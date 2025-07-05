using Spectre.Console.Cli;
using System.ComponentModel;

namespace ItTiger.TigerWrap.Cli.Helpers;

public class GlobalSettings : CommandSettings
{
    [CommandOption("--non-interactive")]
    [Description("Disable prompts; fail or skip when user input is required.")]
    public bool NonInteractive { get; set; } = false;
}
