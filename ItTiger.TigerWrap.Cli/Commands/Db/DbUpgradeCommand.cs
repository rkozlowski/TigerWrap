using System.Diagnostics;
using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Rendering;
using ItTiger.TigerCli.Terminal;
using ItTiger.TigerCli.Tui;
using ItTiger.TigerCli.Tui.Activity;
using ItTiger.TigerQuery;
using ItTiger.TigerQuery.Engine;
using ItTiger.TigerQuery.Events;
using ItTiger.TigerQuery.Core;
using ItTiger.TigerWrap.Core;
using Microsoft.Data.SqlClient;
using ActivityContext = ItTiger.TigerCli.Tui.Activity.ActivityContext;
using ToolkitResponseCode = ItTiger.TigerWrap.Core.ToolkitDbHelper.ToolkitResponseCode;

namespace ItTiger.TigerWrap.Cli.Commands.Db;

public sealed class DbUpgradeCommand(SqlServerConnectionStore connectionStore)
    : TigerCliAsyncCommandHandler<DbUpgradeCommand.Settings>
{
    private const int MaxIssuesShown = 10;

    public sealed class Settings : TigerCliSettings
    {
        [TigerCliArgument(0,
            Name = "connection",
            Description = "Saved TigerWrap database connection.",
            Provider = "connections",
            Promptable = TigerCliPromptable.Normal,
            AutoSelectSingleChoice = true)]
        public string ConnectionName { get; set; } = string.Empty;

        [TigerCliOption("--backup-confirmed",
            Promptable = TigerCliPromptable.No,
            Description = "Confirm that a valid backup of the database exists (required in non-interactive mode).")]
        public bool BackupConfirmed { get; set; }

        [TigerCliOption("--sql-folder",
            Promptable = TigerCliPromptable.No,
            Description = "Override the folder containing the TigerWrapDb deployment scripts "
                + "(default: the 'sql' folder of the TigerWrap installation).")]
        public string? SqlFolder { get; set; }
    }

    private sealed class UpgradeProgress
    {
        private readonly object _lock = new();

        public int CompletedBatches;
        public int Warnings;
        public int Errors;
        public string LastStatus = "Starting upgrade...";
        public readonly List<SqlCmdMessage> Issues = [];
        public readonly Stopwatch Elapsed = Stopwatch.StartNew();

        public void Record(Action action)
        {
            lock (_lock)
            {
                action();
            }
        }
    }

    public override async Task<int> ExecuteAsync(Settings s)
    {
        try
        {
            // 1. Resolve the connection (no API-level validation; the target is 0.9.0).
            var (connectionString, error) = DbCommandSupport.ResolveConnectionString(connectionStore, s.ConnectionName);
            if (connectionString is null)
            {
                return Fail(ToolkitResponseCode.CliMissingConnection, error, s);
            }

            var builder = new SqlConnectionStringBuilder(connectionString);
            var databaseName = builder.InitialCatalog;
            if (string.IsNullOrWhiteSpace(databaseName))
            {
                return Fail(
                    ToolkitResponseCode.CliMissingConnection,
                    $"Connection '{s.ConnectionName}' does not specify a database.",
                    s);
            }

            // 2./3. Probe the database and verify identity and exact source version.
            var probeResult = await TigerTui.RunActivityAsync(
                "Database upgrade",
                "Checking the current database version...",
                (_, ct) => DbCommandSupport.ProbeAsync(connectionString, ct));

            if (!probeResult.IsCompleted)
            {
                return Fail(
                    probeResult.Outcome == ActivityOutcome.Failed
                        ? ToolkitResponseCode.CliUnhandledException
                        : ToolkitResponseCode.TigerCliCancelled,
                    probeResult.Exception?.Message ?? $"Version check did not complete: {probeResult.Outcome}.",
                    s);
            }

            var probe = probeResult.Value!;
            if (probe.Error is not null)
            {
                return Fail(
                    probe.IsNotTigerWrapDb ? ToolkitResponseCode.InvalidDatabase : ToolkitResponseCode.DbError,
                    probe.Error,
                    s);
            }

            var info = probe.Info!;
            switch (DbCommandSupport.Classify(info))
            {
                case TigerWrapDbStatus.UpgradeAvailable:
                    break;

                case TigerWrapDbStatus.Current:
                    TigerConsole.MarkupLine(s.E(
                        "[Success]Database [Key]{0}[/] is already at version {1}. Nothing to upgrade.[/]",
                        databaseName,
                        ExpectedDbInfo.CurrentSchemaVersion));
                    return (int)ToolkitResponseCode.Ok;

                case TigerWrapDbStatus.NewerThanTool:
                    return Fail(
                        ToolkitResponseCode.InvalidDatabase,
                        $"Database version {info.Version} is newer than this tool supports ({ExpectedDbInfo.CurrentSchemaVersion}). "
                            + "Update TigerWrap instead.",
                        s);

                default:
                    return Fail(
                        ToolkitResponseCode.InvalidDatabase,
                        $"Database version {info.Version ?? "<unknown>"} cannot be upgraded by this tool. "
                            + $"Only {DbCommandSupport.UpgradeSourceVersion} -> {ExpectedDbInfo.CurrentSchemaVersion} is supported; "
                            + "older versions must be upgraded manually first (see docs/INSTALL.md).",
                        s);
            }

            // Resolve the upgrade script.
            var sqlFolder = string.IsNullOrWhiteSpace(s.SqlFolder)
                ? DbCommandSupport.GetDefaultSqlFolder()
                : Path.GetFullPath(s.SqlFolder);
            var scriptPath = Path.Combine(sqlFolder, DbCommandSupport.UpgradeScriptFileName);
            if (!File.Exists(scriptPath))
            {
                return Fail(
                    ToolkitResponseCode.TigerCliGenericFail,
                    $"Upgrade script not found: {scriptPath}. "
                        + "Reinstall TigerWrap or point --sql-folder at the folder containing the deployment scripts.",
                    s);
            }

            // 4. Show the planned upgrade.
            TigerConsole.Render(new CliDetails()
                .ApplyPreset(CliTableStylePreset.Lucca)
                .AddTitle(s.E("TigerWrapDb upgrade"))
                .AddKey(s.T("Connection:"), s.ConnectionName)
                .Add(s.T("Server:"), builder.DataSource)
                .Add(s.T("Database:"), databaseName)
                .Add(s.T("Current version:"), info.Version)
                .Add(s.T("Target version:"), ExpectedDbInfo.CurrentSchemaVersion)
                .Add(s.T("Upgrade script:"), scriptPath));

            // 5./6./7. Backup warning and confirmation.
            var confirmation = await ConfirmBackupAsync(s, databaseName);
            if (confirmation != null)
            {
                return (int)confirmation.Value;
            }

            // 8.-12. Execute the script through TigerQuery in SqlCmdEx mode.
            var progress = new UpgradeProgress();
            var (execution, exitCode) = await ExecuteUpgradeAsync(s, connectionString, databaseName, scriptPath, progress);
            RenderIssues(s, progress);

            if (exitCode != null)
            {
                return (int)exitCode.Value;
            }

            if (execution!.ResultCode != ExecutionResultCode.Success || execution.FailedBatches > 0)
            {
                return Fail(
                    ToolkitResponseCode.DbError,
                    $"Upgrade script failed ({execution.ResultCode}; {execution.FailedBatches} failed batch(es))."
                        + (execution.Exception is null ? "" : $" {execution.Exception.Message}")
                        + " Restore the database from your backup before retrying.",
                    s);
            }

            // 13./14. Re-check the database and require the target version and API levels.
            return await VerifyUpgradeAsync(s, connectionString, databaseName, info.Version, execution, progress);
        }
        catch (Exception ex)
        {
            return Fail(ToolkitResponseCode.CliUnhandledException, $"DbUpgradeCommand failed: {ex.Message}", s);
        }
    }

    /// <summary>Returns null to proceed, or the exit code to stop with.</summary>
    private static async Task<ToolkitResponseCode?> ConfirmBackupAsync(Settings s, string databaseName)
    {
        TigerConsole.MarkupLine();
        TigerConsole.MarkupLine(s.E(
            "[Warning]Warning: TigerWrap does not create a backup and cannot roll back a failed upgrade.[/]"));
        TigerConsole.MarkupLine(s.E(
            "Make sure a current backup of database [Key]{0}[/] exists before continuing.",
            databaseName));
        TigerConsole.MarkupLine();

        if (s.BackupConfirmed)
        {
            TigerConsole.MarkupLine(s.E("[Muted]Backup confirmed via --backup-confirmed.[/]"));
            return null;
        }

        if (s.InteractionMode == TigerCliInteractionMode.NonInteractive)
        {
            TigerConsole.MarkupErrorLine(s.E(
                "A backup confirmation is required. Pass --backup-confirmed to confirm that a valid backup exists."));
            return ToolkitResponseCode.CliInteractiveNotAllowed;
        }

        var confirmed = await TigerTui.ConfirmAsync(
            $"Does a current backup of database '{databaseName}' exist?",
            preselect: false);
        if (confirmed != true)
        {
            TigerConsole.MarkupLine(s.E("[Warning]Upgrade cancelled. No changes were made.[/]"));
            return ToolkitResponseCode.TigerCliCancelled;
        }

        return null;
    }

    private static async Task<(ExecutionResult? execution, ToolkitResponseCode? exitCode)> ExecuteUpgradeAsync(
        Settings s,
        string connectionString,
        string databaseName,
        string scriptPath,
        UpgradeProgress progress)
    {
        if (s.InteractionMode == TigerCliInteractionMode.NonInteractive)
        {
            TigerConsole.MarkupLine(s.E(
                "Upgrading [Key]{0}[/] from {1} to {2}...",
                databaseName,
                DbCommandSupport.UpgradeSourceVersion,
                ExpectedDbInfo.CurrentSchemaVersion));
            var execution = await RunEngineAsync(s, connectionString, databaseName, scriptPath, progress, context: null, CancellationToken.None);
            return (execution, null);
        }

        var spec = CreateActivitySpec(s, databaseName);

        var activityResult = await TigerTui.RunActivityAsync(
            "Upgrading TigerWrapDb",
            spec,
            (ctx, ct) => RunEngineAsync(s, connectionString, databaseName, scriptPath, progress, ctx, ct),
            ActivityStopMode.Cancel);

        if (activityResult.Outcome == ActivityOutcome.Failed && activityResult.Exception is not null)
        {
            Fail(
                ToolkitResponseCode.DbError,
                $"Upgrade failed: {activityResult.Exception.Message}. Restore the database from your backup before retrying.",
                s);
            return (null, ToolkitResponseCode.DbError);
        }

        if (!activityResult.IsCompleted)
        {
            var code = activityResult.Outcome == ActivityOutcome.TimedOut
                ? ToolkitResponseCode.CliUnhandledException
                : ToolkitResponseCode.TigerCliCancelled;
            Fail(
                code,
                $"Upgrade did not complete: {activityResult.Outcome}. "
                    + "The database may have been partially upgraded; verify it with 'tiger-wrap db info' "
                    + "and restore the backup if needed.",
                s);
            return (null, code);
        }

        return (activityResult.Value, null);
    }

    internal static ActivityDialogSpec CreateActivitySpec(Settings s, string databaseName)
    {
        return ActivityDialogSpec.Create()
            .AddColumn(width: 10)
            .AddColumn(sizing: CliColumnSizing.Star)
            .AddRow("status", row => row.Cell(0, 2).Text("{0}").Values("Starting upgrade..."))
            .AddRow("batches", row => row.Cell(0).Text(s.T("Batches:")).Cell(1).Text("{0} completed").Values(0))
            .AddRow("issues", row => row.Cell(0).Text(s.T("Issues:")).Cell(1).Text("{0} warning(s), {1} error(s)").Values(0, 0))
            .AddRow("elapsed", row => row.Cell(0).Text(s.T("Elapsed:")).Cell(1).Text("{0}").Values("00:00"))
            .SetNonInteractiveMessage(s.E(
                "Upgrading {0} from {1} to {2}...",
                databaseName,
                DbCommandSupport.UpgradeSourceVersion,
                ExpectedDbInfo.CurrentSchemaVersion))
            .Build();
    }

    private static async Task<ExecutionResult> RunEngineAsync(
        Settings s,
        string connectionString,
        string databaseName,
        string scriptPath,
        UpgradeProgress progress,
        ActivityContext? context,
        CancellationToken cancellationToken)
    {
        var options = new TigerQueryEngineOptions
        {
            ConnectionString = connectionString,
            Mode = SqlCmdMode.SqlCmdEx,
            ContinueOnError = false,
            // Injected variables take precedence over the script's own :setvar values, so the
            // upgrade targets the connection's actual database even if it is not named TigerWrapDb.
            Variables = new Dictionary<string, string> { ["DatabaseName"] = databaseName },
            OnMessage = (message, _) => HandleMessage(s, message, progress, context),
            OnBatchEnd = end => HandleBatchEnd(end, progress, context)
        };

        var engine = new TigerQueryEngine(options);
        return await engine.RunFromFileAsync(scriptPath, cancellationToken: cancellationToken);
    }

    private static void HandleMessage(Settings s, SqlCmdMessage message, UpgradeProgress progress, ActivityContext? context)
    {
        var text = message.Text?.Trim();

        progress.Record(() =>
        {
            if (message.IsError)
            {
                progress.Errors++;
                progress.Issues.Add(message);
            }
            else if (message.Type == SqlCmdMessageType.Warning)
            {
                progress.Warnings++;
                progress.Issues.Add(message);
            }
            else if (!string.IsNullOrEmpty(text))
            {
                progress.LastStatus = text;
            }
        });

        if (context is not null)
        {
            UpdateActivity(progress, context);
        }
        else if (!string.IsNullOrEmpty(text))
        {
            // Non-interactive: linear per-message diagnostics.
            if (message.IsError)
            {
                TigerConsole.MarkupErrorLine(s.E("{0}", FormatIssue(message)));
            }
            else if (message.Type == SqlCmdMessageType.Warning)
            {
                TigerConsole.MarkupLine(s.E("[Warning]{0}[/]", FormatIssue(message)));
            }
            else
            {
                TigerConsole.MarkupLine(s.E("[Muted]{0}[/]", text));
            }
        }
    }

    private static void HandleBatchEnd(BatchEnd end, UpgradeProgress progress, ActivityContext? context)
    {
        progress.Record(() =>
        {
            if (end.Success)
            {
                progress.CompletedBatches++;
            }
        });

        if (context is not null)
        {
            UpdateActivity(progress, context);
        }
    }

    private static void UpdateActivity(UpgradeProgress progress, ActivityContext context)
    {
        progress.Record(() =>
        {
            context.SetMessage("status", progress.LastStatus);
            context.SetValues("batches", progress.CompletedBatches);
            context.SetValues("issues", progress.Warnings, progress.Errors);
            context.SetMessage("elapsed", progress.Elapsed.Elapsed.ToString(@"mm\:ss"));
        });
    }

    private static void RenderIssues(Settings s, UpgradeProgress progress)
    {
        // Non-interactive mode already printed every issue linearly.
        if (s.InteractionMode == TigerCliInteractionMode.NonInteractive || progress.Issues.Count == 0)
        {
            return;
        }

        foreach (var issue in progress.Issues.Take(MaxIssuesShown))
        {
            if (issue.IsError)
            {
                TigerConsole.MarkupErrorLine(s.E("{0}", FormatIssue(issue)));
            }
            else
            {
                TigerConsole.MarkupLine(s.E("[Warning]{0}[/]", FormatIssue(issue)));
            }
        }

        if (progress.Issues.Count > MaxIssuesShown)
        {
            TigerConsole.MarkupLine(s.E("[Muted]...and {0} more issue(s).[/]", progress.Issues.Count - MaxIssuesShown));
        }
    }

    private static string FormatIssue(SqlCmdMessage message)
    {
        var location = message.LineNumber.HasValue ? $" (line {message.LineNumber})" : "";
        return $"{message.Type}{location}: {message.Text}";
    }

    private async Task<int> VerifyUpgradeAsync(
        Settings s,
        string connectionString,
        string databaseName,
        string? versionBefore,
        ExecutionResult execution,
        UpgradeProgress progress)
    {
        var verify = await DbCommandSupport.ProbeAsync(connectionString);
        if (verify.Error is not null)
        {
            return Fail(
                ToolkitResponseCode.DbError,
                $"The upgrade script finished, but the database could not be verified: {verify.Error}",
                s);
        }

        var info = verify.Info!;
        var upgraded =
            string.Equals(info.Version, ExpectedDbInfo.CurrentSchemaVersion, StringComparison.OrdinalIgnoreCase)
            && info.ApiLevel == ExpectedDbInfo.MaxApiLevel
            && info.MinApiLevel == ExpectedDbInfo.MinApiLevel;

        if (!upgraded)
        {
            return Fail(
                ToolkitResponseCode.DbError,
                $"The upgrade script finished, but the database reports version {info.Version ?? "<unknown>"} "
                    + $"(API level {info.ApiLevel?.ToString() ?? "?"}, minimum {info.MinApiLevel?.ToString() ?? "?"}) "
                    + $"instead of {ExpectedDbInfo.CurrentSchemaVersion} (API level {ExpectedDbInfo.MaxApiLevel}). "
                    + "The script's own database/version guards may have prevented the upgrade. "
                    + "Review the messages above and verify the database before using it.",
                s);
        }

        TigerConsole.MarkupLine();
        TigerConsole.Render(new CliDetails()
            .ApplyPreset(CliTableStylePreset.Lucca)
            .AddTitle(s.E("[Success]Upgrade completed successfully[/]"))
            .AddKey(s.T("Database:"), databaseName)
            .Add(s.T("Version:"), $"{versionBefore} -> {info.Version}")
            .Add(s.T("API level:"), info.ApiLevel)
            .Add(s.T("Minimum API level:"), info.MinApiLevel)
            .Add(s.T("Batches executed:"), execution.ExecutedBatches)
            .Add(s.T("Warnings:"), progress.Warnings)
            .Add(s.T("Duration:"), $"{execution.TotalDuration.TotalSeconds:F1}s"));

        return (int)ToolkitResponseCode.Ok;
    }

    private static int Fail(ToolkitResponseCode code, string? message, Settings settings)
    {
        if (!string.IsNullOrWhiteSpace(message))
        {
            TigerConsole.MarkupErrorLine(settings.E("{0}", message));
        }

        return (int)code;
    }
}
