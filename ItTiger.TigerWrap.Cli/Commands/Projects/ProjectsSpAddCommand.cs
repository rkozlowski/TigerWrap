using System.ComponentModel;
using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Terminal;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerQuery.Core;

namespace ItTiger.TigerWrap.Cli.Commands.Projects;

public sealed class ProjectsSpAddCommand(SqlServerConnectionStore connectionStore)
    : TigerCliAsyncCommandHandler<ProjectsSpAddCommand.Settings>
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
            Description = "Schema to map.")]
        public string Schema { get; set; } = string.Empty;

        [TigerCliOption("--match", Promptable = TigerCliPromptable.Normal, Description = "Name match type.")]
        public ToolkitDbHelper.NameMatch? NameMatch { get; set; } = ToolkitDbHelper.NameMatch.Any;

        [TigerCliOption("--pattern", Promptable = TigerCliPromptable.Normal, Description = "Stored procedure name pattern.")]
        public string? Pattern { get; set; }

        [TigerCliOption("--esc-char", Description = "Escape character for pattern matching.")]
        public string? EscChar { get; set; }

        [TigerCliOption("--langopt-reset",
            Provider = "language-options",
            Promptable = TigerCliPromptable.Normal,
            Description = "Language options to reset.")]
        [TigerCliMultiSelect]
        public long[]? LanguageOptionsReset { get; set; }

        [TigerCliOption("--langopt-set",
            Provider = "language-options",
            Promptable = TigerCliPromptable.Normal,
            Description = "Language options to set.")]
        [TigerCliMultiSelect]
        public long[]? LanguageOptionsSet { get; set; }
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
            var project = await db.GetProjectInfoAsync(settings.ProjectName);
            if (project.ReturnValue != 0 || project.ProjectId is null)
            {
                TigerConsole.MarkupErrorLine(settings.E("Could not find project: {0}", settings.ProjectName));
                return project.ReturnValue;
            }

            var resetValue = ProjectCommandProviders.CombineLanguageOptions(settings.LanguageOptionsReset) ?? 0;
            var setValue = ProjectCommandProviders.CombineLanguageOptions(settings.LanguageOptionsSet) ?? 0;

            var (rc, id, err) = await db.AddProjectStoredProcMappingAsync(
                projectId: project.ProjectId,
                schema: settings.Schema,
                nameMatchId: settings.NameMatch,
                namePattern: settings.Pattern,
                escChar: settings.EscChar,
                languageOptionsReset: resetValue,
                languageOptionsSet: setValue);

            if (rc != 0 || id is null)
            {
                TigerConsole.MarkupErrorLine(settings.E("{0}", err));
                return rc;
            }

            TigerConsole.MarkupLine(settings.E(
                "[Success]Stored procedure mapping added successfully (ID: {0}).[/]",
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
