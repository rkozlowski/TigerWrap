using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Primitives;
using ItTiger.TigerQuery.Core;
using ItTiger.TigerWrap.Core;

namespace ItTiger.TigerWrap.Cli.Commands.Projects;

internal static class ProjectCommandProviders
{
    public static async Task<IReadOnlyList<OptionItem<string>>> GetProjectChoicesAsync(
        SqlServerConnectionStore connectionStore,
        TigerCliProviderContext context)
    {
        var db = await ResolveDbFromContextAsync(connectionStore, context);
        if (db is null)
            return [];

        return await GetProjectChoicesAsync(db, context.CancellationToken);
    }

    public static async Task<IReadOnlyList<OptionItem<string>>> GetSchemaChoicesAsync(
        SqlServerConnectionStore connectionStore,
        string connectionName,
        string projectName,
        TigerCliProviderContext context)
    {
        var project = await ResolveProjectAsync(
            connectionStore,
            connectionName,
            projectName,
            context.CancellationToken);
        if (project is null)
            return [];

        var schemas = await project.Value.Db.GetProjectDbSchemasAsync(
            project.Value.ProjectId,
            context.CancellationToken);
        return schemas
            .OrderBy(schema => schema.Name)
            .Select(schema => new OptionItem<string>(schema.Name, schema.Name))
            .ToList();
    }

    public static async Task<IReadOnlyList<OptionItem<int>>> GetStoredProcedureMappingChoicesAsync(
        SqlServerConnectionStore connectionStore,
        string connectionName,
        string projectName,
        TigerCliProviderContext context)
    {
        var project = await ResolveProjectAsync(
            connectionStore,
            connectionName,
            projectName,
            context.CancellationToken);
        if (project is null)
            return [];

        var mappings = await project.Value.Db.GetProjectStoredProcedureMappingsAsync(
            project.Value.ProjectId,
            context.CancellationToken);
        return mappings
            .OrderBy(mapping => mapping.Schema)
            .ThenBy(mapping => mapping.NamePattern)
            .Select(mapping => new OptionItem<int>(
                mapping.Id,
                $"[{mapping.Id}] {mapping.Schema}.{mapping.NamePattern} ({mapping.NameMatchId})"))
            .ToList();
    }

    public static async Task<IReadOnlyList<OptionItem<int>>> GetEnumMappingChoicesAsync(
        SqlServerConnectionStore connectionStore,
        string connectionName,
        string projectName,
        TigerCliProviderContext context)
    {
        var project = await ResolveProjectAsync(
            connectionStore,
            connectionName,
            projectName,
            context.CancellationToken);
        if (project is null)
            return [];

        var mappings = await project.Value.Db.GetProjectEnumMappingsAsync(
            project.Value.ProjectId,
            context.CancellationToken);
        return mappings
            .OrderBy(mapping => mapping.Schema)
            .ThenBy(mapping => mapping.NamePattern)
            .Select(mapping => new OptionItem<int>(
                mapping.Id,
                $"[{mapping.Id}] {mapping.Schema}.{mapping.NamePattern} ({mapping.NameMatchId})"))
            .ToList();
    }

    public static async Task<IReadOnlyList<OptionItem<int>>> GetNameNormalizationChoicesAsync(
        SqlServerConnectionStore connectionStore,
        string connectionName,
        string projectName,
        TigerCliProviderContext context)
    {
        var project = await ResolveProjectAsync(
            connectionStore,
            connectionName,
            projectName,
            context.CancellationToken);
        if (project is null)
            return [];

        var normalizations = await project.Value.Db.GetProjectNameNormalizationsAsync(
            project.Value.ProjectId,
            context.CancellationToken);
        return normalizations
            .OrderBy(normalization => normalization.NamePartTypeId)
            .ThenBy(normalization => normalization.NamePart)
            .Select(normalization => new OptionItem<int>(
                normalization.Id,
                $"[{normalization.Id}] {normalization.NamePart} ({normalization.NamePartTypeId})"))
            .ToList();
    }

    public static async Task<IReadOnlyList<OptionItem<long>>> GetStoredProcedureLanguageOptionChoicesAsync(
        SqlServerConnectionStore connectionStore,
        string connectionName,
        string projectName,
        TigerCliProviderContext context)
    {
        var project = await ResolveProjectAsync(
            connectionStore,
            connectionName,
            projectName,
            context.CancellationToken);
        if (project is null)
            return [];

        return await GetLanguageOptionChoicesAsync(
            project.Value.Db,
            project.Value.LanguageId,
            context.CancellationToken);
    }

    private static async Task<IReadOnlyList<OptionItem<string>>> GetProjectChoicesAsync(
        ToolkitDbHelper db,
        CancellationToken cancellationToken)
    {
        var projects = await db.GetProjectsAsync(null, cancellationToken);
        return projects
            .OrderBy(project => project.Name)
            .Select(project => new OptionItem<string>(project.Name, project.Name))
            .ToList();
    }

    public static async Task<IReadOnlyList<OptionItem<ToolkitDbHelper.Language>>> GetLanguageChoicesAsync(
        SqlServerConnectionStore connectionStore,
        TigerCliProviderContext context)
    {
        var db = await ResolveDbFromContextAsync(connectionStore, context);
        if (db is null)
            return [];

        var languages = await db.GetLanguagesAsync(context.CancellationToken);
        return languages
            .OrderBy(language => language.Name)
            .Select(language => new OptionItem<ToolkitDbHelper.Language>(
                language.Id,
                $"{language.Name} ({language.Code})"))
            .ToList();
    }

