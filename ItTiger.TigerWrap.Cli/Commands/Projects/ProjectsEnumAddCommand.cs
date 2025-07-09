using ItTiger.TigerWrap.Cli.Helpers;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerWrap.Core.Services;
using Microsoft.Extensions.Logging;
using Spectre.Console;
using Spectre.Console.Cli;
using System.ComponentModel;
using static ItTiger.TigerWrap.Core.ToolkitDbHelper;

namespace ItTiger.TigerWrap.Cli.Commands.Projects;

public sealed class ProjectsEnumAddCommand(ConnectionService _connectionService, ILogger<ProjectsEnumAddCommand> _logger)
    : AsyncCommand<ProjectsEnumAddCommand.Settings>
{
    public sealed class Settings : GlobalSettings
    {
        [CommandArgument(0, "<CONNECTION_NAME>")]
        [Description("The name of the connection to use.")]
        public string ConnectionName { get; set; } = string.Empty;

        [CommandArgument(1, "<PROJECT_NAME>")]
        [Description("The name of the project to update.")]
        public string ProjectName { get; set; } = string.Empty;

        [CommandOption("--schema")]
        [Description("The schema containing the enum tables.")]
        public string? Schema { get; set; }

        [CommandOption("--name-match")]
        [Description("Enum name match strategy (e.g. Any, ExactMatch).")]
        public NameMatch? NameMatch { get; set; } = ToolkitDbHelper.NameMatch.Any;

        [CommandOption("--name-pattern")]
        [Description("Name pattern for matching enum tables.")]
        public string NamePattern { get; set; } = string.Empty;

        [CommandOption("--esc-char")]
        [Description("Escape character for pattern matching.")]
        public string? EscChar { get; set; }

        [CommandOption("--is-set-of-flags")]
        [Description("Whether the enums are treated as flags (true/false).")]
        public bool? IsSetOfFlags { get; set; } = false;

        [CommandOption("--name-column")]
        [Description("Optional name column override.")]
        public string? NameColumn { get; set; } = null;

        public override ValidationResult Validate()
        {
            if (!NameMatch.HasValue || !Enum.IsDefined(typeof(NameMatch), NameMatch.Value))
                return ValidationResult.Error($"Invalid name match. Valid values: {ToolkitHelper.GetEnumValuesDescription<NameMatch>()}");
    
            return base.Validate();
        }
    }

    public override async Task<int> ExecuteAsync(CommandContext context, Settings s)
    {
        var (db, error) = await ToolkitHelper.TryResolveDbHelperAsync(_connectionService, s.ConnectionName);
        if (db == null)
            return CliHelper.Fail(ToolkitResponseCode.CliMissingConnection, error, _logger);

        var (rc, projectId, err) = await db.GetProjectIdAsync(s.ProjectName);
        if (rc != 0 || !projectId.HasValue)
            return CliHelper.Fail((ToolkitResponseCode)rc, err, _logger);

        if (string.IsNullOrWhiteSpace(s.Schema) && !s.NonInteractive)
        {
            s.Schema = await CliHelper.SelectSchemaAsync(db, projectId.Value, "Select [green]schema[/]:");
        }

        var (addRc, id, addErr) = await db.AddProjectEnumMappingAsync(
            projectId: projectId,
            schema: s.Schema,
            nameMatchId: s.NameMatch,
            namePattern: s.NamePattern,
            escChar: s.EscChar,
            isSetOfFlags: s.IsSetOfFlags,
            nameColumn: s.NameColumn);

        if (addRc != 0 || !id.HasValue)
            return CliHelper.Fail((ToolkitResponseCode)addRc, addErr, _logger);

        AnsiConsole.MarkupLine($"[green]Enum mapping added with ID {id}![/]");
        return 0;
    }
}
