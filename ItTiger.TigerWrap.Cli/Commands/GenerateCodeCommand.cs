using Spectre.Console;
using Spectre.Console.Cli;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerWrap.Core.Services;
using Microsoft.Extensions.Logging;
using System.ComponentModel;
using static ItTiger.TigerWrap.Core.ToolkitDbHelper;
using ItTiger.TigerWrap.Cli.Helpers;
using System.Diagnostics;

namespace ItTiger.TigerWrap.Cli.Commands;

public sealed class GenerateCodeCommand(ConnectionService _connectionService, ILogger<GenerateCodeCommand> _logger)
    : AsyncCommand<GenerateCodeCommand.Settings>
{
    public sealed class Settings : GlobalSettings
    {
        [CommandArgument(0, "<CONNECTION_NAME>")]
        public string ConnectionName { get; set; } = string.Empty;

        [CommandArgument(1, "<PROJECT_NAME>")]
        public string ProjectName { get; set; } = string.Empty;

        [CommandOption("--database-name")]
        [Description("Optional: override the project's default database.")]
        public string? DatabaseName { get; set; }

        [CommandOption("--output-file")]
        [Description("Path to the single output file (only valid with output-type 'Single')")]
        public string? OutputFile { get; set; }

        [CommandOption("--output-type")]
        [Description("Output type: SingleFile | SplitPerType | SplitPerSchema | SplitPerSchemaAndType")]
        public OutputType OutputType { get; set; } = OutputType.SingleFile;

        [CommandOption("--output-file-prefix")]
        [Description("Prefix for split file output (replaces <ClassName> in filenames)")]
        public string? OutputFilePrefix { get; set; }

        [CommandOption("--output-folder")]
        [Description("Directory to write output files (default: current folder)")]
        public string? OutputFolder { get; set; }

        [CommandOption("--overwrite")]
        [Description("File overwrite mode: Yes | No | Ask (default: Yes)")]
        public OverwriteMode Overwrite { get; set; } = OverwriteMode.Yes;

        [CommandOption("--logging-level")]
        [Description("Logging level (Error, Warning, Info, Debug, Trace). Default: Warning.")]
        public LoggingLevel LoggingLevel { get; set; } = LoggingLevel.Warning;

        public override ValidationResult Validate()
        {
            if (OutputType != OutputType.SingleFile && !string.IsNullOrWhiteSpace(OutputFile))
            {
                return ValidationResult.Error("--output-file can only be used with --output-type=Single.");
            }

            return ValidationResult.Success();
        }
    }

    public override async Task<int> ExecuteAsync(CommandContext context, Settings s)
    {
        try
        {
            var stopwatch = Stopwatch.StartNew();

            var (db, error) = await ToolkitHelper.TryResolveDbHelperAsync(_connectionService, s.ConnectionName);
            if (db == null)
            {
                return CliHelper.Fail(ToolkitResponseCode.CliMissingConnection, error, _logger);
            }

            _logger.LogInformation("Fetching project info...");
            var (rc, projectId, languageId, defaultDb, className, err) = await db.GetProjectInfoAsync(s.ProjectName);
            if (rc != 0 || !projectId.HasValue)
            {
                return CliHelper.Fail(rc == 0 ? ToolkitResponseCode.CliMissingProject : (ToolkitResponseCode)rc, err, _logger);
            }

            var dbName = string.IsNullOrWhiteSpace(s.DatabaseName) ? defaultDb : s.DatabaseName;
            var outputDir = string.IsNullOrWhiteSpace(s.OutputFolder) ? Environment.CurrentDirectory : Path.GetFullPath(s.OutputFolder);
            var prefix = s.OutputFilePrefix ?? className;

            AnsiConsole.MarkupLine($"[green]Generating code for project:[/] [bold]{s.ProjectName}[/]");
            AnsiConsole.MarkupLine($"Class: [yellow]{className}[/], Language: [yellow]{languageId}[/], Database: [yellow]{dbName}[/]");

            var genStopwatch = Stopwatch.StartNew();
            var (results, genRc, genErr) = await db.GenerateCodeAsync(projectId.Value, dbName, s.LoggingLevel);
            genStopwatch.Stop();

            if (genRc != 0 || !string.IsNullOrWhiteSpace(genErr))
            {
                return CliHelper.Fail(genRc == 0 ? ToolkitResponseCode.CliCodeGenerationFailed : (ToolkitResponseCode)genRc,
                    $"Generation failed: {genErr}", _logger);
            }

            if (s.OutputType == OutputType.SingleFile)
            {
                var file = s.OutputFile ?? Path.Combine(outputDir, $"{className}.cs");
                var overwriteError = await ConfirmOverwriteAsync(file, s);
                if (overwriteError != null)
                {
                    return CliHelper.Fail(overwriteError.Value, $"Cannot overwrite existing file: {file}", _logger);
                }
                var text = string.Join(Environment.NewLine, results.OrderBy(r => r.Id).Select(r => r.Text));
                await File.WriteAllTextAsync(file, text);
                _logger.LogInformation("Written to: {File}", file);
                AnsiConsole.MarkupLine($"[green]Written: [italic]{file}[/][/]");
                AnsiConsole.MarkupLine($"[blue]Code generation time: {genStopwatch.Elapsed.TotalSeconds:F3}s, total: {stopwatch.Elapsed.TotalSeconds:F3}s[/]");
                return 0;
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

            foreach (var group in grouped)
            {
                var file = Path.Combine(outputDir, group.Key);
                var overwriteError = await ConfirmOverwriteAsync(file, s);
                if (overwriteError != null)
                {
                    return CliHelper.Fail(overwriteError.Value, $"Cannot overwrite existing file: {file}", _logger);
                }

                var lines = new List<string>();
                lines.AddRange(headers);
                lines.AddRange(group.Select(g => g.Text));
                lines.AddRange(footers);

                await File.WriteAllTextAsync(file, string.Join(Environment.NewLine, lines));
                AnsiConsole.MarkupLine($"[green]Written: [italic]{file}[/][/]");
            }

            if (bootstrap.Count > 0)
            {
                var bootstrapFile = Path.Combine(outputDir, $"{prefix}.Bootstrap.cs");
                var overwriteError = await ConfirmOverwriteAsync(bootstrapFile, s);
                if (overwriteError != null)
                {
                    return CliHelper.Fail(overwriteError.Value, $"Cannot overwrite existing file: {bootstrapFile}", _logger);
                }
                var lines = new List<string>();
                lines.AddRange(headers);
                lines.AddRange(bootstrap.Select(b => b.Text));
                lines.AddRange(footers);
                await File.WriteAllTextAsync(bootstrapFile, string.Join(Environment.NewLine, lines));
                AnsiConsole.MarkupLine($"[green]Written: [italic]{bootstrapFile}[/][/]");
            }

            stopwatch.Stop();
            AnsiConsole.MarkupLine($"[blue]Code generation time: {genStopwatch.Elapsed.TotalSeconds:F3}s, total: {stopwatch.Elapsed.TotalSeconds:F3}s[/]");
            return 0;
        }
        catch (Exception ex)
        {
            return CliHelper.Fail(ToolkitResponseCode.CliUnhandledException, $"GenerateCodeCommand failed: {ex.Message}", ex, _logger);
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

    private static async Task<ToolkitResponseCode?> ConfirmOverwriteAsync(string filePath, Settings s)
    {
        if (!File.Exists(filePath)) return null;

        return s.Overwrite switch
        {
            OverwriteMode.Yes => null,
            OverwriteMode.No => ToolkitResponseCode.CliFileWriteError,
            OverwriteMode.Ask => await AskUser(filePath, s),
            _ => ToolkitResponseCode.CliInvalidArguments
        };
    }

    private static Task<ToolkitResponseCode?> AskUser(string filePath, Settings s)
    {
        if (s.NonInteractive)
        {
            return Task.FromResult<ToolkitResponseCode?>(ToolkitResponseCode.CliInteractiveNotAllowed);
        }

        var overwrite = AnsiConsole.Confirm($"File [italic]{filePath}[/] exists. Overwrite?");
        return Task.FromResult<ToolkitResponseCode?>(overwrite ? null : ToolkitResponseCode.CliFileWriteError);
    }
}

