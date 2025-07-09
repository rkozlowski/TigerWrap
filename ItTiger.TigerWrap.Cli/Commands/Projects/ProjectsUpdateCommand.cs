using ItTiger.TigerWrap.Cli.Helpers;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerWrap.Core.Services;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Spectre.Console;
using Spectre.Console.Cli;
using System.ComponentModel;
using static ItTiger.TigerWrap.Core.ToolkitDbHelper;

namespace ItTiger.TigerWrap.Cli.Commands.Projects;

public sealed class ProjectsUpdateCommand(ConnectionService _connectionService, ILogger<ProjectsUpdateCommand> _logger)
    : AsyncCommand<ProjectsUpdateCommand.Settings>
{
    public sealed class Settings : GlobalSettings
    {
        [CommandArgument(0, "<CONNECTION_NAME>")]
        [Description("The name of the connection to use.")]
        public string ConnectionName { get; set; } = string.Empty;

        [CommandArgument(1, "<PROJECT_NAME>")]
        [Description("The name of the project to update.")]
        public string ProjectName { get; set; } = string.Empty;

        [CommandOption("--new-name")]
        [Description("New name for the project")]
        public string? NewProjectName { get; set; }

        [CommandOption("--namespace")]
        [Description("New root namespace")]
        public string? NamespaceName { get; set; }

        [CommandOption("--class")]
        [Description("New class name")]
        public string? ClassName { get; set; }

        [CommandOption("--class-access")]
        [Description("New class access modifier")]
        public ClassAccess? ClassAccess { get; set; }

        [CommandOption("--param-enum-mapping")]
        [Description("New parameter enum mapping")]
        public ParamEnumMapping? ParamEnumMapping { get; set; }

        [CommandOption("--map-result-set-enums")]
        [Description("Enable enum mapping in result sets (yes | no)")]
        public BoolChoice? MapResultSetEnums { get; set; }

        [CommandOption("--language-options")]
        [Description("Language options to set (hex or comma-separated flags)")]
        public string? LanguageOptions { get; set; }

        [CommandOption("--default-db")]
        [Description("New default database for the project")]
        public string? DefaultDatabase { get; set; }

        public override ValidationResult Validate()
        {
            if (string.IsNullOrWhiteSpace(ConnectionName))
                return ValidationResult.Error("Missing connection name.");

            if (string.IsNullOrWhiteSpace(ProjectName))
                return ValidationResult.Error("Missing project name.");

            return ValidationResult.Success();
        }
    }

    public override async Task<int> ExecuteAsync(CommandContext context, Settings s)
    {
        var (db, error) = await ToolkitHelper.TryResolveDbHelperAsync(_connectionService, s.ConnectionName);
        if (db == null)
        {
            return CliHelper.Fail(ToolkitResponseCode.CliMissingConnection, error, _logger);
        }

        var prj = await db.GetProjectDetailsAsync(s.ProjectName);
        if (prj.ReturnValue != 0 || prj.ProjectId == null)
        {
            return CliHelper.Fail((ToolkitResponseCode)prj.ReturnValue, $"Could not find project: {Markup.Escape(s.ProjectName)}", _logger);
        }

        string? name = s.NewProjectName;
        string? ns = s.NamespaceName;
        string? cls = s.ClassName;
        ClassAccess? classAccess = s.ClassAccess;
        ParamEnumMapping? paramEnumMapping = s.ParamEnumMapping;
        bool? mapResultSetEnums = s.MapResultSetEnums.ToNullableBool();
        long? languageOptions = null;
        string? defaultDb = s.DefaultDatabase;

        if (!s.NonInteractive)
        {
            if (!classAccess.HasValue)
            {
                classAccess = await CliHelper.SelectEnumValueAsync<ClassAccess>(
                    "Select new [green]class access modifier[/] (Esc to skip):",
                    currentValue: prj.ClassAccessId);
            }

            if (!paramEnumMapping.HasValue)
            {
                paramEnumMapping = await CliHelper.SelectEnumValueAsync<ParamEnumMapping>(
                    "Select new [green]parameter enum mapping[/] (Esc to skip):",
                    currentValue: prj.ParamEnumMappingId);
            }

            if (!mapResultSetEnums.HasValue)
            {                
                mapResultSetEnums = (await CliHelper.AskBoolChoiceAsync("[green]Enable enum mapping in result sets[/]?", BoolChoice.Yes)).AsBool();
            }

            if (string.IsNullOrWhiteSpace(s.LanguageOptions))
            {
                languageOptions = await CliHelper.SelectLanguageOptionsAsync(
                    "Select [green]language options[/] to apply (optional)",
                    db,
                    prj.LanguageId,
                    prj.LanguageOptions,
                    true);
            }
            else
            {
                languageOptions = await ToolkitHelper.ResolveLanguageOptionsAsync(db, prj.LanguageId, s.LanguageOptions);
            }

            if (string.IsNullOrWhiteSpace(defaultDb))
            {
                defaultDb = await CliHelper.SelectDatabaseAsync(db, "Select [green]default database[/]:", prj.DefaultDatabase);
            }
        }
        else
        {
            if (!string.IsNullOrWhiteSpace(s.LanguageOptions))
            {
                languageOptions = await ToolkitHelper.ResolveLanguageOptionsAsync(db, prj.LanguageId, s.LanguageOptions);
            }
        }

        var (updateRc, updateErr) = await db.UpdateProjectAsync(
            projectId: prj.ProjectId,
            name: name,
            namespaceName: ns,
            className: cls,
            classAccessId: classAccess,
            paramEnumMappingId: paramEnumMapping,
            mapResultSetEnums: mapResultSetEnums,
            languageOptions: languageOptions,
            defaultDatabase: defaultDb);

        if (updateRc != 0)
        {
            return CliHelper.Fail((ToolkitResponseCode)updateRc, updateErr, _logger);
        }

        AnsiConsole.MarkupLine($"[green]Project '{Markup.Escape(s.ProjectName)}' updated successfully![/]");
        return 0;
    }
}
