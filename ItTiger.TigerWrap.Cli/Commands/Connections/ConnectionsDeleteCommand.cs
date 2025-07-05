using ItTiger.TigerWrap.Cli.Helpers;
using ItTiger.TigerWrap.Core.Services;
using Microsoft.Extensions.Logging;
using NLog;
using Spectre.Console;
using Spectre.Console.Cli;
using static ItTiger.TigerWrap.Core.ToolkitDbHelper;

namespace ItTiger.TigerWrap.Cli.Commands.Connections;

public class ConnectionsDeleteCommand(ConnectionService _service, ILogger<ConnectionsDeleteCommand> _logger)
    : Command<ConnectionsDeleteCommand.Settings>
{
    public class Settings : GlobalSettings
    {
        [CommandArgument(0, "<NAME>")]
        public string Name { get; set; } = string.Empty;
    }

    public override int Execute(CommandContext context, Settings settings)
    {
        if (!_service.DeleteConnection(settings.Name))
        {
            return CliHelper.Fail(
                ToolkitResponseCode.CliMissingConnection,
                $"Connection '{settings.Name}' not found.",
                _logger
            );
        }

        AnsiConsole.MarkupLine($"[green]Connection '{settings.Name}' deleted.[/]");
        _logger.LogInformation("Deleted connection: {Name}", settings.Name);
        return 0;
    }
}