    public static async Task<IReadOnlyList<OptionItem<string>>> GetDatabaseChoicesAsync(
        SqlServerConnectionStore connectionStore,
        TigerCliProviderContext context)
    {
        if (!TryGetConnectionName(context, out var connectionName))
            return [];

        var profile = connectionStore.Find(connectionName);
        if (profile is null)
            return [];

        var databases = await SqlServerDatabaseLister.ListAsync(profile, context.CancellationToken);
        return databases
            .Select(database => new OptionItem<string>(database, database))
            .ToList();
    }

    public static async Task<IReadOnlyList<OptionItem<long>>> GetLanguageOptionChoicesAsync(
        SqlServerConnectionStore connectionStore,
        ProjectsAddCommand.Settings settings,
        TigerCliProviderContext context)
    {
        if (settings.Language is null)
            return [];

        var db = await ResolveDbFromContextAsync(connectionStore, context);
        if (db is null)
            return [];

        return await GetLanguageOptionChoicesAsync(db, settings.Language, context.CancellationToken);
    }

    public static async Task<IReadOnlyList<OptionItem<long>>> GetLanguageOptionChoicesAsync(
        SqlServerConnectionStore connectionStore,
        ProjectsUpdateCommand.Settings settings,
        TigerCliProviderContext context)
    {
        var db = await ResolveDbFromContextAsync(connectionStore, context);
        if (db is null)
            return [];

        var project = await db.GetProjectDetailsAsync(settings.ProjectName, context.CancellationToken);
        if (project.ReturnValue != 0 || project.LanguageId is null)
            return [];

        return await GetLanguageOptionChoicesAsync(db, project.LanguageId, context.CancellationToken);
    }

    public static async Task<long[]?> ExpandLanguageOptionsAsync(
        ToolkitDbHelper db,
        ToolkitDbHelper.Language? languageId,
        long? combinedValue,
        CancellationToken cancellationToken = default)
    {
        if (!combinedValue.HasValue)
            return null;

        if (combinedValue.Value == 0)
            return [];

        var options = await db.GetLanguageOptionsAsync(languageId, cancellationToken);
        return options
            .Where(option => (combinedValue.Value & option.Value) == option.Value)
            .OrderBy(option => option.Value)
            .Select(option => option.Value)
            .ToArray();
    }

    public static long? CombineLanguageOptions(IEnumerable<long>? selectedOptions)
    {
        if (selectedOptions is null)
            return null;

        long combined = 0;
        foreach (var option in selectedOptions)
            combined |= option;

        return combined;
    }

    private static async Task<IReadOnlyList<OptionItem<long>>> GetLanguageOptionChoicesAsync(
        ToolkitDbHelper db,
        ToolkitDbHelper.Language? languageId,
        CancellationToken cancellationToken)
    {
        var options = await db.GetLanguageOptionsAsync(languageId, cancellationToken);
        return options
            .OrderBy(option => option.Value)
            .Select(option => new OptionItem<long>(
                option.Value,
                $"{option.Name} (0x{option.Value:X})"))
            .ToList();
    }

    private static async Task<ToolkitDbHelper?> ResolveDbFromContextAsync(
        SqlServerConnectionStore connectionStore,
        TigerCliProviderContext context)
    {
        if (!TryGetConnectionName(context, out var connectionName))
            return null;

        var (db, _) = await ToolkitHelper.TryResolveDbHelperAsync(connectionStore, connectionName);
        return db;
    }

    private static async Task<ToolkitDbHelper?> ResolveDbAsync(
        SqlServerConnectionStore connectionStore,
        string connectionName)
    {
        if (string.IsNullOrWhiteSpace(connectionName))
            return null;

        var (db, _) = await ToolkitHelper.TryResolveDbHelperAsync(connectionStore, connectionName);
        return db;
    }

    private static async Task<(ToolkitDbHelper Db, short ProjectId, ToolkitDbHelper.Language? LanguageId)?> ResolveProjectAsync(
        SqlServerConnectionStore connectionStore,
        string connectionName,
        string projectName,
        CancellationToken cancellationToken)
    {
        var db = await ResolveDbAsync(connectionStore, connectionName);
        if (db is null || string.IsNullOrWhiteSpace(projectName))
            return null;

        var project = await db.GetProjectInfoAsync(projectName, cancellationToken);
        if (project.ReturnValue != 0 || project.ProjectId is null)
            return null;

        return (db, project.ProjectId.Value, project.LanguageId);
    }

    private static bool TryGetConnectionName(TigerCliProviderContext context, out string connectionName)
    {
        if (context.TryGetValue<string>("connection", out var value) &&
            !string.IsNullOrWhiteSpace(value))
        {
            connectionName = value;
            return true;
        }

        if (context.TryGetValue<string>(nameof(ProjectsAddCommand.Settings.ConnectionName), out value) &&
            !string.IsNullOrWhiteSpace(value))
        {
            connectionName = value;
            return true;
        }

        connectionName = string.Empty;
        return false;
    }
}
