using Spectre.Console;
using Spectre.Console.Cli;
using System.ComponentModel;

namespace ItTiger.TigerWrap.Cli.Helpers;

/// <summary>
/// Base settings class for commands that require a specific language.
/// </summary>
public abstract class LanguageScopedSettings : GlobalSettings
{
    [CommandOption("--language-id")]
    [Description("Specify the language using numeric ID.")]
    public int? LanguageId { get; set; }

    [CommandOption("--language-code")]
    [Description("Specify the language using its code (e.g., CSharp, Python).")]
    public string LanguageCode { get; set; } = string.Empty;

    [CommandOption("--language-name")]
    [Description("Specify the language using its full name (e.g., C#, Python).")]
    public string LanguageName { get; set; } = string.Empty;

    public override ValidationResult Validate()
    {
        var count =
            (LanguageId.HasValue ? 1 : 0) +
            (!string.IsNullOrWhiteSpace(LanguageCode) ? 1 : 0) +
            (!string.IsNullOrWhiteSpace(LanguageName) ? 1 : 0);

        if (count == 0)
        {
            return ValidationResult.Error("One of --language-id, --language-code or --language-name must be specified.");
        }

        if (count > 1)
        {
            return ValidationResult.Error("Specify only one of --language-id, --language-code or --language-name.");
        }

        return base.Validate();
    }
}
