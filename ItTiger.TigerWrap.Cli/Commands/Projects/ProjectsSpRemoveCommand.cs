using System.ComponentModel;
using ItTiger.TigerWrap.Cli.Helpers;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerWrap.Core.Services;
using Microsoft.Extensions.Logging;
using Spectre.Console;
using Spectre.Console.Cli;
using static ItTiger.TigerWrap.Core.ToolkitDbHelper;

namespace ItTiger.TigerWrap.Cli.Commands.Projects;

public sealed class ProjectsSpRemoveCommand(ConnectionService _connectionService, ILogger<ProjectsSpRemoveCommand> _logger)
    : AsyncCommand<ProjectsSpRemoveCommand.Settings>
{
    public sealed class Settings : GlobalSettings
    {
        [CommandArgument(0, "<CONNECTION_NAME>")]
        [Description("Connection name to use.")]
        public string ConnectionName { get; set; } = string.Empty;

        [CommandArgument(1, "<PROJECT_NAME>")]
        [Description("Name of the project to modify.")]
        public string ProjectName { get; set; } = string.Empty;

        [CommandOption("--id")]
        [Description("Stored procedure mapping ID to remove (omit for selection prompt)")]
        public int? SpMappingId { get; set; }

        public override ValidationResult Validate()
        {
            if (string.IsNullOrWhiteSpace(ConnectionName))
                return ValidationResult.Error("Missing connection name.");

            if (string.IsNullOrWhiteSpace(ProjectName))
                return ValidationResult.Error("Missing project name.");

            return ValidationResult.Success();
        }
    }

    public override async Task<int> ExecuteAsync(CommandContext context, Settings s)
    {
        var (db, error) = await ToolkitHelper.TryResolveDbHelperAsync(_connectionService, s.ConnectionName);
        if (db == null)
            return CliHelper.Fail(ToolkitResponseCode.CliMissingConnection, error, _logger);

        var (rc, projectId, _, _, _, _) = await db.GetProjectInfoAsync(s.ProjectName);
        if (rc != 0 || projectId is null)
            return CliHelper.Fail((ToolkitResponseCode)rc, $"Could not find project: {s.ProjectName}", _logger);

        var spMappingId = s.SpMappingId;

        if (!spMappingId.HasValue && !s.NonInteractive)
        {
            var all = await db.GetProjectStoredProcedureMappingsAsync(projectId);
            if (all.Count == 0)
                return CliHelper.Fail(ToolkitResponseCode.CliNoItemsAvailable, "No stored procedure mappings defined for this project.", _logger);

            var choices = all.Select(x =>
            {
                var desc = Markup.Escape($"[{x.Id}] {x.Schema}.{x.NamePattern} ({x.NameMatchId})");
                return new SelectionItem<int>(x.Id, desc);
            }).ToList();

            spMappingId = AnsiConsole.Prompt(
                new SelectionPrompt<SelectionItem<int>>()
                    .Title("Select [green]stored procedure mapping to remove[/]:")
                    .AddChoices(choices)
            ).Value;
        }

        if (!spMappingId.HasValue)
            return CliHelper.Fail(ToolkitResponseCode.CliMissingParameter, "Missing stored procedure mapping ID (--id)", _logger);

        var (removeRc, err) = await db.RemoveProjectStoredProcMappingAsync(projectId, spMappingId);
        if (removeRc != 0)
            return CliHelper.Fail((ToolkitResponseCode)removeRc, err, _logger);

        AnsiConsole.MarkupLine($"[green]Stored procedure mapping removed successfully (ID: {spMappingId})[/]");
        return 0;
    }

}
