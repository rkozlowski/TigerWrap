using System.ComponentModel;
using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Terminal;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerQuery.Core;

namespace ItTiger.TigerWrap.Cli.Commands.Projects;

public sealed class ProjectsSpRemoveCommand(SqlServerConnectionStore connectionStore)
    : TigerCliAsyncCommandHandler<ProjectsSpRemoveCommand.Settings>
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

        [TigerCliOption("--id",
            Required = true,
            Provider = "stored-procedure-mappings",
            Promptable = TigerCliPromptable.Normal,
            Description = "Stored procedure mapping ID to remove.")]
        public int? SpMappingId { get; set; }
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

            var (rc, err) = await db.RemoveProjectStoredProcMappingAsync(
                project.ProjectId,
                settings.SpMappingId);
            if (rc != 0)
            {
                TigerConsole.MarkupErrorLine(settings.E("{0}", err));
                return rc;
            }

            TigerConsole.MarkupLine(settings.E(
                "[Success]Stored procedure mapping removed successfully (ID: {0}).[/]",
                settings.SpMappingId));
            return (int)ToolkitDbHelper.ToolkitResponseCode.Ok;
        }
        catch (Exception ex)
        {
            TigerConsole.MarkupErrorLine(settings.E("{0}", ex.Message));
            return (int)ToolkitDbHelper.ToolkitResponseCode.CliUnhandledException;
        }
    }
}
