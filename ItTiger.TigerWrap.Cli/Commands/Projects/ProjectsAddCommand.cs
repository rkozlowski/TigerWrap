using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Terminal;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerQuery.Core;

namespace ItTiger.TigerWrap.Cli.Commands.Projects;

public sealed class ProjectsAddCommand(SqlServerConnectionStore connectionStore)
    : TigerCliAsyncCommandHandler<ProjectsAddCommand.Settings>
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
            Promptable = TigerCliPromptable.Normal,
            MinLength = 1)]
        public string ProjectName { get; set; } = string.Empty;

        [TigerCliOption("--namespace",
            Required = true,
            Promptable = TigerCliPromptable.Normal,
            MinLength = 1,
            Description = "Root namespace for generated code.")]
        public string NamespaceName { get; set; } = string.Empty;

        [TigerCliOption("--class",
            Required = true,
            Promptable = TigerCliPromptable.Normal,
            MinLength = 1,
            Description = "Class name to generate.")]
        public string ClassName { get; set; } = string.Empty;

        [TigerCliOption("--language",
            Required = true,
            Provider = "languages",
            Promptable = TigerCliPromptable.Normal,
            AutoSelectSingleChoice = true,
            Description = "Language for generated code.")]
        public ToolkitDbHelper.Language? Language { get; set; }

        [TigerCliOption("--default-db",
            Required = true,
            Provider = "databases",
            Promptable = TigerCliPromptable.Last,
            Description = "Default database name for code generation.")]
        public string DefaultDatabase { get; set; } = string.Empty;

        [TigerCliOption("--class-access", Description = "Class access modifier.")]
        public ToolkitDbHelper.ClassAccess? ClassAccess { get; set; } = ToolkitDbHelper.ClassAccess.Public;

        [TigerCliOption("--param-enum-mapping", Description = "Parameter enum mapping strategy.")]
        public ToolkitDbHelper.ParamEnumMapping? ParamEnumMapping { get; set; } =
            ToolkitDbHelper.ParamEnumMapping.EnumNameWithOrWithoutId;

        [TigerCliOption("--map-result-set-enums", Description = "Enable enum mapping in result sets.")]
        public bool? MapResultSetEnums { get; set; } = true;

        [TigerCliOption("--language-options",
            Provider = "language-options",
            Promptable = TigerCliPromptable.Normal,
            DependsOnOption = "--language",
            Description = "Language options to enable.")]
        [TigerCliMultiSelect]
        public long[]? LanguageOptions { get; set; }

        [TigerCliOption("--desc-attr-class",
            Description = "Default description attribute class name for generated enums (e.g. DescriptionAttribute).")]
        public string? DescriptionAttributeClassName { get; set; }

        [TigerCliOption("--desc-attr-namespace",
            Description = "Namespace of the default description attribute class (e.g. System.ComponentModel).")]
        public string? DescriptionAttributeNamespaceName { get; set; }
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
            var languageOptions = ProjectCommandProviders.CombineLanguageOptions(settings.LanguageOptions);

            var (rc, projectId, err) = await db.CreateProjectAsync(
                name: settings.ProjectName,
                namespaceName: settings.NamespaceName,
                className: settings.ClassName,
                classAccessId: settings.ClassAccess,
                languageId: settings.Language,
                paramEnumMappingId: settings.ParamEnumMapping,
                mapResultSetEnums: settings.MapResultSetEnums,
                languageOptions: languageOptions,
                defaultDatabase: settings.DefaultDatabase,
                descriptionAttributeClassName: settings.DescriptionAttributeClassName,
                descriptionAttributeNamespaceName: settings.DescriptionAttributeNamespaceName);

            if (rc != 0 || !projectId.HasValue)
            {
                TigerConsole.MarkupErrorLine(settings.E("{0}", err));
                return rc;
            }

            TigerConsole.MarkupLine(settings.E(
                "[Success]Project '{0}' created with ID {1}.[/]",
                settings.ProjectName,
                projectId.Value));
            return (int)ToolkitDbHelper.ToolkitResponseCode.Ok;
        }
        catch (Exception ex)
        {
            TigerConsole.MarkupErrorLine(settings.E("{0}", ex.Message));
            return (int)ToolkitDbHelper.ToolkitResponseCode.CliUnhandledException;
        }
    }
}
