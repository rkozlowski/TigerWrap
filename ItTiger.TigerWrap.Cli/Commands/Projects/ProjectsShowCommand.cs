using ItTiger.TigerWrap.Cli.Helpers;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerWrap.Core.Services;
using Microsoft.Extensions.Logging;
using Spectre.Console;
using Spectre.Console.Cli;
using System.ComponentModel;

namespace ItTiger.TigerWrap.Cli.Commands.Projects;

public sealed class ProjectsShowCommand(ConnectionService _connectionService, ILogger<ProjectsShowCommand> _logger)
    : AsyncCommand<ProjectsShowCommand.Settings>
{
    public sealed class Settings : GlobalSettings
    {
        [CommandArgument(0, "<CONNECTION_NAME>")]
        public string ConnectionName { get; set; } = string.Empty;

        [CommandArgument(1, "<PROJECT_NAME>")]
        public string ProjectName { get; set; } = string.Empty;
    }

    public override async Task<int> ExecuteAsync(CommandContext context, Settings s)
    {
        var (db, error) = await ToolkitHelper.TryResolveDbHelperAsync(_connectionService, s.ConnectionName);
        if (db == null)
        {
            return CliHelper.Fail(ToolkitDbHelper.ToolkitResponseCode.CliMissingConnection, error, _logger);
        }

        var (rc, projectId, languageId, defaultDb, className, ns, classAccess, options, enumMapping, mapEnums, err) =
            await db.GetProjectDetailsAsync(s.ProjectName);

        if (rc != 0 || !projectId.HasValue)
        {
            return CliHelper.Fail((ToolkitDbHelper.ToolkitResponseCode)rc, err, _logger);
        }

        var (optHex, optNames) = await ToolkitHelper.GetLanguageOptionsSummaryAsync(db, languageId, options);

        AnsiConsole.MarkupLine($"[bold green]Project Details: {s.ProjectName}[/]");
        var details = new Table().RoundedBorder()
            .AddColumn("Property").AddColumn("Value")
            .AddRow("Project Name", $"[aqua]{s.ProjectName}[/]")
            .AddRow("Class", className)
            .AddRow("Namespace", ns)
            .AddRow("LanguageId", languageId?.ToString() ?? "")
            .AddRow("Default DB", defaultDb)
            .AddRow("Class Access", classAccess?.ToString() ?? "")
            .AddRow("Enum Mapping", enumMapping?.ToString() ?? "")
            .AddRow("Map Enums in Result Sets", mapEnums.HasValue ? (mapEnums.Value ? "Yes" : "No") : "")
            .AddRow("Options", optHex)
            .AddRow("", optNames);

        AnsiConsole.Write(details);

        var enums = await db.GetProjectEnumMappingsAsync(projectId.Value);
        if (enums.Count > 0)
        {
            var table = new Table().Title("[blue]Enum Mappings[/]").RoundedBorder()
                .AddColumn("Id").AddColumn("Schema").AddColumn("NameMatchId").AddColumn("NamePattern").AddColumn("EscChar")
                .AddColumn("IsSetOfFlags").AddColumn("NameColumn");

            foreach (var r in enums.OrderBy(e => e.Id))
            {
                table.AddRow(
                    r.Id.ToString(), r.Schema, r.NameMatchId.ToString(),
                    r.NamePattern ?? "", r.EscChar ?? "", r.IsSetOfFlags.ToString(),
                    r.NameColumn ?? "");
            }

            AnsiConsole.Write(table);
        }

        var sps = await db.GetProjectStoredProcedureMappingsAsync(projectId.Value);
        if (sps.Count > 0)
        {
            var table = new Table().Title("[blue]Stored Procedure Mappings[/]").RoundedBorder()
                .AddColumn("Id").AddColumn("Schema").AddColumn("NameMatchId").AddColumn("NamePattern").AddColumn("EscChar")
                .AddColumn("LangOpt Reset").AddColumn("LangOpt Set");

            foreach (var r in sps.OrderBy(p => p.Id))
            {
                var (rsHex, rsNames) = await ToolkitHelper.GetLanguageOptionsSummaryAsync(db, languageId, r.LanguageOptionsReset);
                var (setHex, setNames) = await ToolkitHelper.GetLanguageOptionsSummaryAsync(db, languageId, r.LanguageOptionsSet);
                table.AddRow(
                    r.Id.ToString(), r.Schema, r.NameMatchId.ToString(),
                    r.NamePattern ?? "", r.EscChar ?? "",
                    rsHex, setHex);
                table.AddRow("", "", "", "", "", rsNames, setNames);
            }

            AnsiConsole.Write(table);
        }

        var names = await db.GetProjectNameNormalizationsAsync(projectId.Value);
        if (names.Count > 0)
        {
            var table = new Table().Title("[blue]Name Normalizations[/]").RoundedBorder()
                .AddColumn("Id").AddColumn("NamePart").AddColumn("NamePartTypeId");

            foreach (var r in names.OrderBy(n => n.Id))
            {
                table.AddRow(
                    r.Id.ToString(),
                    r.NamePart ?? "",
                    r.NamePartTypeId.ToString());
            }

            AnsiConsole.Write(table);
        }

        return 0;
    }
}
