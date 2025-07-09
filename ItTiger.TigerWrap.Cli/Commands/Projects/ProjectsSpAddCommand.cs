using System.ComponentModel;
using ItTiger.TigerWrap.Cli.Helpers;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerWrap.Core.Services;
using Microsoft.Extensions.Logging;
using Spectre.Console;
using Spectre.Console.Cli;
using static ItTiger.TigerWrap.Core.ToolkitDbHelper;

namespace ItTiger.TigerWrap.Cli.Commands.Projects;

public sealed class ProjectsSpAddCommand(ConnectionService _connectionService, ILogger<ProjectsSpAddCommand> _logger)
    : AsyncCommand<ProjectsSpAddCommand.Settings>
{
    public sealed class Settings : GlobalSettings
    {
        [CommandArgument(0, "<CONNECTION_NAME>")]
        [Description("Connection name to use.")]
        public string ConnectionName { get; set; } = string.Empty;

        [CommandArgument(1, "<PROJECT_NAME>")]
        [Description("Name of the project to modify.")]
        public string ProjectName { get; set; } = string.Empty;

        [CommandOption("--schema")]
        [Description("Schema to map (e.g. Toolkit)")]
        public string? Schema { get; set; }

        [CommandOption("--match")]
        [Description("Name match type (Any, ExactMatch, Prefix, Suffix, Regex)")]
        public NameMatch? NameMatch { get; set; } = ToolkitDbHelper.NameMatch.Any;

        [CommandOption("--pattern")]
        [Description("Optional stored procedure name pattern (e.g. Get% or ^sp_.*)")]
        public string? Pattern { get; set; }

        [CommandOption("--esc-char")]
        [Description("Optional escape character for pattern matching")]
        public string? EscChar { get; set; }

        [CommandOption("--langopt-reset")]
        [Description("Language options to reset: hex (0x...) or comma-separated flags")]
        public string? LangOptReset { get; set; }

        [CommandOption("--langopt-set")]
        [Description("Language options to set: hex (0x...) or comma-separated flags")]
        public string? LangOptSet { get; set; }

        public override ValidationResult Validate()
        {
            if (string.IsNullOrWhiteSpace(ConnectionName))
            {
                return ValidationResult.Error("Missing connection name.");
            }

            if (string.IsNullOrWhiteSpace(ProjectName))
            {
                return ValidationResult.Error("Missing project name.");
            }

            if (!NameMatch.HasValue || !Enum.IsDefined(typeof(NameMatch), NameMatch.Value))
            {
                return ValidationResult.Error($"Invalid name match type. Valid values: {ToolkitHelper.GetEnumValuesDescription<NameMatch>()}");
            }

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

        var (rc, projectId, languageId, _, _, _) = await db.GetProjectInfoAsync(s.ProjectName);
        if (rc != 0 || projectId is null)
        {
            return CliHelper.Fail((ToolkitResponseCode)rc, $"Could not find project: {Markup.Escape(s.ProjectName)}", _logger);
        }

        if (string.IsNullOrWhiteSpace(s.Schema) && !s.NonInteractive)
        {
            s.Schema = await CliHelper.SelectSchemaAsync(db, projectId.Value, "Select [green]schema[/]:");
        }

        long? resetValue;
        long? setValue;

        if (string.IsNullOrWhiteSpace(s.LangOptReset))
        {
            resetValue = s.NonInteractive
                ? 0
                : await CliHelper.SelectLanguageOptionsAsync(
                    prompt: "Select [green]language options to RESET[/] (optional)",
                    db: db,
                    languageId: languageId,
                    optionsValue: null,
                    isGlobalSelection: false);
        }
        else
        {
            resetValue = await ToolkitHelper.ResolveLanguageOptionsAsync(db, languageId, s.LangOptReset);
        }

        if (string.IsNullOrWhiteSpace(s.LangOptSet))
        {
            setValue = s.NonInteractive
                ? 0
                : await CliHelper.SelectLanguageOptionsAsync(
                    prompt: "Select [green]language options to SET[/] (optional)",
                    db: db,
                    languageId: languageId,
                    optionsValue: null,
                    isGlobalSelection: false);
        }
        else
        {
            setValue = await ToolkitHelper.ResolveLanguageOptionsAsync(db, languageId, s.LangOptSet);
        }

        var (addRc, id, err) = await db.AddProjectStoredProcMappingAsync(
            projectId: projectId,
            schema: s.Schema,
            nameMatchId: s.NameMatch,
            namePattern: s.Pattern,
            escChar: s.EscChar,
            languageOptionsReset: resetValue,
            languageOptionsSet: setValue);

        if (addRc != 0 || id == null)
        {
            return CliHelper.Fail((ToolkitResponseCode)addRc, err, _logger);
        }

        AnsiConsole.MarkupLine($"[green]Stored procedure mapping added successfully (ID: {id})[/]");
        return 0;
    }
}
