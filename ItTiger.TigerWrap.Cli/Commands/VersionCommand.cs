using ItTiger.TigerWrap.Core;
using Spectre.Console;
using Spectre.Console.Cli;

namespace ItTiger.TigerWrap.Cli.Commands;
public sealed class VersionCommand : Command
{
    public override int Execute(CommandContext context)
    {
        AnsiConsole.MarkupLine($"[blue]{ProjectInfo.Name}[/] version [green]{ProjectInfo.Version}[/]");
        AnsiConsole.MarkupLine("[dim]" + new string('-', 60) + "[/]");
        AnsiConsole.MarkupLine($"[yellow]{ProjectInfo.Copyright}[/]");        
        AnsiConsole.MarkupLine($"[grey]For documentation, visit:  [/] [link={ProjectInfo.WebsiteUrl}]{ProjectInfo.WebsiteUrl}[/]");
        AnsiConsole.MarkupLine($"[grey]For source code and issues:[/] [link={ProjectInfo.GitHubUrl}]{ProjectInfo.GitHubUrl}[/]");
        return 0;
    }
}
