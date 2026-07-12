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

    [TigerCliOption("--language-id", Description = "Filter by language id.")]
    public int? LanguageId { get; set; }

    [TigerCliOption("--language-code", Description = "Filter by language code.")]
    public string? LanguageCode { get; set; }

    [TigerCliOption("--language-name", Description = "Filter by language name.")]
    public string? LanguageName { get; set; }
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
            var languageId = await ResolveLanguageIdAsync(db, settings);
            if (languageId.Error is not null)
            {
                TigerConsole.MarkupErrorLine(settings.E("{0}", languageId.Error));
                return (int)ToolkitDbHelper.ToolkitResponseCode.CliInvalidArguments;
            }

            var projects = await db.GetProjectsAsync((ToolkitDbHelper.Language?)languageId.Value);
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

    private static async Task<(byte? Value, string? Error)> ResolveLanguageIdAsync(
        ToolkitDbHelper db,
        ProjectsListSettings settings)
    {
        if (settings.LanguageId.HasValue)
            return ((byte)settings.LanguageId.Value, null);

        if (!string.IsNullOrWhiteSpace(settings.LanguageCode))
        {
            var id = await ToolkitHelper.GetLanguageIdByCodeAsync(db, settings.LanguageCode);
            return id is null
                ? (null, $"Unknown language code: '{settings.LanguageCode}'")
                : (id, null);
        }

        if (!string.IsNullOrWhiteSpace(settings.LanguageName))
        {
            var id = await ToolkitHelper.GetLanguageIdByNameAsync(db, settings.LanguageName);
            return id is null
                ? (null, $"Unknown language name: '{settings.LanguageName}'")
                : (id, null);
        }

        return (null, null);
    }
}
