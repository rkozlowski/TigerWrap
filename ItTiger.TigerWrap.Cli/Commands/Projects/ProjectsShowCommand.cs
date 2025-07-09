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

        AnsiConsole.MarkupLine($"[bold green]Project Details: {Markup.Escape(s.ProjectName)}[/]");
        var details = new Table().RoundedBorder()
            .AddColumn("Property").AddColumn("Value")
            .AddRow("Project Name", $"[aqua]{Markup.Escape(s.ProjectName)}[/]")
            .AddRow("Class", Markup.Escape(className))
            .AddRow("Namespace", Markup.Escape(ns))
            .AddRow("LanguageId", Markup.Escape(languageId?.ToString() ?? ""))
            .AddRow("Default DB", Markup.Escape(defaultDb))
            .AddRow("Class Access", Markup.Escape(classAccess?.ToString() ?? ""))
            .AddRow("Enum Mapping", Markup.Escape(enumMapping?.ToString() ?? ""))
            .AddRow("Map Enums in Result Sets", mapEnums.HasValue ? (mapEnums.Value ? "Yes" : "No") : "")
            .AddRow("Options", optHex)
            .AddRow("", Markup.Escape(optNames));

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
                    Markup.Escape(r.NamePattern ?? ""), Markup.Escape(r.EscChar ?? ""), r.IsSetOfFlags.ToString(),
                    Markup.Escape(r.NameColumn ?? ""));
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
                    r.Id.ToString(), Markup.Escape(r.Schema), Markup.Escape(r.NameMatchId.ToString()),
                    Markup.Escape(r.NamePattern ?? ""), Markup.Escape(r.EscChar ?? ""),
                    rsHex, setHex);
                table.AddRow("", "", "", "", "", Markup.Escape(rsNames), Markup.Escape(setNames));
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
                    Markup.Escape(r.NamePart ?? ""),
                    Markup.Escape(r.NamePartTypeId.ToString()));
            }

            AnsiConsole.Write(table);
        }

        return 0;
    }
}
