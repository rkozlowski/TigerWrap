using Spectre.Console;
using Spectre.Console.Cli;
using ItTiger.TigerWrap.Core.Services;
using ItTiger.TigerWrap.Cli.Helpers;
using Microsoft.Extensions.Logging;
using static ItTiger.TigerWrap.Core.ToolkitDbHelper;

namespace ItTiger.TigerWrap.Cli.Commands.Connections;

public class ConnectionsListCommand(ConnectionService _service, ILogger<ConnectionsListCommand> _logger)
    : Command
{
    public override int Execute(CommandContext context)
    {
        var connections = _service.LoadConnections();

        if (connections.Count == 0)
        {
            return CliHelper.Fail(
                ToolkitResponseCode.CliMissingConnection,
                "No connections defined.",
                _logger
            );
        }

        var table = new Table()
            .RoundedBorder()
            .AddColumn("Name")
            .AddColumn("Server")
            .AddColumn("Database");

        foreach (var c in connections)
        {
            table.AddRow(Markup.Escape(c.Name), Markup.Escape(c.Server), Markup.Escape(c.Database));
        }

        AnsiConsole.Write(table);
        _logger.LogInformation("Listed connections.");
        return 0;
    }
}
