using System.Text.RegularExpressions;
using ItTiger.TigerCli.Commands;
using ItTiger.TigerWrap.Cli.Commands;
using ItTiger.TigerWrap.Cli.Commands.Projects;
using ItTiger.TigerWrap.Core;

namespace ItTiger.TigerWrap.Tests;

public sealed class PromptUxTests
{
    // The tool refused to talk to any deployed TigerWrapDb (and every provider-backed
    // prompt showed an empty list) when ExpectedDbInfo lagged behind the schema's API
    // level. Keep the two in sync by reading the level straight from Script.Version.sql.
    [Fact]
    public void ExpectedDbInfo_SupportsApiLevelDeclaredInSchemaVersionScript()
    {
        var scriptPath = FindRepoFile(Path.Combine("TigerWrapDb", "Scripts", "Script.Version.sql"));
        var script = File.ReadAllText(scriptPath);

        var match = Regex.Match(script, @"@apiLevel\s+SMALLINT\s*=\s*(\d+)", RegexOptions.IgnoreCase);
        Assert.True(match.Success, $"Could not find @apiLevel in {scriptPath}");

        var schemaApiLevel = byte.Parse(match.Groups[1].Value);

        Assert.True(
            ExpectedDbInfo.IsApiLevelSupported(schemaApiLevel),
            $"TigerWrapDb declares API level {schemaApiLevel}, but ExpectedDbInfo supports " +
            $"{ExpectedDbInfo.MinApiLevel}-{ExpectedDbInfo.MaxApiLevel}. " +
            "Update ExpectedDbInfo when the schema API level changes.");
    }

    // Interactive `project sp add` used to be impossible to complete for non-LIKE
    // matches: the esc-char prompt bound Enter as an empty string, which the stored
    // procedure rejects ("Unexpected escape character"). The pattern/esc-char prompts
    // are now gated on the selected match type.
    [Fact]
    public void SpAdd_PatternAndEscChar_PromptOnlyWhenRelevantForMatchType()
    {
        var pattern = GetOption<ProjectsSpAddCommand.Settings>(nameof(ProjectsSpAddCommand.Settings.Pattern));
        var escChar = GetOption<ProjectsSpAddCommand.Settings>(nameof(ProjectsSpAddCommand.Settings.EscChar));

        Assert.Equal("--match", pattern.PromptWhenOption);
        Assert.Equal(["Any"], pattern.PromptWhenValueNotIn);
        Assert.Equal("--match", pattern.RequiredWhenOption);
        Assert.Equal(["Any"], pattern.RequiredWhenValueNotIn);

        Assert.Equal("--match", escChar.PromptWhenOption);
        Assert.Equal(nameof(ToolkitDbHelper.NameMatch.Like), escChar.PromptWhenValue);
    }

    [Fact]
    public void EnumAdd_NamePatternAndEscChar_PromptOnlyWhenRelevantForMatchType()
    {
        var pattern = GetOption<ProjectsEnumAddCommand.Settings>(nameof(ProjectsEnumAddCommand.Settings.NamePattern));
        var escChar = GetOption<ProjectsEnumAddCommand.Settings>(nameof(ProjectsEnumAddCommand.Settings.EscChar));

        Assert.Equal("--name-match", pattern.PromptWhenOption);
        Assert.Equal(["Any"], pattern.PromptWhenValueNotIn);
        Assert.Equal("--name-match", pattern.RequiredWhenOption);
        Assert.Equal(["Any"], pattern.RequiredWhenValueNotIn);

        Assert.Equal("--name-match", escChar.PromptWhenOption);
        Assert.Equal(nameof(ToolkitDbHelper.NameMatch.Like), escChar.PromptWhenValue);
    }

    // Optional prompts answered with Enter bind as "", but the toolkit stored
    // procedures treat empty string as a provided value (e.g. NameColumn = '' or
    // EscChar = '' would be stored / rejected). The handlers normalize to NULL.
    [Theory]
    [InlineData(null, null)]
    [InlineData("", null)]
    [InlineData("   ", null)]
    [InlineData("Code", "Code")]
    public void NullIfEmpty_NormalizesUnansweredPromptValues(string? value, string? expected)
    {
        Assert.Equal(expected, OptionValues.NullIfEmpty(value));
    }

    private static TigerCliOptionAttribute GetOption<TSettings>(string propertyName)
    {
        var option = typeof(TSettings)
            .GetProperty(propertyName)
            ?.GetCustomAttributes(typeof(TigerCliOptionAttribute), inherit: false)
            .Cast<TigerCliOptionAttribute>()
            .Single();

        Assert.NotNull(option);
        return option;
    }

    private static string FindRepoFile(string relativePath)
    {
        var directory = new DirectoryInfo(AppContext.BaseDirectory);
        while (directory is not null)
        {
            var candidate = Path.Combine(directory.FullName, relativePath);
            if (File.Exists(candidate))
                return candidate;

            directory = directory.Parent;
        }

        throw new FileNotFoundException($"Could not locate '{relativePath}' above {AppContext.BaseDirectory}.");
    }
}
