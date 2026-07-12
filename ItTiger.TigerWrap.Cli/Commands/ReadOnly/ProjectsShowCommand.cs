using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Primitives;
using ItTiger.TigerCli.Rendering;
using ItTiger.TigerCli.Terminal;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerQuery.Core;

namespace ItTiger.TigerWrap.Cli.Commands.ReadOnly;

public sealed class ProjectsShowSettings : TigerCliSettings
{
    [TigerCliArgument(0,
        Name = "connection",
        Description = "Saved TigerWrap database connection.",
        Provider = "connections",
        Promptable = TigerCliPromptable.Normal,
        AutoSelectSingleChoice = true)]
    public string ConnectionName { get; set; } = string.Empty;

    [TigerCliArgument(1,
        Name = "project",
        Description = "Project name.",
        Provider = "projects",
        AutoSelectSingleChoice = true,
        Promptable = TigerCliPromptable.Normal)]
    public string ProjectName { get; set; } = string.Empty;
}

public sealed class ProjectsShowCommand(SqlServerConnectionStore connectionStore)
    : TigerCliAsyncCommandHandler<ProjectsShowSettings>
{
    public override async Task<int> ExecuteAsync(ProjectsShowSettings settings)
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
            var (rc, projectId, languageId, defaultDb, className, ns, classAccess, options, enumMapping, mapEnums, descAttrClass, descAttrNamespace, err) =
                await db.GetProjectDetailsAsync(settings.ProjectName);

            if (rc != 0 || !projectId.HasValue)
            {
                TigerConsole.MarkupErrorLine(settings.E("{0}", err));
                return rc;
            }

            var (optHex, optNames) = await ToolkitHelper.GetLanguageOptionsSummaryAsync(db, languageId, options);

            var details = new CliDetails()
                .ApplyPreset(CliTableStylePreset.Lucca)
                .AddTitle(settings.E("Project: {0}", settings.ProjectName))
                .AddKey(settings.T("Project Name:"), settings.ProjectName)
                .Add(settings.T("Class:"), className)
                .Add(settings.T("Namespace:"), ns)
                .Add(settings.T("Language Id:"), languageId)
                .Add(settings.T("Default DB:"), defaultDb)
                .Add(settings.T("Class Access:"), classAccess)
                .Add(settings.T("Enum Mapping:"), enumMapping)
                .Add(settings.T("Map Enums in Result Sets:"), mapEnums.HasValue ? (mapEnums.Value ? "Yes" : "No") : null)
                .AddOptional(settings.T("Description Attribute:"), FormatDescriptionAttribute(descAttrClass, descAttrNamespace))
                .Add(settings.T("Options:"), optHex)
                .AddOptional(settings.T("Option Names:"), optNames);

            TigerConsole.Render(details);

            await RenderEnumMappingsAsync(db, settings, projectId.Value);
            await RenderStoredProcedureMappingsAsync(db, settings, projectId.Value, languageId);
            await RenderNameNormalizationsAsync(db, settings, projectId.Value);

            return (int)ToolkitDbHelper.ToolkitResponseCode.Ok;
        }
        catch (Exception ex)
        {
            TigerConsole.MarkupErrorLine(settings.E("{0}", ex.Message));
            return (int)ToolkitDbHelper.ToolkitResponseCode.CliUnhandledException;
        }
    }

    private static async Task RenderEnumMappingsAsync(
        ToolkitDbHelper db,
        ProjectsShowSettings settings,
        short projectId)
    {
        var rows = (await db.GetProjectEnumMappingsAsync(projectId))
            .OrderBy(row => row.Id)
            .ToList();
        if (rows.Count == 0)
            return;

        var list = new CliList<ToolkitDbHelper.GetProjectEnumMappingsResult>()
            .ApplyPreset(CliTableStylePreset.Milano)
            .AddTitle(settings.T("Enum mappings"))
            .AddKeyColumn(settings.T("Id"), row => row.Id)
            .AddColumn(settings.T("Schema"), row => row.Schema)
            .AddColumn(settings.T("Name Match"), row => row.NameMatchId)
            .AddColumn(settings.T("Name Pattern"), row => row.NamePattern)
            .AddColumn(settings.T("Esc Char"), row => row.EscChar)
            .AddColumn(settings.T("Set Of Flags"), row => row.IsSetOfFlags)
            .AddColumn(settings.T("Name Column"), row => row.NameColumn)
            .AddColumn(settings.T("Description"), row => row.Description).SetWidth(maxWidth: 30).SetWrapping(CliWrapping.CharWrapTruncate)
            .AddColumn(settings.T("Desc Column"), row => row.DescriptionColumn)
            .AddColumn(settings.T("Desc Attribute"), row => FormatDescriptionAttribute(row.DescriptionAttributeClassName, row.DescriptionAttributeNamespaceName));

        TigerConsole.Render(list.Render(rows));
    }

    private static string? FormatDescriptionAttribute(string? className, string? namespaceName)
    {
        if (string.IsNullOrWhiteSpace(className))
            return string.IsNullOrWhiteSpace(namespaceName) ? null : namespaceName;

        return string.IsNullOrWhiteSpace(namespaceName) ? className : $"{namespaceName}.{className}";
    }

    private static async Task RenderStoredProcedureMappingsAsync(
        ToolkitDbHelper db,
        ProjectsShowSettings settings,
        short projectId,
        ToolkitDbHelper.Language? languageId)
    {
        var rows = (await db.GetProjectStoredProcedureMappingsAsync(projectId))
            .OrderBy(row => row.Id)
            .ToList();
        if (rows.Count == 0)
            return;

        var displayRows = new List<StoredProcedureMappingRow>();
        foreach (var row in rows)
        {
            var (resetHex, resetNames) = await ToolkitHelper.GetLanguageOptionsSummaryAsync(
                db,
                languageId,
                row.LanguageOptionsReset);
            var (setHex, setNames) = await ToolkitHelper.GetLanguageOptionsSummaryAsync(
                db,
                languageId,
                row.LanguageOptionsSet);

            displayRows.Add(new StoredProcedureMappingRow(
                row.Id,
                row.Schema,
                row.NameMatchId,
                row.NamePattern,
                row.EscChar,
                FormatOptions(resetHex, resetNames),
                FormatOptions(setHex, setNames)));
        }

        var list = new CliList<StoredProcedureMappingRow>()
            .ApplyPreset(CliTableStylePreset.Milano)
            .AddTitle(settings.T("Stored procedure mappings"))
            .AddKeyColumn(settings.T("Id"), row => row.Id)
            .AddColumn(settings.T("Schema"), row => row.Schema)
            .AddColumn(settings.T("Name Match"), row => row.NameMatch)
            .AddColumn(settings.T("Name Pattern"), row => row.NamePattern)
            .AddColumn(settings.T("Esc Char"), row => row.EscChar)
            .AddColumn(settings.T("LangOpt Reset"), row => row.LanguageOptionsReset).SetWidth(maxWidth: 30).SetWrapping(CliWrapping.CharWrapTruncate)
            .AddColumn(settings.T("LangOpt Set"), row => row.LanguageOptionsSet).SetWidth(maxWidth: 30).SetWrapping(CliWrapping.CharWrapTruncate);

        TigerConsole.Render(list.Render(displayRows));
    }

    private static async Task RenderNameNormalizationsAsync(
        ToolkitDbHelper db,
        ProjectsShowSettings settings,
        short projectId)
    {
        var rows = (await db.GetProjectNameNormalizationsAsync(projectId))
            .OrderBy(row => row.Id)
            .ToList();
        if (rows.Count == 0)
            return;

        var list = new CliList<ToolkitDbHelper.GetProjectNameNormalizationsResult>()
            .ApplyPreset(CliTableStylePreset.Milano)
            .AddTitle(settings.T("Name normalizations"))
            .AddKeyColumn(settings.T("Id"), row => row.Id)
            .AddColumn(settings.T("Name Part"), row => row.NamePart)
            .AddColumn(settings.T("Name Part Type"), row => row.NamePartTypeId);

        TigerConsole.Render(list.Render(rows));
    }

    private static string FormatOptions(string hex, string names)
    {
        if (string.IsNullOrWhiteSpace(names))
            return hex;

        if (string.IsNullOrWhiteSpace(hex))
            return names;

        return $"{hex}{Environment.NewLine}{names}";
    }

    private sealed record StoredProcedureMappingRow(
        int Id,
        string Schema,
        ToolkitDbHelper.NameMatch NameMatch,
        string NamePattern,
        string EscChar,
        string LanguageOptionsReset,
        string LanguageOptionsSet);
}
