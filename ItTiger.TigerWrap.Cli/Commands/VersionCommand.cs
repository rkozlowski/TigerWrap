using ItTiger.TigerWrap.Core;
using Spectre.Console;
using Spectre.Console.Cli;

public sealed class VersionCommand : Command
{
    public override int Execute(CommandContext context)
    {
        AnsiConsole.MarkupLine($"[blue]{ProjectInfo.Name}[/] version [green]{ProjectInfo.Version}[/]");
        return 0;
    }
}
