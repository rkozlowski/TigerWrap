using ItTiger.TigerWrap.Core;
using Spectre.Console;
using Spectre.Console.Cli;
using Spectre.Console.Cli.Help;
using Spectre.Console.Rendering;
using System.Collections.Generic;

namespace ItTiger.TigerWrap.Cli.Helpers;

public sealed class TigerWrapHelpProvider(ICommandAppSettings settings) : HelpProvider(settings)
{
    public override IEnumerable<IRenderable> GetFooter(ICommandModel model, ICommandInfo? command)
    {
        
        yield return new Markup(Environment.NewLine);
        yield return new Markup("[dim]" + new string('-', 60) + "[/]");
        yield return new Markup(Environment.NewLine);
        yield return new Markup($"[yellow]{ProjectInfo.Copyright}[/]");
        yield return new Markup(Environment.NewLine);
        yield return new Markup($"[grey]For documentation, visit:  [/] [link={ProjectInfo.WebsiteUrl}]{ProjectInfo.WebsiteUrl}[/]");
        yield return new Markup(Environment.NewLine);
        yield return new Markup($"[grey]For source code and issues:[/] [link={ProjectInfo.GitHubUrl}]{ProjectInfo.GitHubUrl}[/]");
        
    }
}
