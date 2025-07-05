using ItTiger.TigerWrap.Cli.Helpers;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerWrap.Core.Services;
using Microsoft.Extensions.Logging;
using Spectre.Console;
using Spectre.Console.Cli;
using System.ComponentModel;

namespace ItTiger.TigerWrap.Cli.Commands;

public sealed class LanguagesListCommand(ConnectionService _connectionService, ILogger<LanguagesListCommand> _logger)
    : AsyncCommand<LanguagesListCommand.Settings>
{
    public sealed class Settings : GlobalSettings
    {
        [CommandArgument(0, "<CONNECTION_NAME>")]
        [Description("The name of the connection to use.")]
        public string ConnectionName { get; set; } = string.Empty;
    }

    public override async Task<int> ExecuteAsync(CommandContext context, Settings settings)
    {
        try
        {
            var info = _connectionService.LoadConnections().FirstOrDefault(c => c.Name == settings.ConnectionName);
            if (info == null)
            {
                return CliHelper.Fail(
                    ToolkitDbHelper.ToolkitResponseCode.CliMissingConnection,
                    $"Connection named '{settings.ConnectionName}' not found.",
                    _logger
                );
            }

            var db = new ToolkitDbHelper(info.BuildConnectionString());
            await DbInfoValidator.ValidateAsync(db);

            _logger.LogInformation("Fetching available languages...");
            var languages = await db.GetLanguagesAsync();

            var table = new Table().Title("Available Languages")
                                   .AddColumn("Id")
                                   .AddColumn("Name")
                                   .AddColumn("Code");

            foreach (var lang in languages)
            {
                table.AddRow(((int)lang.Id).ToString(), lang.Name, lang.Code);
            }

            AnsiConsole.Write(table);
            return 0;
        }
        catch (Exception ex)
        {
            return CliHelper.Fail(
                ToolkitDbHelper.ToolkitResponseCode.CliUnhandledException,
                $"Unexpected error while listing languages: {ex.Message}", ex, _logger                
            );
        }
    }
}
