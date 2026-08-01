using System.Diagnostics;
using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Rendering;
using ItTiger.TigerCli.Terminal;
using ItTiger.TigerCli.Tui.Activity;
using ItTiger.TigerQuery;
using ItTiger.TigerQuery.Engine;
using ItTiger.TigerQuery.Events;
using ActivityContext = ItTiger.TigerCli.Tui.Activity.ActivityContext;

namespace ItTiger.TigerWrap.Cli.Commands.Db;

/// <summary>
/// Runs a packaged TigerWrapDb deployment script through TigerQuery in
/// <see cref="TigerQueryExecutionMode.Prepared"/> mode and turns the engine's execution plan
/// and batch events into "batch N of M" progress.
/// <para>
/// Prepared mode parses the whole sqlcmd structure - including <c>:r</c> includes and
/// <c>:setvar</c> - before the connection is opened, so a malformed script fails before the
/// database is touched, and the total batch count is known up front rather than discovered
/// while executing.
/// </para>
/// </summary>
internal sealed class ScriptRunner(TigerCliSettings settings, string initialStatus)
{
    private const int MaxIssuesShown = 10;

    private readonly object _lock = new();
    private readonly List<SqlCmdMessage> _issues = [];
    private readonly Stopwatch _elapsed = Stopwatch.StartNew();

    private string _status = initialStatus;

    /// <summary>Logical batches completed successfully so far.</summary>
    public int CompletedBatches { get; private set; }

    /// <summary>Total logical batch count reported by the prepared execution plan.</summary>
    public int? TotalBatches { get; private set; }

    /// <summary>Total scheduled executions (a <c>GO n</c> batch counts n times).</summary>
    public long? TotalExecutions { get; private set; }

    public int Warnings { get; private set; }

    public int Errors { get; private set; }

    public IReadOnlyList<SqlCmdMessage> Issues => _issues;

    /// <summary>Builds the shared activity layout used by <c>db install</c> and <c>db upgrade</c>.</summary>
    public static ActivityDialogSpec CreateActivitySpec(
        TigerCliSettings settings,
        string batchesLabel,
        string nonInteractiveMessage,
        string initialStatus)
    {
        return ActivityDialogSpec.Create()
            .AddColumn(width: 10)
            .AddColumn(sizing: CliColumnSizing.Star)
            .AddRow("status", row => row.Cell(0, 2).Text("{0}").Values(initialStatus))
            .AddRow("batches", row => row.Cell(0).Text(batchesLabel).Cell(1).Text("{0} of {1}").Values(0, "?"))
            .AddRow("issues", row => row.Cell(0).Text(settings.T("Issues:")).Cell(1).Text("{0} warning(s), {1} error(s)").Values(0, 0))
            .AddRow("elapsed", row => row.Cell(0).Text(settings.T("Elapsed:")).Cell(1).Text("{0}").Values("00:00"))
            .SetNonInteractiveMessage(nonInteractiveMessage)
            .Build();
    }

    public async Task<ExecutionResult> RunAsync(
        string connectionString,
        string databaseName,
        string scriptPath,
        ActivityContext? context,
        CancellationToken cancellationToken)
    {
        var options = new TigerQueryEngineOptions
        {
            ConnectionString = connectionString,
            ExecutionMode = TigerQueryExecutionMode.Prepared,
            Mode = SqlCmdMode.SqlCmdEx,
            ContinueOnError = false,
            // Injected variables take precedence over the script's own :setvar values, so the
            // script targets the connection's actual database even if it is not named TigerWrapDb.
            Variables = new Dictionary<string, string> { ["DatabaseName"] = databaseName },
            OnExecutionPlanReady = plan => HandlePlanReady(plan, context),
            OnMessage = (message, _) => HandleMessage(message, context),
            OnBatchEnd = end => HandleBatchEnd(end, context)
        };

        var engine = new TigerQueryEngine(options);
        return await engine.RunFromFileAsync(scriptPath, cancellationToken: cancellationToken);
    }

    /// <summary>Renders collected warnings and errors after an interactive run.</summary>
    public void RenderIssues()
    {
        // Non-interactive mode already printed every issue linearly.
        if (settings.InteractionMode == TigerCliInteractionMode.NonInteractive || _issues.Count == 0)
        {
            return;
        }

        foreach (var issue in _issues.Take(MaxIssuesShown))
        {
            if (issue.IsError)
            {
                TigerConsole.MarkupErrorLine(settings.E("{0}", FormatIssue(issue)));
            }
            else
            {
                TigerConsole.MarkupLine(settings.E("[Warning]{0}[/]", FormatIssue(issue)));
            }
        }

        if (_issues.Count > MaxIssuesShown)
        {
            TigerConsole.MarkupLine(settings.E("[Muted]...and {0} more issue(s).[/]", _issues.Count - MaxIssuesShown));
        }
    }

    private void HandlePlanReady(ExecutionPlanReady plan, ActivityContext? context)
    {
        Record(() =>
        {
            TotalBatches = plan.LogicalBatchCount;
            TotalExecutions = plan.TotalExecutionCount;
        });

        if (context is not null)
        {
            UpdateActivity(context);
        }
        else
        {
            TigerConsole.MarkupLine(settings.E(
                "[Muted]Script prepared: {0} batch(es), {1} execution(s).[/]",
                plan.LogicalBatchCount,
                plan.TotalExecutionCount));
        }
    }

    private void HandleMessage(SqlCmdMessage message, ActivityContext? context)
    {
        var text = message.Text?.Trim();

        Record(() =>
        {
            if (message.IsError)
            {
                Errors++;
                _issues.Add(message);
            }
            else if (message.Type == SqlCmdMessageType.Warning)
            {
                Warnings++;
                _issues.Add(message);
            }
            else if (!string.IsNullOrEmpty(text))
            {
                _status = text;
            }
        });

        if (context is not null)
        {
            UpdateActivity(context);
        }
        else if (!string.IsNullOrEmpty(text))
        {
            // Non-interactive: linear per-message diagnostics.
            if (message.IsError)
            {
                TigerConsole.MarkupErrorLine(settings.E("{0}", FormatIssue(message)));
            }
            else if (message.Type == SqlCmdMessageType.Warning)
            {
                TigerConsole.MarkupLine(settings.E("[Warning]{0}[/]", FormatIssue(message)));
            }
            else
            {
                TigerConsole.MarkupLine(settings.E("[Muted]{0}[/]", text));
            }
        }
    }

    private void HandleBatchEnd(BatchEnd end, ActivityContext? context)
    {
        Record(() =>
        {
            TotalBatches = end.TotalLogicalBatchCount ?? TotalBatches;
            TotalExecutions = end.TotalExecutionCount ?? TotalExecutions;

            if (end.Success)
            {
                CompletedBatches = Math.Max(CompletedBatches, end.BatchNumber);
            }
        });

        if (context is not null)
        {
            UpdateActivity(context);
        }
    }

    private void UpdateActivity(ActivityContext context)
    {
        Record(() =>
        {
            context.SetMessage("status", _status);
            context.SetValues("batches", CompletedBatches, TotalBatches?.ToString() ?? "?");
            context.SetValues("issues", Warnings, Errors);
            context.SetMessage("elapsed", _elapsed.Elapsed.ToString(@"mm\:ss"));
        });
    }

    private void Record(Action action)
    {
        lock (_lock)
        {
            action();
        }
    }

    private static string FormatIssue(SqlCmdMessage message)
    {
        var location = message.LineNumber.HasValue ? $" (line {message.LineNumber})" : "";
        return $"{message.Type}{location}: {message.Text}";
    }
}
