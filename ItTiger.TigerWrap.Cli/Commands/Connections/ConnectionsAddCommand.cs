using Spectre.Console;
using Spectre.Console.Cli;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerWrap.Core.Models;
using ItTiger.TigerWrap.Core.Services;
using ItTiger.TigerWrap.Cli.Helpers;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using System.ComponentModel;
using static ItTiger.TigerWrap.Core.ToolkitDbHelper;

namespace ItTiger.TigerWrap.Cli.Commands.Connections;

public class ConnectionsAddCommand(ConnectionService service, ILogger<ConnectionsAddCommand> logger)
    : Command<ConnectionsAddCommand.Settings>
{
    private readonly ConnectionService _service = service;
    private readonly ILogger _logger = logger;

    public sealed class Settings : GlobalSettings
    {
        [CommandOption("--name <NAME>")]
        public string Name { get; set; } = string.Empty;

        [CommandOption("--server <SERVER>")]
        public string Server { get; set; } = string.Empty;

        [CommandOption("--auth <AUTH>")]
        [Description("Authentication type: Integrated | SqlPassword | Entra")]
        public AuthenticationType Authentication { get; set; }

        [CommandOption("--username <USERNAME>")]
        public string Username { get; set; } = string.Empty;

        [CommandOption("--database <DATABASE>")]
        public string Database { get; set; } = string.Empty;

        [CommandOption("--encrypt <ENCRYPT>")]
        [Description("Encryption option: Optional | Mandatory | Strict")]
        public EncryptOption Encrypt { get; set; } = EncryptOption.Optional;

        [CommandOption("--trust-server-cert")]
        public bool TrustServerCertificate { get; set; } = false;
    }

    public override int Execute(CommandContext context, Settings s)
    {
        if (string.IsNullOrWhiteSpace(s.Name))
        {
            return CliHelper.Fail(ToolkitResponseCode.CliInvalidArguments, "Connection name is required.", _logger);
        }
        if (string.IsNullOrWhiteSpace(s.Server))
        {
            return CliHelper.Fail(ToolkitResponseCode.CliInvalidArguments, "Server name is required.", _logger);
        }
        if (s.Authentication == AuthenticationType.SqlPassword && string.IsNullOrWhiteSpace(s.Username))
        {
            return CliHelper.Fail(ToolkitResponseCode.CliInvalidArguments, "Username is required for SQL authentication.", _logger);
        }

        var existing = _service.LoadConnections().FirstOrDefault(c => c.Name == s.Name);
        if (existing != null)
        {
            return CliHelper.Fail(ToolkitResponseCode.CliInvalidArguments, $"A connection named '{s.Name}' already exists. Use 'update' instead.", _logger);
        }

        var info = new ConnectionInfo
        {
            Name = s.Name.Trim(),
            Server = s.Server.Trim(),
            Authentication = s.Authentication,
            Username = s.Username?.Trim() ?? string.Empty,
            Database = s.Database?.Trim() ?? string.Empty,
            Encrypt = s.Encrypt,
            TrustServerCertificate = s.TrustServerCertificate
        };

        if (s.Authentication == AuthenticationType.SqlPassword && string.IsNullOrWhiteSpace(info.PlainPassword))
        {
            if (s.NonInteractive)
            {
                return CliHelper.Fail(ToolkitResponseCode.CliInteractiveNotAllowed, "Password is required in non-interactive mode.", _logger);
            }
            info.PlainPassword = AnsiConsole.Prompt(
                new TextPrompt<string>("Password?").Secret());
        }

        if (string.IsNullOrWhiteSpace(info.Database))
        {
            if (s.NonInteractive)
            {
                return CliHelper.Fail(ToolkitResponseCode.CliInteractiveNotAllowed, "Database is required in non-interactive mode.", _logger);
            }

            try
            {
                using var sql = new SqlConnection(info.BuildConnectionString());
                sql.Open();
                using var cmd = sql.CreateCommand();
                cmd.CommandText = "SELECT [name] FROM sys.databases WHERE database_id > 4 ORDER BY [name]";
                using var reader = cmd.ExecuteReader();
                var dbs = new List<string>();
                while (reader.Read()) dbs.Add(reader.GetString(0));

                info.Database = AnsiConsole.Prompt(
                    new SelectionPrompt<string>()
                        .Title("Select a [green]user database[/]:")
                        .AddChoices(dbs));
            }
            catch (Exception ex)
            {
                return CliHelper.Fail(ToolkitResponseCode.CliFileWriteError, $"Could not connect to retrieve databases: {ex.Message}", _logger);
            }
        }

        _service.AddOrUpdateConnection(info);
        _logger.LogInformation("Connection added: {Name}", info.Name);
        AnsiConsole.MarkupLine($"[green]Connection '{info.Name}' saved.[/]");
        return 0;
    }
}
