using ItTiger.TigerWrap.Cli.Helpers;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerWrap.Core.Services;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Spectre.Console;
using Spectre.Console.Cli;
using System.ComponentModel;
using System.Security.Claims;
using static ItTiger.TigerWrap.Core.ToolkitDbHelper;

namespace ItTiger.TigerWrap.Cli.Commands.Projects;

public sealed class ProjectsAddCommand(ConnectionService _connectionService, ILogger<ProjectsAddCommand> _logger)
    : AsyncCommand<ProjectsAddCommand.Settings>
{
    public sealed class Settings : LanguageScopedSettings
    {
        [CommandArgument(0, "<CONNECTION_NAME>")]
        [Description("The name of the connection to use.")]
        public string ConnectionName { get; set; } = string.Empty;

        [CommandArgument(1, "<PROJECT_NAME>")]
        [Description("The name of the new project.")]
        public string ProjectName { get; set; } = string.Empty;

        [CommandOption("--namespace")]
        [Description("The root namespace to use for generated code.")]
        public string NamespaceName { get; set; } = string.Empty;

        [CommandOption("--class")]
        [Description("The class name to generate.")]
        public string ClassName { get; set; } = string.Empty;

        [CommandOption("--class-access")]
        [Description("Class access modifier")]
        public ClassAccess? ClassAccess { get; set; } = ToolkitDbHelper.ClassAccess.Public;

        [CommandOption("--param-enum-mapping")]
        [Description("Parameter enum mapping strategy")]
        public ParamEnumMapping? ParamEnumMapping { get; set; } = ToolkitDbHelper.ParamEnumMapping.EnumNameWithOrWithoutId;

        [CommandOption("--map-result-set-enums")]
        [Description("Enable enum mapping in result sets (true/false)")]
        public bool? MapResultSetEnums { get; set; } = true;

        [CommandOption("--language-options")]
        [Description("Language options: hex (e.g. 0x0004) or comma-separated flags")]
        public string LanguageOptions { get; set; } = string.Empty;

        [CommandOption("--default-db")]
        [Description("Default database name for code generation")]
        public string? DefaultDatabase { get; set; }

        public override ValidationResult Validate()
        {
            if (string.IsNullOrWhiteSpace(ProjectName))
                return ValidationResult.Error("Project name is required.");

            if (string.IsNullOrWhiteSpace(NamespaceName))
                return ValidationResult.Error("Namespace name is required.");

            if (string.IsNullOrWhiteSpace(ClassName))
                return ValidationResult.Error("Class name is required.");

            if (!ClassAccess.HasValue || !Enum.IsDefined(typeof(ClassAccess), ClassAccess.Value))
            {
                return ValidationResult.Error($"Invalid class access modifier. Valid values: {ToolkitHelper.GetEnumValuesDescription<ClassAccess>()}");
            }
            if (!ParamEnumMapping.HasValue || !Enum.IsDefined(typeof(ParamEnumMapping), ParamEnumMapping.Value))
            {
                return ValidationResult.Error($"Parameter enum mapping strategy. Valid values: {ToolkitHelper.GetEnumValuesDescription<ParamEnumMapping>()}");
            }
            

            return base.Validate(); // Will also invoke LanguageScopedSettings.Validate()
        }
    }

    public override async Task<int> ExecuteAsync(CommandContext context, Settings s)
    {
        var (db, error) = await ToolkitHelper.TryResolveDbHelperAsync(_connectionService, s.ConnectionName);
        if (db == null)
        {
            return CliHelper.Fail(ToolkitResponseCode.CliMissingConnection, error, _logger);
        }

        var languageId = await CliHelper.ResolveLanguageAsync(db, s, _logger);
        if (languageId == null)
        {
            return (int)ToolkitResponseCode.CliInvalidArguments;
        }

        if (string.IsNullOrWhiteSpace(s.DefaultDatabase))
        {
            if (s.NonInteractive)
            {
                return CliHelper.Fail(ToolkitResponseCode.CliInteractiveNotAllowed, "Database is required in non-interactive mode.", _logger);
            }

            try
            {
                using var sql = new SqlConnection(db.ConnectionString);
                sql.Open();
                using var cmd = sql.CreateCommand();
                cmd.CommandText = "SELECT [name] FROM sys.databases WHERE database_id > 4 ORDER BY [name]";
                using var reader = cmd.ExecuteReader();
                var dbs = new List<string>();
                while (reader.Read()) { dbs.Add(reader.GetString(0)); }
                s.DefaultDatabase = AnsiConsole.Prompt(
                    new SelectionPrompt<string>()
                        .Title("Select a [green]user database[/]:")
                        .AddChoices(dbs));
            }
            catch (Exception ex)
            {
                return CliHelper.Fail(ToolkitResponseCode.CliFileWriteError, $"Could not connect to retrieve databases: {ex.Message}", _logger);
            }
        }


        long? languageOptions;
        if (string.IsNullOrWhiteSpace(s.LanguageOptions))
        {
            languageOptions = await CliHelper.SelectLanguageOptionsAsync("Select [dodgerblue1]language options[/]", db, languageId, null, true);
        }
        else
        {
            languageOptions = await ToolkitHelper.ResolveLanguageOptionsAsync(db, languageId, s.LanguageOptions);
        }
        

        var (rc, projectId, err) = await db.CreateProjectAsync(
            name: s.ProjectName,
            namespaceName: s.NamespaceName,
            className: s.ClassName,
            classAccessId: s.ClassAccess,
            languageId: (Language?)languageId,
            paramEnumMappingId: s.ParamEnumMapping,
            mapResultSetEnums: s.MapResultSetEnums,
            languageOptions: languageOptions,
            defaultDatabase: s.DefaultDatabase!);

        if (rc != 0 || !projectId.HasValue)
        {
            return CliHelper.Fail((ToolkitResponseCode)rc, err, _logger);
        }

        AnsiConsole.MarkupLine($"[green]Project '{s.ProjectName}' created with ID {projectId}![/]");
        return 0;
    }
}
