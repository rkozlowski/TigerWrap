using ItTiger.TigerWrap.Core;
using Microsoft.Extensions.Logging;
using Spectre.Console;
using System.Runtime.InteropServices;
using static ItTiger.TigerWrap.Core.ToolkitDbHelper;

namespace ItTiger.TigerWrap.Cli.Helpers;

public static class CliHelper
{
    public static int Fail(ToolkitResponseCode code, string? message, ILogger logger)
    {
        var codeName = Enum.GetName(typeof(ToolkitResponseCode), code);
        var fullMessage = $"[{(int)code}] {codeName}: {message}";

        logger.LogError("Error: {Message}", fullMessage);
        AnsiConsole.MarkupLine("[red]{0}[/]", fullMessage.EscapeMarkup());

        return (int)code;
    }

    public static int Fail(ToolkitResponseCode code, string? message, Exception ex, ILogger logger)
    {
        var codeName = Enum.GetName(typeof(ToolkitResponseCode), code);
        var fullMessage = $"[{(int)code}] {codeName}: {message}";

        logger.LogError(ex, "Error: {Message}", fullMessage);
        AnsiConsole.MarkupLine("[red]{0}[/]", fullMessage.EscapeMarkup());

        return (int)code;
    }

    public static async Task<long?> SelectLanguageOptionsAsync(
        string prompt,
        ToolkitDbHelper db,
        ToolkitDbHelper.Language? languageId,
        long? optionsValue,
        bool isGlobalSelection)
    {
        var options = await db.GetLanguageOptionsAsync(languageId);

        if (!isGlobalSelection)
        {
            options = [.. options.Where(o => o.IsOverridablePerStoredProc)];
        }

        if (!options.Any())
        {
            AnsiConsole.MarkupLine("[yellow]No language options available.[/]");
            return null;
        }

        var selectedIds = new HashSet<short>();

        if (optionsValue.HasValue && optionsValue.Value != 0)
        {
            foreach (var opt in options)
            {
                if ((optionsValue.Value & opt.Value) == opt.Value)
                {
                    selectedIds.Add(opt.Id);
                }
            }
        }

        var promptMenu = new MultiSelectionPrompt<GetLanguageOptionsResult>()
            .Title(prompt)
            .NotRequired()
            .UseConverter(opt => $"{opt.Name} (0x{opt.Value:X})")
            .AddChoices(options);

        foreach (var opt in options)
        {
            if (selectedIds.Contains(opt.Id))
            {
                promptMenu.Select(opt);
            }
        }

        var selected = AnsiConsole.Prompt(promptMenu);

        long total = 0;
        foreach (var sel in selected)
        {
            total |= sel.Value;
        }

        return total;
    }

    /// <summary>
    /// Resolves the language ID based on the values provided in a LanguageScopedSettings instance.
    /// </summary>
    /// <param name="db">An instance of ToolkitDbHelper.</param>
    /// <param name="settings">The CLI settings containing one of the language specifiers.</param>
    /// <param name="logger">Logger instance for reporting errors.</param>
    /// <returns>The resolved language ID or null if resolution failed.</returns>
    public static async Task<ToolkitDbHelper.Language?> ResolveLanguageAsync(
        ToolkitDbHelper db,
        LanguageScopedSettings settings,
        ILogger logger)
    {
        if (settings.LanguageId.HasValue)
        {
            return (ToolkitDbHelper.Language)(byte)settings.LanguageId.Value;
        }

        if (!string.IsNullOrWhiteSpace(settings.LanguageCode))
        {
            var id = await ToolkitHelper.GetLanguageIdByCodeAsync(db, settings.LanguageCode);
            if (id == null)
            {
                Fail(ToolkitDbHelper.ToolkitResponseCode.CliInvalidArguments, $"Unknown language code: '{settings.LanguageCode}'", logger);
                return null;
            }

            return (ToolkitDbHelper.Language)id.Value;
        }

        if (!string.IsNullOrWhiteSpace(settings.LanguageName))
        {
            var id = await ToolkitHelper.GetLanguageIdByNameAsync(db, settings.LanguageName);
            if (id == null)
            {
                Fail(ToolkitDbHelper.ToolkitResponseCode.CliInvalidArguments, $"Unknown language name: '{settings.LanguageName}'", logger);
                return null;
            }

            return (ToolkitDbHelper.Language)id.Value;
        }

        Fail(ToolkitDbHelper.ToolkitResponseCode.CliInvalidArguments, "No language option provided.", logger);
        return null;
    }

    public static async Task<T?> SelectEnumValueAsync<T>(
            string prompt,
            T? currentValue = null,
            bool allowNull = false)
            where T : struct, Enum
    {
        var enumValues = Enum.GetValues<T>();
        var choices = new List<string>();

        // Add <None> if allowed
        if (allowNull)
            choices.Add("<None>");

        // Add enum values, optionally sorting to bring current value on top
        foreach (var value in enumValues)
        {
            var name = value.ToString();
            if (currentValue.HasValue && EqualityComparer<T>.Default.Equals(currentValue.Value, value))
                choices.Insert(allowNull ? 1 : 0, name); // Move to top after <None> if applicable
            else
                choices.Add(name);
        }

        var selection = new SelectionPrompt<string>()
            .Title(prompt)
            .PageSize(10)
            .AddChoices(choices);

        var selected = await AnsiConsole.PromptAsync(selection);

        if (allowNull && selected == "<None>")
            return null;

        if (Enum.TryParse<T>(selected, out var result))
            return result;

        throw new InvalidOperationException($"Unable to parse selected enum value: '{selected}'");
    }

    public static async Task<string> SelectSchemaAsync(
    ToolkitDbHelper db,
    short projectId,
    string prompt)
    {
        var all = await db.GetProjectDbSchemasAsync(projectId);
        if (all.Count == 0)
            throw new CliException(ToolkitResponseCode.CliNoItemsAvailable, "No schemas available for selection.");

        var choices = all.Select(x => new SelectionItem<string>(x.Name, Markup.Escape(x.Name))).ToList();

        return AnsiConsole.Prompt(
            new SelectionPrompt<SelectionItem<string>>()
                .Title(prompt)
                .AddChoices(choices)
        ).Value;
    }

}
