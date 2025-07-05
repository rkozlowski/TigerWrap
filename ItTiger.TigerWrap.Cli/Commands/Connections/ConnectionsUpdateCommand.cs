using ItTiger.TigerWrap.Cli.Helpers;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerWrap.Core.Services;
using Microsoft.Extensions.Logging;
using NLog;
using Spectre.Console;
using Spectre.Console.Cli;

namespace ItTiger.TigerWrap.Cli.Commands.Connections;

public class ConnectionsUpdateCommand(ConnectionService _service, ILogger<ConnectionsUpdateCommand> _logger)
    : Command<ConnectionsUpdateCommand.Settings>
{
    public class Settings : GlobalSettings
    {
        [CommandArgument(0, "<NAME>")]
        public string Name { get; set; } = string.Empty;

        [CommandOption("--server <SERVER>")]
        public string Server { get; set; } = string.Empty;

        [CommandOption("--auth <AUTH>")]
        public AuthenticationType? Authentication { get; set; }

        [CommandOption("--username <USERNAME>")]
        public string Username { get; set; } = string.Empty;

        [CommandOption("--database <DATABASE>")]
        public string Database { get; set; } = string.Empty;

        [CommandOption("--encrypt <ENCRYPT>")]
        public EncryptOption? Encrypt { get; set; }

        [CommandOption("--trust-server-cert")]
        public bool? TrustServerCertificate { get; set; }
    }

    public override int Execute(CommandContext context, Settings s)
    {
        var conn = _service.LoadConnections().FirstOrDefault(c => c.Name == s.Name);
        if (conn == null)
        {
            return CliHelper.Fail(ToolkitDbHelper.ToolkitResponseCode.CliMissingConnection, $"Connection '{s.Name}' not found.", _logger);
        }

        if (!string.IsNullOrEmpty(s.Server))
        {
            conn.Server = s.Server;
        }
        if (s.Authentication.HasValue)
        {
            conn.Authentication = s.Authentication.Value;
        }
        if (!string.IsNullOrEmpty(s.Username))
        {
            conn.Username = s.Username;
        }
        if (!string.IsNullOrEmpty(s.Database))
        {
            conn.Database = s.Database;
        }
        if (s.Encrypt.HasValue)
        {
            conn.Encrypt = s.Encrypt.Value;
        }
        if (s.TrustServerCertificate.HasValue)
        {
            conn.TrustServerCertificate = s.TrustServerCertificate.Value;
        }

        if (conn.Authentication == AuthenticationType.SqlPassword && string.IsNullOrEmpty(conn.PlainPassword))
        {
            if (s.NonInteractive)
            {
                return CliHelper.Fail(ToolkitDbHelper.ToolkitResponseCode.CliInteractiveNotAllowed, "Cannot prompt in non-interactive mode.", _logger);
            }

            conn.PlainPassword = AnsiConsole.Prompt(
                new TextPrompt<string>("Password?").Secret());
        }

        _service.AddOrUpdateConnection(conn);
        AnsiConsole.MarkupLine($"[green]Connection '{conn.Name}' updated![/]");
        _logger.LogInformation("Updated connection: {Name}", conn.Name);
        return 0;
    }
}
