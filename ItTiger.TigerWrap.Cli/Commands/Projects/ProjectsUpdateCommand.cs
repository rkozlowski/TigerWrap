using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Terminal;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerQuery.Core;

namespace ItTiger.TigerWrap.Cli.Commands.Projects;

public sealed class ProjectsUpdateCommand(SqlServerConnectionStore connectionStore)
    : TigerCliAsyncCommandHandler<ProjectsUpdateCommand.Settings>
{
    public sealed class Settings : TigerCliSettings
    {
        [TigerCliArgument(0,
            Name = "connection",
            Description = "Saved TigerWrap database connection.",
            Provider = "connections",
            Promptable = TigerCliPromptable.Normal,
            AutoSelectSingleChoice = true,
            MinLength = 1)]
        public string ConnectionName { get; set; } = string.Empty;

        [TigerCliArgument(1,
            Name = "project",
            Description = "Project name.",
            Provider = "projects",
            Promptable = TigerCliPromptable.Normal,
            AutoSelectSingleChoice = true,
            MinLength = 1)]
        public string ProjectName { get; set; } = string.Empty;

        [TigerCliOption("--new-name",
            Promptable = TigerCliPromptable.Normal,
            MinLength = 1,
            Description = "New project name.")]
        public string? NewProjectName { get; set; }

        [TigerCliOption("--namespace",
            Promptable = TigerCliPromptable.Normal,
            MinLength = 1,
            Description = "Root namespace for generated code.")]
        public string? NamespaceName { get; set; }

        [TigerCliOption("--class",
            Promptable = TigerCliPromptable.Normal,
            MinLength = 1,
            Description = "Class name to generate.")]
        public string? ClassName { get; set; }

        [TigerCliOption("--default-db",
            Provider = "databases",
            Promptable = TigerCliPromptable.Last,
            Description = "Default database name for code generation.")]
        public string? DefaultDatabase { get; set; }

        [TigerCliOption("--class-access", Promptable = TigerCliPromptable.Normal, Description = "Class access modifier.")]
        public ToolkitDbHelper.ClassAccess? ClassAccess { get; set; }

        [TigerCliOption("--param-enum-mapping", Promptable = TigerCliPromptable.Normal, Description = "Parameter enum mapping strategy.")]
        public ToolkitDbHelper.ParamEnumMapping? ParamEnumMapping { get; set; }

        [TigerCliOption("--map-result-set-enums", Promptable = TigerCliPromptable.Normal, Description = "Enable enum mapping in result sets.")]
        public bool? MapResultSetEnums { get; set; }

        [TigerCliOption("--language-options",
            Provider = "language-options",
            Promptable = TigerCliPromptable.Normal,
            Description = "Language options to enable.")]
        [TigerCliMultiSelect]
        public long[]? LanguageOptions { get; set; }
    }

    internal static async Task<TigerCliEditLoad<Settings>> LoadAsync(
        SqlServerConnectionStore connectionStore,
        Settings settings)
    {
        var (db, _) = await ToolkitHelper.TryResolveDbHelperAsync(
            connectionStore,
            settings.ConnectionName);
        if (db is null)
            return TigerCliEditLoad<Settings>.NotFound();

        var project = await db.GetProjectDetailsAsync(settings.ProjectName);
        if (project.ReturnValue != 0 || project.ProjectId is null)
            return TigerCliEditLoad<Settings>.NotFound();

        return TigerCliEditLoad<Settings>.Found(new Settings
        {
            NewProjectName = settings.ProjectName,
            NamespaceName = project.NamespaceName,
            ClassName = project.ClassName,
            DefaultDatabase = project.DefaultDatabase,
            ClassAccess = project.ClassAccessId,
            ParamEnumMapping = project.ParamEnumMappingId,
            MapResultSetEnums = project.MapResultSetEnums,
            LanguageOptions = await ProjectCommandProviders.ExpandLanguageOptionsAsync(
                db,
                project.LanguageId,
                project.LanguageOptions)
        });
    }

    public override async Task<int> ExecuteAsync(Settings settings)
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
            var project = await db.GetProjectDetailsAsync(settings.ProjectName);
            if (project.ReturnValue != 0 || project.ProjectId is null)
            {
                TigerConsole.MarkupErrorLine(settings.E("Could not find project: {0}", settings.ProjectName));
                return project.ReturnValue;
            }

            var languageOptions = ProjectCommandProviders.CombineLanguageOptions(settings.LanguageOptions);

            var (updateRc, updateErr) = await db.UpdateProjectAsync(
                projectId: project.ProjectId,
                name: settings.NewProjectName,
                namespaceName: settings.NamespaceName,
                className: settings.ClassName,
                classAccessId: settings.ClassAccess,
                paramEnumMappingId: settings.ParamEnumMapping,
                mapResultSetEnums: settings.MapResultSetEnums,
                languageOptions: languageOptions,
                defaultDatabase: settings.DefaultDatabase);

            if (updateRc != 0)
            {
                TigerConsole.MarkupErrorLine(settings.E("{0}", updateErr));
                return updateRc;
            }

            TigerConsole.MarkupLine(settings.E(
                "[Success]Project '{0}' updated successfully.[/]",
                settings.ProjectName));
            return (int)ToolkitDbHelper.ToolkitResponseCode.Ok;
        }
        catch (Exception ex)
        {
            TigerConsole.MarkupErrorLine(settings.E("{0}", ex.Message));
            return (int)ToolkitDbHelper.ToolkitResponseCode.CliUnhandledException;
        }
    }
}
