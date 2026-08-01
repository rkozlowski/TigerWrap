using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Rendering;
using ItTiger.TigerCli.Terminal;
using ItTiger.TigerCli.Tui;
using ItTiger.TigerCli.Tui.Activity;
using ItTiger.TigerQuery.Engine;
using ItTiger.TigerQuery.Core;
using ItTiger.TigerWrap.Core;
using Microsoft.Data.SqlClient;
using ToolkitResponseCode = ItTiger.TigerWrap.Core.ToolkitDbHelper.ToolkitResponseCode;

namespace ItTiger.TigerWrap.Cli.Commands.Db;

/// <summary>
/// Installs TigerWrapDb into an existing, empty database by executing the packaged
/// full-install artifact through TigerQuery in prepared mode.
/// <para>
/// The command never creates a database: the target must already exist and must be reachable
/// through a saved connection. Emptiness is checked twice - here, for early and readable
/// feedback, and again inside the install script itself, which is the authoritative guard.
/// </para>
/// </summary>
public sealed class DbInstallCommand(SqlServerConnectionStore connectionStore)
    : TigerCliAsyncCommandHandler<DbInstallCommand.Settings>
{
    private const string InitialStatus = "Starting installation...";

    public sealed class Settings : TigerCliSettings
    {
        [TigerCliArgument(0,
            Name = "connection",
            Description = "Saved connection targeting the empty database that will receive TigerWrapDb.",
            Provider = "connections",
            Promptable = TigerCliPromptable.Normal,
            AutoSelectSingleChoice = true)]
        public string ConnectionName { get; set; } = string.Empty;

        [TigerCliOption("--confirm",
            Promptable = TigerCliPromptable.No,
            Description = "Confirm the installation without prompting (required in non-interactive mode).")]
        public bool Confirmed { get; set; }

        [TigerCliOption("--sql-folder",
            Promptable = TigerCliPromptable.No,
            Description = "Override the folder containing the TigerWrapDb deployment scripts "
                + "(default: the 'sql' folder of the TigerWrap installation).")]
        public string? SqlFolder { get; set; }
    }

    public override async Task<int> ExecuteAsync(Settings s)
    {
        try
        {
            // 1. Resolve the connection. No API-level validation: the target has no TigerWrap objects yet.
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
                    $"Connection '{s.ConnectionName}' does not specify a database. "
                        + "TigerWrap installs into an existing database and never creates one; "
                        + "create the database first and point the connection at it.",
                    s);
            }

            // 2. Locate the packaged full-install artifact before touching the database.
            var sqlFolder = string.IsNullOrWhiteSpace(s.SqlFolder)
                ? DbCommandSupport.GetDefaultSqlFolder()
                : Path.GetFullPath(s.SqlFolder);
            var scriptPath = Path.Combine(sqlFolder, DbCommandSupport.FullDeployScriptFileName);
            if (!File.Exists(scriptPath))
            {
                return Fail(
                    ToolkitResponseCode.TigerCliGenericFail,
                    $"Install script not found: {scriptPath}. "
                        + "Reinstall TigerWrap or point --sql-folder at the folder containing the deployment scripts.",
                    s);
            }

            // 3. Preflight: the database must exist, be empty and be capable.
            var preflightResult = await TigerTui.RunActivityAsync(
                "Database install",
                "Inspecting the target database...",
                (_, ct) => DatabaseEmptinessCheck.InspectAsync(connectionString, ct));

            if (!preflightResult.IsCompleted)
            {
                return Fail(
                    preflightResult.Outcome == ActivityOutcome.Failed
                        ? ToolkitResponseCode.DbError
                        : ToolkitResponseCode.TigerCliCancelled,
                    preflightResult.Exception?.Message
                        ?? $"Inspecting the target database did not complete: {preflightResult.Outcome}.",
                    s);
            }

            var preflight = preflightResult.Value!;

            RenderPlan(s, builder, databaseName, scriptPath, preflight);

            if (!preflight.CanInstall)
            {
                return RefuseInstall(s, databaseName, preflight);
            }

            // 4. Confirm.
            var confirmation = await ConfirmInstallAsync(s, builder.DataSource, databaseName);
            if (confirmation != null)
            {
                return (int)confirmation.Value;
            }

            // 5. Execute the packaged script in prepared mode with batch-level progress.
            var runner = new ScriptRunner(s, InitialStatus);
            var (execution, exitCode) = await ExecuteInstallAsync(s, connectionString, databaseName, scriptPath, runner);
            runner.RenderIssues();

            if (exitCode != null)
            {
                return (int)exitCode.Value;
            }

            // The script's own guard stops execution with SET NOEXEC ON rather than by failing a
            // batch, so reported errors - not only failed batches - have to count as a failure.
            if (execution!.ResultCode != ExecutionResultCode.Success
                || execution.FailedBatches > 0
                || runner.Errors > 0)
            {
                return Fail(
                    ToolkitResponseCode.DbError,
                    $"Install script failed ({execution.ResultCode}; {execution.FailedBatches} failed batch(es), "
                        + $"{runner.Errors} error(s))."
                        + (execution.Exception is null ? "" : $" {execution.Exception.Message}")
                        + " The database may be partially populated; drop and recreate it before retrying.",
                    s);
            }

            // 6. Verify the installed version and API level.
            return await VerifyInstallAsync(s, connectionString, databaseName, execution, runner);
        }
        catch (Exception ex)
        {
            return Fail(ToolkitResponseCode.CliUnhandledException, $"DbInstallCommand failed: {ex.Message}", s);
        }
    }

    private void RenderPlan(
        Settings s,
        SqlConnectionStringBuilder builder,
        string databaseName,
        string scriptPath,
        DatabaseEmptinessResult preflight)
    {
        TigerConsole.Render(new CliDetails()
            .ApplyPreset(CliTableStylePreset.Lucca)
            .AddTitle(s.E("TigerWrapDb installation"))
            .AddKey(s.T("Connection:"), s.ConnectionName)
            .Add(s.T("Server:"), builder.DataSource)
            .Add(s.T("Database:"), databaseName)
            .Add(s.T("Collation:"), preflight.Collation)
            .Add(s.T("Compatibility level:"), preflight.CompatibilityLevel)
            .Add(s.T("Database contents:"), preflight.IsEmpty
                ? s.T("empty")
                : s.E("{0} user object(s)", preflight.ConflictCount))
            .Add(s.T("Target version:"), ExpectedDbInfo.CurrentSchemaVersion)
            .Add(s.T("Target API level:"), ExpectedDbInfo.MaxApiLevel)
            .Add(s.T("Install script:"), scriptPath));
    }

    /// <summary>
    /// Reports why installation cannot proceed. Uses <see cref="ToolkitResponseCode.InvalidDatabase"/>
    /// because a dedicated <c>DatabaseNotEmpty</c> code is an <c>[Enum].[ToolkitResponseCode]</c> row
    /// and therefore lands with the batched response-code change, not here.
    /// </summary>
    private static int RefuseInstall(Settings s, string databaseName, DatabaseEmptinessResult preflight)
    {
        TigerConsole.MarkupLine();

        if (!preflight.IsEmpty)
        {
            TigerConsole.MarkupErrorLine(s.E(
                "Database [Key]{0}[/] is not empty and cannot receive a TigerWrapDb installation.",
                databaseName));
            TigerConsole.MarkupLine(s.E(
                "[Muted]Users, roles and permissions do not count as content; only user-defined "
                    + "objects and TigerWrap schemas do.[/]"));
            TigerConsole.MarkupLine();

            var byKind = new CliTable()
                .ApplyPreset(CliTableStylePreset.Milano)
                .AddTitle(s.E("Conflicting objects ({0} total)", preflight.ConflictCount))
                .AddHeader(s.T("Type"), s.T("Count"));
            foreach (var (kind, count) in preflight.ConflictsByKind)
            {
                byKind.AddRecord(kind, count);
            }

            TigerConsole.Render(byKind);

            if (preflight.SampleConflicts.Count > 0)
            {
                var sample = new CliTable()
                    .ApplyPreset(CliTableStylePreset.Milano)
                    .AddTitle(s.E(
                        "Sample ({0} of {1})",
                        preflight.SampleConflicts.Count,
                        preflight.ConflictCount))
                    .AddHeader(s.T("Type"), s.T("Object"));
                foreach (var conflict in preflight.SampleConflicts)
                {
                    sample.AddRecord(conflict.Kind, conflict.Name);
                }

                TigerConsole.Render(sample);
            }

            if (preflight.ConflictsByKind.Any(kind =>
                    string.Equals(kind.Kind, "TigerWrap schema", StringComparison.Ordinal)))
            {
                TigerConsole.MarkupLine();
                TigerConsole.MarkupLine(s.E(
                    "This database already contains TigerWrap objects. Run [Key]tiger-wrap db info[/] "
                        + "to inspect it, or [Key]tiger-wrap db upgrade[/] to bring it up to date."));
            }
        }

        if (!preflight.IsCapable)
        {
            TigerConsole.MarkupLine();
            TigerConsole.MarkupErrorLine(s.E(
                "Database [Key]{0}[/] has compatibility level {1}; TigerWrapDb requires {2} or higher.",
                databaseName,
                preflight.CompatibilityLevel,
                DatabaseEmptinessCheck.MinCompatibilityLevel));
            // The database name is not wrapped in square brackets here: it would be parsed as a
            // console style expression. Users can quote the identifier themselves.
            TigerConsole.MarkupLine(s.E(
                "Fix it with: [Key]ALTER DATABASE {0} SET COMPATIBILITY_LEVEL = {1};[/]",
                databaseName,
                DatabaseEmptinessCheck.MinCompatibilityLevel));
        }

        TigerConsole.MarkupLine();
        TigerConsole.MarkupLine(s.E("[Muted]No changes were made to the database.[/]"));
        return (int)ToolkitResponseCode.InvalidDatabase;
    }

    /// <summary>Returns null to proceed, or the exit code to stop with.</summary>
    private static async Task<ToolkitResponseCode?> ConfirmInstallAsync(Settings s, string server, string databaseName)
    {
        TigerConsole.MarkupLine();
        TigerConsole.MarkupLine(s.E(
            "TigerWrapDb {0} will be installed into database [Key]{1}[/] on server [Key]{2}[/].",
            ExpectedDbInfo.CurrentSchemaVersion,
            databaseName,
            server));

        if (s.Confirmed)
        {
            TigerConsole.MarkupLine(s.E("[Muted]Installation confirmed via --confirm.[/]"));
            return null;
        }

        if (s.InteractionMode == TigerCliInteractionMode.NonInteractive)
        {
            TigerConsole.MarkupErrorLine(s.E(
                "A confirmation is required. Pass --confirm to install into '{0}' on '{1}'.",
                databaseName,
                server));
            return ToolkitResponseCode.CliInteractiveNotAllowed;
        }

        var confirmed = await TigerTui.ConfirmAsync(
            $"Install TigerWrapDb into database '{databaseName}' on server '{server}'?",
            preselect: false);
        if (confirmed != true)
        {
            TigerConsole.MarkupLine(s.E("[Warning]Installation cancelled. No changes were made.[/]"));
            return ToolkitResponseCode.TigerCliCancelled;
        }

        return null;
    }

    private static async Task<(ExecutionResult? execution, ToolkitResponseCode? exitCode)> ExecuteInstallAsync(
        Settings s,
        string connectionString,
        string databaseName,
        string scriptPath,
        ScriptRunner runner)
    {
        if (s.InteractionMode == TigerCliInteractionMode.NonInteractive)
        {
            TigerConsole.MarkupLine(s.E(
                "Installing TigerWrapDb {0} into [Key]{1}[/]...",
                ExpectedDbInfo.CurrentSchemaVersion,
                databaseName));
            var execution = await runner.RunAsync(connectionString, databaseName, scriptPath, context: null, CancellationToken.None);
            return (execution, null);
        }

        var activityResult = await TigerTui.RunActivityAsync(
            "Installing TigerWrapDb",
            CreateActivitySpec(s, databaseName),
            (ctx, ct) => runner.RunAsync(connectionString, databaseName, scriptPath, ctx, ct),
            ActivityStopMode.Cancel);

        if (activityResult.Outcome == ActivityOutcome.Failed && activityResult.Exception is not null)
        {
            Fail(
                ToolkitResponseCode.DbError,
                $"Installation failed: {activityResult.Exception.Message}. "
                    + "Drop and recreate the database before retrying.",
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
                $"Installation did not complete: {activityResult.Outcome}. "
                    + "The database may be partially populated; verify it with 'tiger-wrap db info' "
                    + "and drop and recreate it if needed.",
                s);
            return (null, code);
        }

        return (activityResult.Value, null);
    }

    internal static ActivityDialogSpec CreateActivitySpec(Settings s, string databaseName)
    {
        return ScriptRunner.CreateActivitySpec(
            s,
            s.T("Batches:"),
            s.E(
                "Installing TigerWrapDb {0} into {1}...",
                ExpectedDbInfo.CurrentSchemaVersion,
                databaseName),
            InitialStatus);
    }

    private async Task<int> VerifyInstallAsync(
        Settings s,
        string connectionString,
        string databaseName,
        ExecutionResult execution,
        ScriptRunner runner)
    {
        var verify = await DbCommandSupport.ProbeAsync(connectionString);
        if (verify.Error is not null)
        {
            return Fail(
                ToolkitResponseCode.DbError,
                $"The install script finished, but the database could not be verified: {verify.Error}",
                s);
        }

        var info = verify.Info!;
        var installed =
            string.Equals(info.Version, ExpectedDbInfo.CurrentSchemaVersion, StringComparison.OrdinalIgnoreCase)
            && info.ApiLevel == ExpectedDbInfo.MaxApiLevel
            && info.MinApiLevel == ExpectedDbInfo.MinApiLevel;

        if (!installed)
        {
            return Fail(
                ToolkitResponseCode.DbError,
                $"The install script finished, but the database reports version {info.Version ?? "<unknown>"} "
                    + $"(API level {info.ApiLevel?.ToString() ?? "?"}, minimum {info.MinApiLevel?.ToString() ?? "?"}) "
                    + $"instead of {ExpectedDbInfo.CurrentSchemaVersion} (API level {ExpectedDbInfo.MaxApiLevel}). "
                    + "The script's own guards may have stopped the installation. "
                    + "Review the messages above and verify the database before using it.",
                s);
        }

        TigerConsole.MarkupLine();
        TigerConsole.Render(new CliDetails()
            .ApplyPreset(CliTableStylePreset.Lucca)
            .AddTitle(s.E("[Success]Installation completed successfully[/]"))
            .AddKey(s.T("Database:"), databaseName)
            .Add(s.T("Database type:"), info.DbName)
            .Add(s.T("Version:"), info.Version)
            .Add(s.T("API level:"), info.ApiLevel)
            .Add(s.T("Minimum API level:"), info.MinApiLevel)
            .Add(s.T("Batches executed:"), $"{execution.ExecutedBatches} of {runner.TotalBatches?.ToString() ?? "?"}")
            .Add(s.T("Warnings:"), runner.Warnings)
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
