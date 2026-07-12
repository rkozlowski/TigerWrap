namespace ItTiger.TigerWrap.Cli.Commands;

internal static class OptionValues
{
    /// <summary>
    /// Optional prompts answered with Enter bind as an empty string; the toolkit
    /// stored procedures expect NULL when a value was not provided.
    /// </summary>
    public static string? NullIfEmpty(string? value)
        => string.IsNullOrWhiteSpace(value) ? null : value;
}
