using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Primitives;
using ItTiger.TigerCli.Rendering;
using ItTiger.TigerCli.Terminal;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerQuery.Core;

namespace ItTiger.TigerWrap.Cli.Commands.ReadOnly;

public sealed class ProjectsListSettings : TigerCliSettings
{
    [TigerCliArgument(0,
        Name = "connection",
        Description = "Saved TigerWrap database connection.",
        Provider = "connections",
        Promptable = TigerCliPromptable.Normal,
        AutoSelectSingleChoice = true)]
    public string ConnectionName { get; set; } = string.Empty;

    [TigerCliOption("--language",
        Provider = "languages",
        Promptable = TigerCliPromptable.No,        
        Description = "Filter by language.")]
    public ToolkitDbHelper.Language? Language { get; set; }
}

public sealed class ProjectsListCommand(SqlServerConnectionStore connectionStore)
    : TigerCliAsyncCommandHandler<ProjectsListSettings>
{
    public override async Task<int> ExecuteAsync(ProjectsListSettings settings)
    {
        var (db, error) = await ToolkitHelper.TryResolveDbHelperAsync(
            connectionStore,
            settings.ConnectionName);
        if (db is null)
        {
            TigerConsole.MarkupErrorLine(settings.E("{0}", error));
            return (int)ToolkitDbHelper.ToolkitResponseCode.CliMissingConnection;
        }

        try
        {
            var projects = await db.GetProjectsAsync(settings.Language);
            if (!projects.Any())
            {
                TigerConsole.MarkupLine(settings.T("[Muted]No projects found.[/]"));
                return (int)ToolkitDbHelper.ToolkitResponseCode.Ok;
            }

            var table = new CliTable()
                .ApplyPreset(CliTableStylePreset.Milano)
                .AddTitle(settings.T("Projects"))
                .AddHeader(
                    settings.T("Id"),
                    settings.T("Name"),
                    settings.T("Class"),
                    settings.T("Namespace"),
                    settings.T("Language"),
                    settings.T("Language Code"));

            foreach (var project in projects)
            {
                table.AddRecord(
                    project.Id,
                    project.Name,
                    project.ClassName,
                    project.NamespaceName,
                    project.LanguageName,
                    project.LanguageCode);
            }

            TigerConsole.Render(table);
            return (int)ToolkitDbHelper.ToolkitResponseCode.Ok;
        }
        catch (Exception ex)
        {
            TigerConsole.MarkupErrorLine(settings.E("{0}", ex.Message));
            return (int)ToolkitDbHelper.ToolkitResponseCode.CliUnhandledException;
        }
    }
}
