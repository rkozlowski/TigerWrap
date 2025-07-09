using ItTiger.TigerWrap.Cli.Helpers;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerWrap.Core.Services;
using Microsoft.Extensions.Logging;
using Spectre.Console;
using Spectre.Console.Cli;
using System.ComponentModel;

namespace ItTiger.TigerWrap.Cli.Commands.Projects;

public sealed class ProjectsListCommand(ConnectionService _connectionService, ILogger<ProjectsListCommand> _logger)
    : AsyncCommand<ProjectsListCommand.Settings>
{
    public sealed class Settings : GlobalSettings
    {
        [CommandArgument(0, "<CONNECTION_NAME>")]
        [Description("The name of the connection to use.")]
        public string ConnectionName { get; set; } = string.Empty;

        [CommandOption("--language-id")]
        [Description("Filter by LanguageId")]
        public int? LanguageId { get; set; }

        [CommandOption("--language-code")]
        [Description("Filter by LanguageCode (e.g. CSharp, Python)")]
        public string LanguageCode { get; set; } = string.Empty;

        [CommandOption("--language-name")]
        [Description("Filter by LanguageName")]
        public string LanguageName { get; set; } = string.Empty;
    }

    public override async Task<int> ExecuteAsync(CommandContext context, Settings s)
    {
        var (db, error) = await ToolkitHelper.TryResolveDbHelperAsync(_connectionService, s.ConnectionName);
        if (db == null)
        {
            return CliHelper.Fail(ToolkitDbHelper.ToolkitResponseCode.CliMissingConnection, error, _logger);
        }

        try
        {
            byte? languageId = null;

            if (s.LanguageId.HasValue)
            {
                languageId = (byte)s.LanguageId.Value;
            }
            else if (!string.IsNullOrWhiteSpace(s.LanguageCode))
            {
                languageId = await ToolkitHelper.GetLanguageIdByCodeAsync(db, s.LanguageCode);
                if (languageId == null)
                {
                    return CliHelper.Fail(
                        ToolkitDbHelper.ToolkitResponseCode.CliInvalidArguments,
                        $"Unknown language code: '{s.LanguageCode}'",
                        _logger
                    );
                }
            }
            else if (!string.IsNullOrWhiteSpace(s.LanguageName))
            {
                languageId = await ToolkitHelper.GetLanguageIdByNameAsync(db, s.LanguageName);
                if (languageId == null)
                {
                    return CliHelper.Fail(
                        ToolkitDbHelper.ToolkitResponseCode.CliInvalidArguments,
                        $"Unknown language name: '{s.LanguageName}'",
                        _logger
                    );
                }
            }

            _logger.LogInformation("Fetching projects...");
            var projects = await db.GetProjectsAsync((ToolkitDbHelper.Language?)languageId);

            if (!projects.Any())
            {
                AnsiConsole.MarkupLine("[yellow]No projects found.[/]");
                return 0;
            }

            var table = new Table().Title("Available Projects")
                                   .AddColumn("Id")
                                   .AddColumn("Name")
                                   .AddColumn("Class")
                                   .AddColumn("Namespace")
                                   .AddColumn("Language");

            foreach (var proj in projects)
            {
                table.AddRow(
                    proj.Id.ToString(),
                    Markup.Escape(proj.Name),
                    Markup.Escape(proj.ClassName),
                    Markup.Escape(proj.NamespaceName),
                    Markup.Escape(proj.LanguageName));
            }

            AnsiConsole.Write(table);
            return 0;
        }
        catch (Exception ex)
        {
            return CliHelper.Fail(ToolkitDbHelper.ToolkitResponseCode.CliUnhandledException, ex.Message, ex, _logger);
        }
    }
}
