using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Terminal;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerQuery.Core;

namespace ItTiger.TigerWrap.Cli.Commands.Projects;

public sealed class ProjectsEnumAddCommand(SqlServerConnectionStore connectionStore)
    : TigerCliAsyncCommandHandler<ProjectsEnumAddCommand.Settings>
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

        [TigerCliOption("--schema",
            Required = true,
            Provider = "schemas",
            Promptable = TigerCliPromptable.Normal,
            MinLength = 1,
            Description = "Schema containing the enum tables.")]
        public string Schema { get; set; } = string.Empty;

        [TigerCliOption("--name-match", Promptable = TigerCliPromptable.Normal, Description = "Enum name match strategy.")]
        public ToolkitDbHelper.NameMatch? NameMatch { get; set; } = ToolkitDbHelper.NameMatch.Any;

        [TigerCliOption("--name-pattern", Promptable = TigerCliPromptable.Normal, Description = "Name pattern for matching enum tables.")]
        public string NamePattern { get; set; } = string.Empty;

        [TigerCliOption("--esc-char", Description = "Escape character for pattern matching.")]
        public string? EscChar { get; set; }

        [TigerCliOption("--is-set-of-flags", Description = "Whether the enums are treated as flags.")]
        public bool? IsSetOfFlags { get; set; } = false;

        [TigerCliOption("--name-column", Description = "Optional name column override.")]
        public string? NameColumn { get; set; } = null;

        [TigerCliOption("--description",
            Description = "Static description text emitted as a description attribute on matched enums.")]
        public string? Description { get; set; }

        [TigerCliOption("--description-column",
            Description = "Column in the source enum table used to read enum member description text.")]
        public string? DescriptionColumn { get; set; }

        [TigerCliOption("--desc-attr-class",
            Description = "Description attribute class name override (e.g. DescriptionAttribute).")]
        public string? DescriptionAttributeClassName { get; set; }

        [TigerCliOption("--desc-attr-namespace",
            Description = "Namespace override of the description attribute class (e.g. System.ComponentModel).")]
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
            var (projectRc, projectId, projectErr) = await db.GetProjectIdAsync(settings.ProjectName);
            if (projectRc != 0 || !projectId.HasValue)
            {
                TigerConsole.MarkupErrorLine(settings.E("{0}", projectErr));
                return projectRc;
            }

            var (rc, id, err) = await db.AddProjectEnumMappingAsync(
                projectId: projectId,
                schema: settings.Schema,
                nameMatchId: settings.NameMatch,
                namePattern: settings.NamePattern,
                escChar: settings.EscChar,
                isSetOfFlags: settings.IsSetOfFlags,
                nameColumn: settings.NameColumn,
                description: settings.Description,
                descriptionColumn: settings.DescriptionColumn,
                descriptionAttributeClassName: settings.DescriptionAttributeClassName,
                descriptionAttributeNamespaceName: settings.DescriptionAttributeNamespaceName);

            if (rc != 0 || !id.HasValue)
            {
                TigerConsole.MarkupErrorLine(settings.E("{0}", err));
                return rc;
            }

            TigerConsole.MarkupLine(settings.E(
                "[Success]Enum mapping added successfully (ID: {0}).[/]",
                id.Value));
            return (int)ToolkitDbHelper.ToolkitResponseCode.Ok;
        }
        catch (Exception ex)
        {
            TigerConsole.MarkupErrorLine(settings.E("{0}", ex.Message));
            return (int)ToolkitDbHelper.ToolkitResponseCode.CliUnhandledException;
        }
    }
}
