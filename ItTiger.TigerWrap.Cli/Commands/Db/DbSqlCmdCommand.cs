using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Rendering;
using ItTiger.TigerCli.Terminal;
using ItTiger.TigerCli.Tui;
using ItTiger.TigerCli.Tui.Activity;
using ItTiger.TigerQuery;
using ItTiger.TigerQuery.Core;
using ItTiger.TigerQuery.Engine;
using Microsoft.Data.SqlClient;
using ToolkitResponseCode = ItTiger.TigerWrap.Core.ToolkitDbHelper.ToolkitResponseCode;

namespace ItTiger.TigerWrap.Cli.Commands.Db;

/// <summary>
/// Script-oriented <c>db sqlcmd</c>: executes a SQL script file against a saved connection through
/// TigerQuery's engine, in-process, in prepared mode. It prepares and populates databases for
/// automation such as E2E tests, so it is excluded from the command menu, does not require the
/// target to be a TigerWrapDb, and leaves TigerQuery's execution semantics unchanged.
/// </summary>
public sealed class DbSqlCmdCommand(SqlServerConnectionStore connectionStore)
    : TigerCliAsyncCommandHandler<DbSqlCmdCommand.Settings>
{
    public sealed class Settings : TigerCliSettings
    {
        [TigerCliArgument(0,
            Name = "connection",
            Description = "Saved connection to execute the script against (any database).",
            Provider = "connections",
            Promptable = TigerCliPromptable.Normal)]
        public string ConnectionName { get; set; } = string.Empty;

        [TigerCliOption("-f|--file",
            ValueName = "file",
            Required = true,
            Promptable = TigerCliPromptable.No,
            Description = "SQL script file to execute.")]
        public string FilePath { get; set; } = string.Empty;

        [TigerCliOption("-m|--mode",
            Promptable = TigerCliPromptable.No,
            Description = "TigerQuery parser mode: Normal (T-SQL and GO only), SqlCmd, or SqlCmdEx.")]
        public SqlCmdMode Mode { get; set; } = SqlCmdMode.SqlCmd;

        [TigerCliOption("--command-timeout",
            ValueName = "seconds",
            Promptable = TigerCliPromptable.No,
            Description = "Seconds each SQL batch may run before it is cancelled. 0 means no limit; "
                + "omit for the 30-second provider default. This is not the connection timeout.")]
        public int? CommandTimeout { get; set; }

        public override TigerCliValidationResult Validate()
        {
            if (CommandTimeout is < 0)
            {
                return TigerCliValidationResult.Error(
                    T("--command-timeout must be 0 (no limit) or a positive number of seconds."));
            }

            if (!string.IsNullOrWhiteSpace(FilePath) && !File.Exists(FilePath))
            {
                return TigerCliValidationResult.Error(F("SQL script file not found: {0}", FilePath));
            }

            return TigerCliValidationResult.Success();
        }
    }

    private const string InitialStatus = "Starting script...";

    public override async Task<int> ExecuteAsync(Settings s)
    {
        try
        {
            // No TigerWrapDb validation: the target is usually an application or test database.
            var (connectionString, error) = DbCommandSupport.ResolveConnectionString(connectionStore, s.ConnectionName);
            if (connectionString is null)
            {
                return Fail(ToolkitResponseCode.CliMissingConnection, error, s);
            }

            var databaseName = new SqlConnectionStringBuilder(connectionString).InitialCatalog;
            var scriptPath = Path.GetFullPath(s.FilePath);

            var runner = new ScriptRunner(s, InitialStatus);
            var (execution, exitCode) = await ExecuteScriptAsync(s, connectionString, databaseName, scriptPath, runner);
            runner.RenderIssues();

            if (exitCode != null)
            {
                return (int)exitCode.Value;
            }

            // The engine result is the failure authority: a failed batch the run continued past
            // still fails the command.
            if (execution!.ResultCode != ExecutionResultCode.Success || execution.FailedBatches > 0)
            {
                return Fail(
                    execution.ResultCode == ExecutionResultCode.UserCancelled
                        ? ToolkitResponseCode.TigerCliCancelled
                        : ToolkitResponseCode.DbError,
                    $"Script failed ({execution.ResultCode}; {execution.FailedBatches} failed batch(es), "
                        + $"{execution.ExecutedBatches} executed)."
                        + (execution.Exception is null ? "" : $" {execution.Exception.Message}"),
                    s);
            }

            TigerConsole.Render(new CliDetails()
                .ApplyPreset(CliTableStylePreset.Lucca)
                .AddTitle(s.E("[Success]Script completed successfully[/]"))
                .AddKey(s.T("Connection:"), s.ConnectionName)
                .Add(s.T("Database:"), databaseName)
                .Add(s.T("Script:"), scriptPath)
                .Add(s.T("Batches executed:"), $"{execution.ExecutedBatches} of {runner.TotalBatches?.ToString() ?? "?"}")
                .Add(s.T("Warnings:"), runner.Warnings)
                .Add(s.T("Duration:"), $"{execution.TotalDuration.TotalSeconds:F1}s"));

            return (int)ToolkitResponseCode.Ok;
        }
        catch (Exception ex)
        {
            return Fail(ToolkitResponseCode.CliUnhandledException, $"DbSqlCmdCommand failed: {ex.Message}", s);
        }
    }

    private static async Task<(ExecutionResult? execution, ToolkitResponseCode? exitCode)> ExecuteScriptAsync(
        Settings s,
        string connectionString,
        string databaseName,
        string scriptPath,
        ScriptRunner runner)
    {
        try
        {
            if (s.InteractionMode == TigerCliInteractionMode.NonInteractive)
            {
                TigerConsole.MarkupLine(s.E("Executing [Path]{0}[/] on [Key]{1}[/]...", scriptPath, s.ConnectionName));
                var execution = await runner.RunScriptAsync(
                    connectionString, scriptPath, s.Mode, s.CommandTimeout, context: null, CancellationToken.None);
                return (execution, null);
            }

            var activityResult = await TigerTui.RunActivityAsync(
                "Executing SQL script",
                CreateActivitySpec(s, databaseName),
                (ctx, ct) => runner.RunScriptAsync(connectionString, scriptPath, s.Mode, s.CommandTimeout, ctx, ct),
                ActivityStopMode.Cancel);

            if (activityResult.Outcome == ActivityOutcome.Failed && activityResult.Exception is not null)
            {
                throw activityResult.Exception;
            }

            if (!activityResult.IsCompleted)
            {
                var code = activityResult.Outcome == ActivityOutcome.TimedOut
                    ? ToolkitResponseCode.CliUnhandledException
                    : ToolkitResponseCode.TigerCliCancelled;
                Fail(code, $"Script did not complete: {activityResult.Outcome}. Earlier batches may have been applied.", s);
                return (null, code);
            }

            return (activityResult.Value, null);
        }
        catch (SqlException ex)
        {
            // Batch-level SQL errors are reported in the ExecutionResult; a SqlException escaping
            // the engine means the connection could not be opened.
            Fail(ToolkitResponseCode.DbError, $"Cannot connect to the database: {ex.Message}", s);
            return (null, ToolkitResponseCode.DbError);
        }
        catch (OperationCanceledException)
        {
            Fail(ToolkitResponseCode.TigerCliCancelled, "Script execution was cancelled.", s);
            return (null, ToolkitResponseCode.TigerCliCancelled);
        }
    }

    internal static ActivityDialogSpec CreateActivitySpec(Settings s, string databaseName)
    {
        return ScriptRunner.CreateActivitySpec(
            s,
            s.T("Batches:"),
            s.E("Executing {0} on {1}...", s.FilePath, databaseName),
            InitialStatus);
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
