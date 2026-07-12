using System.ComponentModel;
using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Terminal;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerQuery.Core;

namespace ItTiger.TigerWrap.Cli.Commands.Projects;

public sealed class ProjectsNormAddCommand(SqlServerConnectionStore connectionStore)
    : TigerCliAsyncCommandHandler<ProjectsNormAddCommand.Settings>
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

        [TigerCliOption("--name-part",
            Required = true,
            Promptable = TigerCliPromptable.Normal,
            MinLength = 1,
            Description = "Name part to normalize.")]
        public string NamePart { get; set; } = string.Empty;

        [TigerCliOption("--type", Required = true, Promptable = TigerCliPromptable.Normal, Description = "Name part type.")]
        public ToolkitDbHelper.NamePartType? NamePartTypeId { get; set; }
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

            var (rc, id, err) = await db.AddProjectNameNormalizationAsync(
                projectId: project.ProjectId,
                namePart: settings.NamePart,
                namePartTypeId: settings.NamePartTypeId);

            if (rc != 0 || id is null)
            {
                TigerConsole.MarkupErrorLine(settings.E("{0}", err));
                return rc;
            }

            TigerConsole.MarkupLine(settings.E(
                "[Success]Name normalization added successfully (ID: {0}).[/]",
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
