using System.ComponentModel;
using ItTiger.TigerWrap.Cli.Helpers;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerWrap.Core.Services;
using Microsoft.Extensions.Logging;
using Spectre.Console;
using Spectre.Console.Cli;
using static ItTiger.TigerWrap.Core.ToolkitDbHelper;

namespace ItTiger.TigerWrap.Cli.Commands.Projects;

public sealed class ProjectsNormAddCommand(ConnectionService _connectionService, ILogger<ProjectsNormAddCommand> _logger)
    : AsyncCommand<ProjectsNormAddCommand.Settings>
{
    public sealed class Settings : GlobalSettings
    {
        [CommandArgument(0, "<CONNECTION_NAME>")]
        [Description("Connection name to use.")]
        public string ConnectionName { get; set; } = string.Empty;

        [CommandArgument(1, "<PROJECT_NAME>")]
        [Description("Name of the project to modify.")]
        public string ProjectName { get; set; } = string.Empty;

        [CommandOption("--name-part")]
        [Description("The name part to normalize (e.g. tbl, usp)")]
        public string? NamePart { get; set; }

        [CommandOption("--type")]
        [Description("Name part type")]
        public NamePartType? NamePartTypeId { get; set; }

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
        {
            return CliHelper.Fail(ToolkitResponseCode.CliMissingConnection, error, _logger);
        }

        var (rc, projectId, _, _, _, _) = await db.GetProjectInfoAsync(s.ProjectName);
        if (rc != 0 || projectId is null)
        {
            return CliHelper.Fail((ToolkitResponseCode)rc, $"Could not find project: {s.ProjectName}", _logger);
        }

        var namePart = s.NamePart;
        if (string.IsNullOrWhiteSpace(namePart) && !s.NonInteractive)
        {
            namePart = AnsiConsole.Ask<string>("Enter the [green]name part[/] to normalize (e.g. tbl, usp):");
        }

        if (string.IsNullOrWhiteSpace(namePart))
        {
            return CliHelper.Fail(ToolkitResponseCode.CliMissingParameter, "Missing --name-part", _logger);
        }

        var namePartType = s.NamePartTypeId;
        if (!namePartType.HasValue && !s.NonInteractive)
        {
            namePartType = await CliHelper.SelectEnumValueAsync<NamePartType>("Select [green]name part type[/]:");
        }

        if (!namePartType.HasValue)
        {
            return CliHelper.Fail(ToolkitResponseCode.CliMissingParameter, "Missing --type", _logger);
        }

        var (addRc, id, err) = await db.AddProjectNameNormalizationAsync(
            projectId: projectId,
            namePart: namePart,
            namePartTypeId: namePartType);

        if (addRc != 0 || id == null)
        {
            return CliHelper.Fail((ToolkitResponseCode)addRc, err, _logger);
        }

        AnsiConsole.MarkupLine($"[green]Name normalization added successfully (ID: {id})[/]");
        return 0;
    }
}
