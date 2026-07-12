using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Primitives;
using ItTiger.TigerCli.Rendering;
using ItTiger.TigerCli.Terminal;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerQuery.Core;

namespace ItTiger.TigerWrap.Cli.Commands.ReadOnly;

public sealed class LanguagesListSettings : TigerCliSettings
{
    [TigerCliArgument(0,
        Name = "connection",
        Description = "Saved TigerWrap database connection.",
        Provider = "connections",
        Promptable = TigerCliPromptable.Normal,
        AutoSelectSingleChoice = true)]
    public string ConnectionName { get; set; } = string.Empty;
}

public sealed class LanguagesListCommand(SqlServerConnectionStore connectionStore)
    : TigerCliAsyncCommandHandler<LanguagesListSettings>
{
    public override async Task<int> ExecuteAsync(LanguagesListSettings settings)
    {
        var (db, error) = await ToolkitHelper.TryResolveDbHelperAsync(
            connectionStore,
            settings.ConnectionName);
        if (db is null)
        {
            TigerConsole.MarkupErrorLine(settings.E("{0}", error));
            return (int)ToolkitDbHelper.ToolkitResponseCode.CliMissingConnection;
        }

        try
        {
            var languages = await db.GetLanguagesAsync();

            var table = new CliTable()
                .ApplyPreset(CliTableStylePreset.Milano)
                .AddTitle(settings.T("Available languages"))
                .AddHeader(
                    settings.T("Id"),
                    settings.T("Name"),
                    settings.T("Code"));

            foreach (var language in languages)
            {
                table.AddRecord(
                    (int)language.Id,
                    language.Name,
                    language.Code);
            }

            TigerConsole.Render(table);
            return (int)ToolkitDbHelper.ToolkitResponseCode.Ok;
        }
        catch (Exception ex)
        {
            TigerConsole.MarkupErrorLine(settings.E(
                "Unexpected error while listing languages: {0}",
                ex.Message));
            return (int)ToolkitDbHelper.ToolkitResponseCode.CliUnhandledException;
        }
    }
}
