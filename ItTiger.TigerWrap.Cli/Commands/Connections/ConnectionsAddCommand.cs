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
using System.Threading.Tasks;

namespace ItTiger.TigerWrap.Cli.Commands.Connections;

public class ConnectionsAddCommand(ConnectionService service, ILogger<ConnectionsAddCommand> logger)
    : AsyncCommand<ConnectionsAddCommand.Settings>
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
        [Description("Authentication type: Integrated | SqlPassword")]
        public AuthenticationType Authentication { get; set; } = AuthenticationType.Integrated;

        [CommandOption("--username <USERNAME>")]
        public string Username { get; set; } = string.Empty;

        [CommandOption("--database <DATABASE>")]
        public string Database { get; set; } = string.Empty;

        [CommandOption("--encrypt <ENCRYPT>")]
        [Description("Encryption option: Optional | Mandatory | Strict")]
        public EncryptOption Encrypt { get; set; } = EncryptOption.Optional;

        [CommandOption("--trust-server-cert <YesNo>")]
        [Description("Trust server certificate: Yes | No")]
        public BoolChoice? TrustServerCertificate { get; set; }
    }

    public override async Task<int> ExecuteAsync(CommandContext context, Settings s)
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

        var name = s.Name.Trim();

        var existing = _service.LoadConnections().FirstOrDefault(c => c.Name == name);
        if (existing != null)
        {
            return CliHelper.Fail(ToolkitResponseCode.CliInvalidArguments, $"A connection named '{name}' already exists. Use 'update' instead.", _logger);
        }

        var info = new ConnectionInfo
        {
            Name = name,
            Server = s.Server.Trim(),
            Authentication = s.Authentication,
            Username = s.Username?.Trim() ?? string.Empty,
            Database = s.Database?.Trim() ?? string.Empty,
            Encrypt = s.Encrypt,
            TrustServerCertificate = s.TrustServerCertificate.AsBool()
        };

        if (s.Authentication == AuthenticationType.SqlPassword && string.IsNullOrWhiteSpace(info.PlainPassword))
        {
            if (s.NonInteractive)
            {
                return CliHelper.Fail(ToolkitResponseCode.CliInteractiveNotAllowed, "Password is required in non-interactive mode.", _logger);
            }
            info.PlainPassword = AnsiConsole.Prompt(
                new TextPrompt<string>("Enter [green]SQL password[/]:").Secret());
        }

        if (s.TrustServerCertificate is null && !s.NonInteractive)
        {
            s.TrustServerCertificate = await CliHelper.AskBoolChoiceAsync("Trust [green]server certificate[/]?");
            info.TrustServerCertificate = s.TrustServerCertificate.AsBool();
        }

        if (string.IsNullOrWhiteSpace(info.Database))
        {
            if (s.NonInteractive)
            {
                return CliHelper.Fail(ToolkitResponseCode.CliInteractiveNotAllowed, "Database is required in non-interactive mode.", _logger);
            }
            using var sqlConn = new SqlConnection(info.BuildConnectionString());
            info.Database = await CliHelper.SelectDatabaseAsync(sqlConn, "Select a [green]TigerWrap database[/]:") ?? string.Empty;
        }

        _service.AddOrUpdateConnection(info);
        _logger.LogInformation("Connection added: {Name} ({Server}/{Database})", info.Name, info.Server, info.Database);
        AnsiConsole.MarkupLine($"[green]Connection '{Markup.Escape(info.Name)}' saved.[/]");
        return 0;
    }
}
