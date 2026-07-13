using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Rendering;
using ItTiger.TigerCli.Terminal;
using ItTiger.TigerCli.Tui;
using ItTiger.TigerQuery.Core;
using ItTiger.TigerWrap.Core;
using Microsoft.Data.SqlClient;
using ToolkitResponseCode = ItTiger.TigerWrap.Core.ToolkitDbHelper.ToolkitResponseCode;

namespace ItTiger.TigerWrap.Cli.Commands.Db;

public sealed class DbInfoCommand(SqlServerConnectionStore connectionStore)
    : TigerCliAsyncCommandHandler<DbInfoCommand.Settings>
{
    public sealed class Settings : TigerCliSettings
    {
        [TigerCliArgument(0,
            Name = "connection",
            Description = "Saved TigerWrap database connection.",
            Provider = "connections",
            Promptable = TigerCliPromptable.Normal,
            AutoSelectSingleChoice = true)]
        public string ConnectionName { get; set; } = string.Empty;
    }

    public override async Task<int> ExecuteAsync(Settings s)
    {
        try
        {
            var (connectionString, error) = DbCommandSupport.ResolveConnectionString(connectionStore, s.ConnectionName);
            if (connectionString is null)
            {
                TigerConsole.MarkupErrorLine(s.E("{0}", error));
                return (int)ToolkitResponseCode.CliMissingConnection;
            }

            var builder = new SqlConnectionStringBuilder(connectionString);

            var activityResult = await TigerTui.RunActivityAsync(
                "Database info",
                "Reading database information...",
                (_, ct) => DbCommandSupport.ProbeAsync(connectionString, ct));

            if (!activityResult.IsCompleted)
            {
                return Fail(
                    activityResult.Outcome == ActivityOutcome.Failed
                        ? ToolkitResponseCode.CliUnhandledException
                        : ToolkitResponseCode.TigerCliCancelled,
                    activityResult.Exception?.Message ?? $"Reading database information did not complete: {activityResult.Outcome}.",
                    s);
            }

            var probe = activityResult.Value!;

            RenderConnectionDetails(s, builder, probe.Info);

            if (probe.Error is not null)
            {
                TigerConsole.MarkupErrorLine(s.E("{0}", probe.Error));
                return (int)(probe.IsNotTigerWrapDb
                    ? ToolkitResponseCode.InvalidDatabase
                    : ToolkitResponseCode.DbError);
            }

            RenderStatus(s, DbCommandSupport.Classify(probe.Info!));
            return (int)ToolkitResponseCode.Ok;
        }
        catch (Exception ex)
        {
            return Fail(ToolkitResponseCode.CliUnhandledException, $"DbInfoCommand failed: {ex.Message}", s);
        }
    }

    private void RenderConnectionDetails(Settings s, SqlConnectionStringBuilder builder, TigerWrapDbInfo? info)
    {
        var details = new CliDetails()
            .ApplyPreset(CliTableStylePreset.Lucca)
            .AddTitle(s.E("TigerWrap database info"))
            .AddKey(s.T("Connection:"), s.ConnectionName)
            .Add(s.T("Server:"), builder.DataSource)
            .Add(s.T("Database:"), builder.InitialCatalog);

        if (info is not null)
        {
            details
                .Add(s.T("Database type:"), info.DbName)
                .Add(s.T("Schema version:"), info.Version)
                .Add(s.T("API level:"), info.ApiLevel)
                .Add(s.T("Minimum API level:"), info.MinApiLevel)
                .Add(
                    s.T("Tool supports API levels:"),
                    ExpectedDbInfo.MinApiLevel == ExpectedDbInfo.MaxApiLevel
                        ? ExpectedDbInfo.MaxApiLevel.ToString()
                        : $"{ExpectedDbInfo.MinApiLevel}-{ExpectedDbInfo.MaxApiLevel}");
        }

        TigerConsole.Render(details);
    }

    private static void RenderStatus(Settings s, TigerWrapDbStatus status)
    {
        switch (status)
        {
            case TigerWrapDbStatus.Current:
                TigerConsole.MarkupLine(s.E(
                    "[Success]Status: up to date.[/] This database is compatible with this version of TigerWrap."));
                break;

            case TigerWrapDbStatus.UpgradeAvailable:
                TigerConsole.MarkupLine(s.E(
                    "[Warning]Status: upgrade available ({0} -> {1}).[/]",
                    DbCommandSupport.UpgradeSourceVersion,
                    ExpectedDbInfo.CurrentSchemaVersion));
                TigerConsole.MarkupLine(s.E(
                    "Run [Key]tiger-wrap db upgrade[/] to upgrade this database."));
                break;

            case TigerWrapDbStatus.OlderUnsupported:
                TigerConsole.MarkupLine(s.E(
                    "[Warning]Status: unsupported older version.[/] This tool can only upgrade from version {0}.",
                    DbCommandSupport.UpgradeSourceVersion));
                TigerConsole.MarkupLine(s.E(
                    "Upgrade the database manually using the released upgrade scripts first (see docs/INSTALL.md)."));
                break;

            case TigerWrapDbStatus.NewerThanTool:
                TigerConsole.MarkupLine(s.E(
                    "[Warning]Status: database is newer than this tool.[/] Update TigerWrap to work with this database."));
                break;

            case TigerWrapDbStatus.NotTigerWrapDb:
                TigerConsole.MarkupErrorLine(s.E(
                    "Status: this is not a {0} database.", ExpectedDbInfo.DbName));
                break;
        }
    }

    private static int Fail(ToolkitResponseCode code, string? message, Settings settings)
    {
        if (!string.IsNullOrWhiteSpace(message))
        {
            TigerConsole.MarkupErrorLine(settings.E("{0}", message));
        }

        return (int)code;
    }
}
