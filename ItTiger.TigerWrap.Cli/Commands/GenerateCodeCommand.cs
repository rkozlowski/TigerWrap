using System.Diagnostics;
using System.Globalization;
using System.Runtime.ExceptionServices;
using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Primitives;
using ItTiger.TigerCli.Rendering;
using ItTiger.TigerCli.Terminal;
using ItTiger.TigerCli.Tui;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerQuery.Core;
using static ItTiger.TigerWrap.Core.ToolkitDbHelper;

namespace ItTiger.TigerWrap.Cli.Commands;

public sealed class GenerateCodeCommand(SqlServerConnectionStore connectionStore)
    : TigerCliAsyncCommandHandler<GenerateCodeCommand.Settings>
{
    public sealed class Settings : TigerCliSettings
    {
        [TigerCliArgument(0,
            Name = "connection",
            Description = "Saved TigerWrap database connection.",
            Provider = "connections",
            Promptable = TigerCliPromptable.No,
            MinLength = 1)]
        public string ConnectionName { get; set; } = string.Empty;

        [TigerCliArgument(1,
            Name = "project",
            Description = "Project name.",
            Promptable = TigerCliPromptable.No,
            MinLength = 1)]
        public string ProjectName { get; set; } = string.Empty;

        [TigerCliOption("--database-name", Description = "Optional: override the project's default database.")]
        public string? DatabaseName { get; set; }

        [TigerCliOption("--output-file", Description = "Path to the single output file (only valid with output-type 'Single')")]
        public string? OutputFile { get; set; }

        [TigerCliOption("--output-type", Description = "Output type: SingleFile | SplitPerType | SplitPerSchema | SplitPerSchemaAndType")]
        public OutputType OutputType { get; set; } = OutputType.SingleFile;

        [TigerCliOption("--output-file-prefix", Description = "Prefix for split file output (replaces <ClassName> in filenames)")]
        public string? OutputFilePrefix { get; set; }

        [TigerCliOption("--output-folder", Description = "Directory to write output files (default: current folder)")]
        public string? OutputFolder { get; set; }

        [TigerCliOption("--overwrite", Description = "File overwrite mode: Yes | No | Ask (default: Yes)")]
        public OverwriteMode Overwrite { get; set; } = OverwriteMode.Yes;

        [TigerCliOption("--logging-level", Description = "Logging level (Error, Warning, Info, Debug, Trace). Default: Warning.")]
        public LoggingLevel LoggingLevel { get; set; } = LoggingLevel.Warning;

        public override TigerCliValidationResult Validate()
        {
            if (OutputType != OutputType.SingleFile && !string.IsNullOrWhiteSpace(OutputFile))
            {
                return TigerCliValidationResult.Error("--output-file can only be used with --output-type=Single.");
            }

            return TigerCliValidationResult.Success();
        }
    }

    public override async Task<int> ExecuteAsync(Settings s)
    {
        try
        {
            var stopwatch = Stopwatch.StartNew();

            var (db, error) = await ToolkitHelper.TryResolveDbHelperAsync(connectionStore, s.ConnectionName);
            if (db == null)
            {
                return Fail(ToolkitResponseCode.CliMissingConnection, error, s);
            }

            var (rc, projectId, languageId, defaultDb, className, err) = await db.GetProjectInfoAsync(s.ProjectName);
            if (rc != 0 || !projectId.HasValue)
            {
                return Fail(rc == 0 ? ToolkitResponseCode.CliMissingProject : (ToolkitResponseCode)rc, err, s);
            }

            var dbName = string.IsNullOrWhiteSpace(s.DatabaseName) ? defaultDb : s.DatabaseName;
            var outputDir = string.IsNullOrWhiteSpace(s.OutputFolder) ? Environment.CurrentDirectory : Path.GetFullPath(s.OutputFolder);
            var prefix = s.OutputFilePrefix ?? className;
            var effectiveOutputFolder = GetEffectiveOutputFolder(s, outputDir);

            TigerConsole.MarkupLine(s.E("[Success]Generating code for project:[/] [Key]{0}[/]", s.ProjectName));
            TigerConsole.MarkupLine(s.E(
                "Class: [Warning]{0}[/], Language: [Warning]{1}[/], Database: [Warning]{2}[/]",
                className,
                languageId,
                dbName));
            TigerConsole.MarkupLine(s.E("Output folder: [Path]{0}[/]", FormatOutputFolder(effectiveOutputFolder)));
            TigerConsole.MarkupLine();

            var genStopwatch = Stopwatch.StartNew();
            var activityResult = await TigerTui.RunActivityAsync(
                "Generating code",
                "Running database code generation...",
                (_, ct) => db.GenerateCodeAsync(projectId.Value, dbName, s.LoggingLevel, ct));
            genStopwatch.Stop();

            if (activityResult.Outcome == ActivityOutcome.Failed && activityResult.Exception is not null)
            {
                ExceptionDispatchInfo.Capture(activityResult.Exception).Throw();
            }

            if (!activityResult.IsCompleted)
            {
                return Fail(
                    activityResult.Outcome == ActivityOutcome.TimedOut
                        ? ToolkitResponseCode.CliUnhandledException
                        : ToolkitResponseCode.TigerCliCancelled,
                    $"Generation did not complete: {activityResult.Outcome}.",
                    s);
            }

            var (results, genRc, genErr) = activityResult.Value;

            if (genRc != 0 || !string.IsNullOrWhiteSpace(genErr))
            {
                return Fail(
                    genRc == 0 ? ToolkitResponseCode.CliCodeGenerationFailed : (ToolkitResponseCode)genRc,
                    $"Generation failed: {genErr}",
                    s);
            }

            if (s.OutputType == OutputType.SingleFile)
            {
                var file = Path.GetFullPath(s.OutputFile ?? Path.Combine(outputDir, $"{className}.cs"));
                var overwriteError = await ConfirmOverwriteAsync(file, s);
                if (overwriteError != null)
                {
                    return Fail(overwriteError.Value, $"Cannot overwrite existing file: {file}", s);
                }
                var text = string.Join(Environment.NewLine, results.OrderBy(r => r.Id).Select(r => r.Text));
                var singleWrittenFiles = new List<GeneratedFileSummary> { await WriteGeneratedFileAsync(file, text) };
                RenderWrittenFilesSummary(singleWrittenFiles, s);
                stopwatch.Stop();
                TigerConsole.MarkupLine(s.E(
                    "[Muted]Code generation time: {0}s, total: {1}s[/]",
                    FormatSeconds(genStopwatch),
                    FormatSeconds(stopwatch)));
                return (int)ToolkitResponseCode.Ok;
            }

            var headers = results.Where(r => r.CodePartId == CodePart.CodeHeader).Select(r => r.Text);
            var footers = results.Where(r => r.CodePartId == CodePart.CodeEnd).Select(r => r.Text);
            var bootstrap = results.Where(r => r.CodePartId == CodePart.CodeBootstrap).ToList();
            var grouped = results
                .Where(r => r.CodePartId is CodePart.Enums or CodePart.ResultTypes or CodePart.TvpTypes or CodePart.SpWrappers)
                .GroupBy(r => s.OutputType switch
                {
                    OutputType.SplitPerType => $"{prefix}.{GetFileNameSuffix(r.CodePartId)}.cs",
                    OutputType.SplitPerSchema => $"{prefix}.{r.Schema}.cs",
                    OutputType.SplitPerSchemaAndType => $"{prefix}.{r.Schema}.{GetFileNameSuffix(r.CodePartId)}.cs",
                    _ => throw new NotImplementedException()
                });
            var writtenFiles = new List<GeneratedFileSummary>();

            foreach (var group in grouped)
            {
                var file = Path.Combine(outputDir, group.Key);
                var overwriteError = await ConfirmOverwriteAsync(file, s);
                if (overwriteError != null)
                {
                    return Fail(overwriteError.Value, $"Cannot overwrite existing file: {file}", s);
                }

                var lines = new List<string>();
                lines.AddRange(headers);
                lines.AddRange(group.Select(g => g.Text));
                lines.AddRange(footers);

                writtenFiles.Add(await WriteGeneratedFileAsync(file, string.Join(Environment.NewLine, lines)));
            }

            if (bootstrap.Count > 0)
            {
                var bootstrapFile = Path.Combine(outputDir, $"{prefix}.Bootstrap.cs");
                var overwriteError = await ConfirmOverwriteAsync(bootstrapFile, s);
                if (overwriteError != null)
                {
                    return Fail(overwriteError.Value, $"Cannot overwrite existing file: {bootstrapFile}", s);
                }
                var lines = new List<string>();
                lines.AddRange(headers);
                lines.AddRange(bootstrap.Select(b => b.Text));
                lines.AddRange(footers);
                writtenFiles.Add(await WriteGeneratedFileAsync(bootstrapFile, string.Join(Environment.NewLine, lines)));
            }

            stopwatch.Stop();
            RenderWrittenFilesSummary(writtenFiles, s);
            TigerConsole.MarkupLine(s.E(
                "[Muted]Code generation time: {0}s, total: {1}s[/]",
                FormatSeconds(genStopwatch),
                FormatSeconds(stopwatch)));
            return (int)ToolkitResponseCode.Ok;
        }
        catch (Exception ex)
        {
            return Fail(ToolkitResponseCode.CliUnhandledException, $"GenerateCodeCommand failed: {ex.Message}", s);
        }
    }

    private static string GetFileNameSuffix(CodePart part) =>
        part switch
        {
            CodePart.CodeBootstrap => "Bootstrap",
            CodePart.Enums => "Enums",
            CodePart.ResultTypes => "ResultTypes",
            CodePart.TvpTypes => "TvpTypes",
            CodePart.SpWrappers => "StoredProcedures",
            _ => part.ToString()
        };

    internal static string FormatByteSize(long bytes)
    {
        string[] units = ["B", "KiB", "MiB", "GiB", "TiB"];
        if (bytes < 1024)
        {
            return string.Create(CultureInfo.InvariantCulture, $"{bytes} B");
        }

        var value = (double)bytes;
        var unitIndex = 0;
        while (value >= 1024 && unitIndex < units.Length - 1)
        {
            value /= 1024;
            unitIndex++;
        }

        return string.Create(CultureInfo.InvariantCulture, $"{value:F2} {units[unitIndex]}");
    }

    internal static CliTable CreateWrittenFilesList(IEnumerable<GeneratedFileSummary> writtenFiles, Settings settings)
    {
        var list = new CliList<GeneratedFileSummary>()
            .ApplyPreset(CliTableStylePreset.Milano)
            .AddTitle(settings.E("[Success]Files written:[/]"), CliTextAlignment.Left)
            .AddKeyColumn(settings.T("File name"), row => row.FileName)
            .AddColumn(settings.T("Lines"), row => row.Lines, ThemeStyle.Value)
            .AddColumn(settings.T("Size"), row => FormatByteSize(row.Bytes), ThemeStyle.Value);

        var table = list.Render(writtenFiles);
        SetColumnAlignment(table, 1, CliTextAlignment.Right);
        SetColumnAlignment(table, 2, CliTextAlignment.Right);
        return table;
    }

    internal static async Task<GeneratedFileSummary> WriteGeneratedFileAsync(string filePath, string content)
    {
        await File.WriteAllTextAsync(filePath, content);

        var info = new FileInfo(filePath);
        return new GeneratedFileSummary(
            Path.GetFileName(filePath),
            File.ReadLines(filePath).Count(),
            info.Length);
    }

    internal static void RenderWrittenFilesSummary(IReadOnlyCollection<GeneratedFileSummary> writtenFiles, Settings settings)
    {
        if (writtenFiles.Count == 0)
        {
            TigerConsole.MarkupLine(settings.E("[Warning]No files written.[/]"));
            return;
        }

        TigerConsole.Render(CreateWrittenFilesList(writtenFiles, settings));
    }

    private static void SetColumnAlignment(CliTable table, int columnIndex, CliTextAlignment alignment)
    {
        table.Header.Elements[columnIndex].DataStyle ??= new CliCellStyle();
        table.Header.Elements[columnIndex].DataStyle!.HorizontalAlignment = alignment;
    }

    private static string GetEffectiveOutputFolder(Settings settings, string outputDir)
    {
        if (settings.OutputType == OutputType.SingleFile && !string.IsNullOrWhiteSpace(settings.OutputFile))
        {
            var file = Path.GetFullPath(settings.OutputFile);
            return Path.GetDirectoryName(file) ?? outputDir;
        }

        return Path.GetFullPath(outputDir);
    }

    internal static string FormatOutputFolder(string outputFolder)
    {
        var fullPath = Path.GetFullPath(outputFolder);
        return Path.EndsInDirectorySeparator(fullPath)
            ? fullPath
            : fullPath + Path.DirectorySeparatorChar;
    }

    private static async Task<ToolkitResponseCode?> ConfirmOverwriteAsync(string filePath, Settings s)
    {
        if (!File.Exists(filePath)) return null;

        return s.Overwrite switch
        {
            OverwriteMode.Yes => null,
            OverwriteMode.No => ToolkitResponseCode.CliFileWriteError,
            OverwriteMode.Ask => await AskUserAsync(filePath, s),
            _ => ToolkitResponseCode.CliInvalidArguments
        };
    }

    private static async Task<ToolkitResponseCode?> AskUserAsync(string filePath, Settings s)
    {
        if (s.InteractionMode == TigerCliInteractionMode.NonInteractive)
        {
            return ToolkitResponseCode.CliInteractiveNotAllowed;
        }

        var overwrite = await TigerTui.ConfirmAsync($"File {filePath} exists. Overwrite?", preselect: false);
        return overwrite == true ? null : ToolkitResponseCode.CliFileWriteError;
    }

    private static string FormatSeconds(Stopwatch stopwatch) =>
        stopwatch.Elapsed.TotalSeconds.ToString("F3", CultureInfo.InvariantCulture);

    private static int Fail(ToolkitResponseCode code, string? message, Settings settings)
    {
        if (!string.IsNullOrWhiteSpace(message))
        {
            TigerConsole.MarkupErrorLine(settings.E("{0}", message));
        }

        return (int)code;
    }

    internal readonly record struct GeneratedFileSummary(string FileName, int Lines, long Bytes);
}

