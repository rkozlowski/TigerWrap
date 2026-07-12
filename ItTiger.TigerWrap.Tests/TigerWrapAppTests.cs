using System.Collections;
using System.Reflection;
using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Testing;
using ItTiger.TigerQuery.Core;
using ItTiger.TigerWrap.Cli;
using ItTiger.TigerWrap.Cli.Commands;
using ItTiger.TigerWrap.Cli.Commands.Projects;
using ItTiger.TigerWrap.Cli.Commands.ReadOnly;
using ItTiger.TigerWrap.Core;
using ToolkitResponseCode = ItTiger.TigerWrap.Core.ToolkitDbHelper.ToolkitResponseCode;

namespace ItTiger.TigerWrap.Tests;

[Collection("TigerCli app tests")]
public sealed class TigerWrapAppTests
{
    [Fact]
    public async Task RootHelp_IncludesCommandsIncludingGenerateCode()
    {
        var app = TigerWrapApp.Build(CreateStore());

        var result = await TigerCliAppTestHost
            .For(app)
            .WithArgs("--help")
            .RunAsync(CancellationToken.None);

        Assert.Equal(0, result.ExitCode);
        Assert.Contains("connections", result.StdOut);
        Assert.Contains("languages-list", result.StdOut);
        Assert.Contains("generate-code", result.StdOut);
        Assert.Contains("projects", result.StdOut);
    }

    [Theory]
    [InlineData("languages-list", "Saved TigerWrap database connection")]
    [InlineData("projects", "list")]
    [InlineData("projects list", "language-code")]
    [InlineData("projects show", "Project name")]
    [InlineData("projects add", "--language")]
    [InlineData("projects add", "--desc-attr-class")]
    [InlineData("projects update", "--new-name")]
    [InlineData("projects update", "--desc-attr-namespace")]
    [InlineData("projects sp add", "--langopt-reset")]
    [InlineData("projects sp remove", "Stored procedure mapping ID")]
    [InlineData("projects enum add", "--name-match")]
    [InlineData("projects enum add", "--description-column")]
    [InlineData("projects enum add", "--desc-attr-class")]
    [InlineData("projects enum remove", "Enum mapping ID")]
    [InlineData("projects norm add", "--name-part")]
    [InlineData("projects norm remove", "Normalization ID")]
    [InlineData("generate-code", "--output-type")]
    public async Task CommandHelp_IsRegistered(string commandPath, string expectedText)
    {
        var app = TigerWrapApp.Build(CreateStore());

        var result = await TigerCliAppTestHost
            .For(app)
            .WithArgs([.. commandPath.Split(' '), "--help"])
            .RunAsync(CancellationToken.None);

        Assert.Equal(0, result.ExitCode);
        Assert.Contains(expectedText, result.StdOut);
    }

    [Fact]
    public async Task ProjectsHelp_ListsNestedSubResourceGroups()
    {
        var app = TigerWrapApp.Build(CreateStore());

        var result = await TigerCliAppTestHost
            .For(app)
            .WithArgs("projects", "--help")
            .RunAsync(CancellationToken.None);

        Assert.Equal(0, result.ExitCode);
        Assert.Contains("sp", result.StdOut);
        Assert.Contains("Manage project stored procedure mappings", result.StdOut);
        Assert.Contains("enum", result.StdOut);
        Assert.Contains("Manage project enum mappings", result.StdOut);
        Assert.Contains("norm", result.StdOut);
        Assert.Contains("Manage project name normalizations", result.StdOut);
        Assert.DoesNotContain("Add stored procedure mapping.", result.StdOut);
    }

    [Theory]
    [InlineData("projects sp", "Manage project stored procedure mappings")]
    [InlineData("projects enum", "Manage project enum mappings")]
    [InlineData("projects norm", "Manage project name normalizations")]
    public async Task ProjectSubResourceGroupHelp_ListsAddAndRemoveChildren(string commandPath, string expectedDescription)
    {
        var app = TigerWrapApp.Build(CreateStore());

        var result = await TigerCliAppTestHost
            .For(app)
            .WithArgs([.. commandPath.Split(' '), "--help"])
            .RunAsync(CancellationToken.None);

        Assert.Equal(0, result.ExitCode);
        Assert.Contains(expectedDescription, result.StdOut);
        Assert.Contains("add", result.StdOut);
        Assert.Contains("remove", result.StdOut);
    }

    [Fact]
    public void ProjectsShowProjectArgument_UsesProviderBackedSelection()
    {
        var projectArgument = typeof(ProjectsShowSettings)
            .GetProperty(nameof(ProjectsShowSettings.ProjectName))
            ?.GetCustomAttributes(typeof(TigerCliArgumentAttribute), inherit: false)
            .Cast<TigerCliArgumentAttribute>()
            .Single();

        Assert.NotNull(projectArgument);
        Assert.Equal("projects", projectArgument.Provider);
        Assert.True(projectArgument.AutoSelectSingleChoice);
    }

    [Fact]
    public void ProjectsAdd_UsesSingleLanguageSelectorAndProviderBackedDefaults()
    {
        var language = GetOption<ProjectsAddCommand.Settings>(nameof(ProjectsAddCommand.Settings.Language));
        var defaultDatabase = GetOption<ProjectsAddCommand.Settings>(nameof(ProjectsAddCommand.Settings.DefaultDatabase));
        var languageOptions = GetOption<ProjectsAddCommand.Settings>(nameof(ProjectsAddCommand.Settings.LanguageOptions));

        Assert.Equal("--language", language.Aliases.Single());
        Assert.Equal("languages", language.Provider);
        Assert.True(language.Required);
        Assert.True(language.AutoSelectSingleChoice);

        Assert.Equal("databases", defaultDatabase.Provider);
        Assert.True(defaultDatabase.Required);

        Assert.Equal("language-options", languageOptions.Provider);
        Assert.NotNull(GetMultiSelect<ProjectsAddCommand.Settings>(nameof(ProjectsAddCommand.Settings.LanguageOptions)));
    }

    [Fact]
    public void ProjectsUpdate_UsesProjectProviderAndMultiSelectLanguageOptions()
    {
        var project = GetArgument<ProjectsUpdateCommand.Settings>(nameof(ProjectsUpdateCommand.Settings.ProjectName));
        var languageOptions = GetOption<ProjectsUpdateCommand.Settings>(nameof(ProjectsUpdateCommand.Settings.LanguageOptions));

        Assert.Equal("projects", project.Provider);
        Assert.True(project.AutoSelectSingleChoice);
        Assert.Equal("language-options", languageOptions.Provider);
        Assert.NotNull(GetMultiSelect<ProjectsUpdateCommand.Settings>(nameof(ProjectsUpdateCommand.Settings.LanguageOptions)));
    }

    [Fact]
    public void ProjectsSpAdd_UsesProviderBackedSelectorsAndMultiSelectLanguageOptions()
    {
        var connection = GetArgument<ProjectsSpAddCommand.Settings>(nameof(ProjectsSpAddCommand.Settings.ConnectionName));
        var project = GetArgument<ProjectsSpAddCommand.Settings>(nameof(ProjectsSpAddCommand.Settings.ProjectName));
        var schema = GetOption<ProjectsSpAddCommand.Settings>(nameof(ProjectsSpAddCommand.Settings.Schema));
        var reset = GetOption<ProjectsSpAddCommand.Settings>(nameof(ProjectsSpAddCommand.Settings.LanguageOptionsReset));
        var set = GetOption<ProjectsSpAddCommand.Settings>(nameof(ProjectsSpAddCommand.Settings.LanguageOptionsSet));

        Assert.Equal("connections", connection.Provider);
        Assert.True(connection.AutoSelectSingleChoice);
        Assert.Equal("projects", project.Provider);
        Assert.True(project.AutoSelectSingleChoice);
        Assert.Equal("schemas", schema.Provider);
        Assert.True(schema.Required);
        Assert.Equal("language-options", reset.Provider);
        Assert.Equal("language-options", set.Provider);
        Assert.NotNull(GetMultiSelect<ProjectsSpAddCommand.Settings>(nameof(ProjectsSpAddCommand.Settings.LanguageOptionsReset)));
        Assert.NotNull(GetMultiSelect<ProjectsSpAddCommand.Settings>(nameof(ProjectsSpAddCommand.Settings.LanguageOptionsSet)));
    }

    [Fact]
    public void ProjectsEnumAdd_SupportsDescriptionAttributeOptions()
    {
        var description = GetOption<ProjectsEnumAddCommand.Settings>(nameof(ProjectsEnumAddCommand.Settings.Description));
        var descriptionColumn = GetOption<ProjectsEnumAddCommand.Settings>(nameof(ProjectsEnumAddCommand.Settings.DescriptionColumn));
        var attrClass = GetOption<ProjectsEnumAddCommand.Settings>(nameof(ProjectsEnumAddCommand.Settings.DescriptionAttributeClassName));
        var attrNamespace = GetOption<ProjectsEnumAddCommand.Settings>(nameof(ProjectsEnumAddCommand.Settings.DescriptionAttributeNamespaceName));

        Assert.Equal("--description", description.Aliases.Single());
        Assert.Equal("--description-column", descriptionColumn.Aliases.Single());
        Assert.Equal("--desc-attr-class", attrClass.Aliases.Single());
        Assert.Equal("--desc-attr-namespace", attrNamespace.Aliases.Single());
        Assert.False(description.Required);
        Assert.False(descriptionColumn.Required);
        Assert.False(attrClass.Required);
        Assert.False(attrNamespace.Required);
    }

    [Fact]
    public void ProjectsAddAndUpdate_SupportDescriptionAttributeDefaults()
    {
        var addClass = GetOption<ProjectsAddCommand.Settings>(nameof(ProjectsAddCommand.Settings.DescriptionAttributeClassName));
        var addNamespace = GetOption<ProjectsAddCommand.Settings>(nameof(ProjectsAddCommand.Settings.DescriptionAttributeNamespaceName));
        var updateClass = GetOption<ProjectsUpdateCommand.Settings>(nameof(ProjectsUpdateCommand.Settings.DescriptionAttributeClassName));
        var updateNamespace = GetOption<ProjectsUpdateCommand.Settings>(nameof(ProjectsUpdateCommand.Settings.DescriptionAttributeNamespaceName));

        Assert.Equal("--desc-attr-class", addClass.Aliases.Single());
        Assert.Equal("--desc-attr-namespace", addNamespace.Aliases.Single());
        Assert.Equal("--desc-attr-class", updateClass.Aliases.Single());
        Assert.Equal("--desc-attr-namespace", updateNamespace.Aliases.Single());
        Assert.False(addClass.Required);
        Assert.False(addNamespace.Required);
        Assert.False(updateClass.Required);
        Assert.False(updateNamespace.Required);
    }

    [Fact]
    public void ProjectRemoveCommands_UseProviderBackedIdSelectors()
    {
        AssertRemoveIdProvider<ProjectsSpRemoveCommand.Settings>(
            nameof(ProjectsSpRemoveCommand.Settings.SpMappingId),
            "stored-procedure-mappings");
        AssertRemoveIdProvider<ProjectsEnumRemoveCommand.Settings>(
            nameof(ProjectsEnumRemoveCommand.Settings.EnumMappingId),
            "enum-mappings");
        AssertRemoveIdProvider<ProjectsNormRemoveCommand.Settings>(
            nameof(ProjectsNormRemoveCommand.Settings.NormalizationId),
            "normalizations");
    }

    [Fact]
    public void ProjectSubResourceAddCommands_UseProviderBackedProjectAndSchemaSelectorsWhereApplicable()
    {
        var spProject = GetArgument<ProjectsSpAddCommand.Settings>(nameof(ProjectsSpAddCommand.Settings.ProjectName));
        var enumProject = GetArgument<ProjectsEnumAddCommand.Settings>(nameof(ProjectsEnumAddCommand.Settings.ProjectName));
        var normProject = GetArgument<ProjectsNormAddCommand.Settings>(nameof(ProjectsNormAddCommand.Settings.ProjectName));
        var spSchema = GetOption<ProjectsSpAddCommand.Settings>(nameof(ProjectsSpAddCommand.Settings.Schema));
        var enumSchema = GetOption<ProjectsEnumAddCommand.Settings>(nameof(ProjectsEnumAddCommand.Settings.Schema));

        Assert.Equal("projects", spProject.Provider);
        Assert.Equal("projects", enumProject.Provider);
        Assert.Equal("projects", normProject.Provider);
        Assert.Equal("schemas", spSchema.Provider);
        Assert.Equal("schemas", enumSchema.Provider);
        Assert.True(spSchema.Required);
        Assert.True(enumSchema.Required);
    }

    [Fact]
    public void GenerateCode_UsesConservativePromptabilityAndOutputOptions()
    {
        var connection = GetArgument<GenerateCodeCommand.Settings>(nameof(GenerateCodeCommand.Settings.ConnectionName));
        var project = GetArgument<GenerateCodeCommand.Settings>(nameof(GenerateCodeCommand.Settings.ProjectName));
        var outputFile = GetOption<GenerateCodeCommand.Settings>(nameof(GenerateCodeCommand.Settings.OutputFile));
        var outputType = GetOption<GenerateCodeCommand.Settings>(nameof(GenerateCodeCommand.Settings.OutputType));
        var outputFolder = GetOption<GenerateCodeCommand.Settings>(nameof(GenerateCodeCommand.Settings.OutputFolder));
        var overwrite = GetOption<GenerateCodeCommand.Settings>(nameof(GenerateCodeCommand.Settings.Overwrite));

        Assert.Equal("connections", connection.Provider);
        Assert.Equal(TigerCliPromptable.No, connection.Promptable);
        Assert.Equal(TigerCliPromptable.No, project.Promptable);
        Assert.Null(project.Provider);
        Assert.Equal("--output-file", outputFile.Aliases.Single());
        Assert.Equal("--output-type", outputType.Aliases.Single());
        Assert.Equal("--output-folder", outputFolder.Aliases.Single());
        Assert.Equal("--overwrite", overwrite.Aliases.Single());
    }

    [Fact]
    public void GenerateCode_IsExcludedFromCommandMenuAndNotOptionalCommandPrompting()
    {
        var app = TigerWrapApp.Build(CreateStore());
        var generateCode = FindCommandRegistration(app, "generate-code");

        Assert.Equal(CommandMenuMode.Disabled, GetRegistrationProperty<CommandMenuMode>(generateCode, "CommandMenuMode"));
        Assert.Equal(TigerCliPromptMode.RequiredOnly, GetRegistrationProperty<TigerCliPromptMode>(generateCode, "PromptMode"));
    }

    [Fact]
    public void GenerateCode_RejectsOutputFileForSplitOutput()
    {
        var settings = new GenerateCodeCommand.Settings
        {
            OutputFile = "TigerWrap.cs",
            OutputType = OutputType.SplitPerType
        };

        var result = settings.Validate();

        Assert.False(result.IsValid);
        Assert.Contains("--output-file", result.ErrorMessage);
    }

    [Fact]
    public async Task GenerateCode_NonInteractiveMissingArguments_UsesExistingMissingArgumentFailure()
    {
        var app = TigerWrapApp.Build(CreateStore());

        var result = await TigerCliAppTestHost
            .For(app)
            .WithArgs("generate-code", "--non-interactive")
            .RunAsync(CancellationToken.None);

        Assert.Equal((int)ToolkitResponseCode.TigerCliMissingRequiredArgument, result.ExitCode);
    }

    [Fact]
    public async Task UnknownOption_MapsToTigerCliInvalidArguments()
    {
        var app = TigerWrapApp.Build(CreateStore());

        var result = await TigerCliAppTestHost
            .For(app)
            .WithArgs("projects", "list", "dev", "--definitely-not-an-option", "--non-interactive")
            .RunAsync(CancellationToken.None);

        Assert.Equal((int)ToolkitResponseCode.TigerCliInvalidArguments, result.ExitCode);
    }

    [Fact]
    public async Task CommandMenuNonInteractive_MapsToTigerCliInteractiveNotAllowed()
    {
        var app = TigerWrapApp.Build(CreateStore());

        var result = await TigerCliAppTestHost
            .For(app)
            .WithArgs("definitely-not-a-command", "--non-interactive")
            .RunAsync(CancellationToken.None);

        Assert.Equal((int)ToolkitResponseCode.TigerCliInteractiveNotAllowed, result.ExitCode);
    }

    [Fact]
    public async Task ConnectionsHelp_IncludesTigerQueryConnectionCommands()
    {
        var app = TigerWrapApp.Build(CreateStore());

        var result = await TigerCliAppTestHost
            .For(app)
            .WithArgs("connections", "--help")
            .RunAsync(CancellationToken.None);

        Assert.Equal(0, result.ExitCode);
        Assert.Contains("list", result.StdOut);
        Assert.Contains("show", result.StdOut);
        Assert.Contains("add", result.StdOut);
        Assert.Contains("edit", result.StdOut);
        Assert.Contains("delete", result.StdOut);
    }

    [Fact]
    public async Task ConnectionsAdd_UsesConfiguredTigerWrapStore()
    {
        var store = CreateStore();
        var app = TigerWrapApp.Build(store);

        var result = await TigerCliAppTestHost
            .For(app)
            .WithArgs(
                "connections",
                "add",
                "local",
                "--server",
                ".",
                "--database",
                "TigerWrapDb",
                "--authentication",
                "Integrated",
                "--encrypt",
                "Mandatory",
                "--trust-server-certificate",
                "True",
                "--non-interactive")
            .RunAsync(CancellationToken.None);

        Assert.Equal(0, result.ExitCode);
        var profile = store.Find("local");
        Assert.NotNull(profile);
        Assert.Equal("TigerWrapDb", profile.Database);
    }

    [Fact]
    public async Task ConnectionsAdd_RequiresDatabase()
    {
        var store = CreateStore();
        var app = TigerWrapApp.Build(store);

        var result = await TigerCliAppTestHost
            .For(app)
            .WithArgs(
                "connections",
                "add",
                "missing-db",
                "--server",
                ".",
                "--authentication",
                "Integrated",
                "--non-interactive")
            .RunAsync(CancellationToken.None);

        Assert.NotEqual(0, result.ExitCode);
        Assert.Contains("Database is required", result.StdErr);
        Assert.Empty(store.Load());
    }

    private static SqlServerConnectionStore CreateStore()
    {
        return new SqlServerConnectionStore(
            new SqlServerConnectionStoreOptions
            {
                FilePath = Path.Combine(CreateTempDirectory(), "connections.json")
            },
            new NoOpConnectionPasswordProtector());
    }

    private static string CreateTempDirectory()
    {
        var directory = Path.Combine(Path.GetTempPath(), "TigerWrap.Tests", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(directory);
        return directory;
    }

    private static object FindCommandRegistration(TigerCliApp app, params string[] pathTokens)
    {
        var field = typeof(TigerCliApp).GetField("_namedCommands", BindingFlags.Instance | BindingFlags.NonPublic);
        Assert.NotNull(field);

        var commands = Assert.IsAssignableFrom<IEnumerable>(field.GetValue(app)).Cast<object>();
        return commands.Single(command =>
            GetRegistrationProperty<string[]>(command, "PathTokens")
                .SequenceEqual(pathTokens, StringComparer.OrdinalIgnoreCase));
    }

    private static T GetRegistrationProperty<T>(object registration, string propertyName)
    {
        var property = registration
            .GetType()
            .GetProperty(propertyName, BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);

        Assert.NotNull(property);
        return Assert.IsType<T>(property.GetValue(registration));
    }

    private static TigerCliArgumentAttribute GetArgument<TSettings>(string propertyName)
    {
        var argument = typeof(TSettings)
            .GetProperty(propertyName)
            ?.GetCustomAttributes(typeof(TigerCliArgumentAttribute), inherit: false)
            .Cast<TigerCliArgumentAttribute>()
            .Single();

        Assert.NotNull(argument);
        return argument;
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

    private static TigerCliMultiSelectAttribute? GetMultiSelect<TSettings>(string propertyName)
    {
        return typeof(TSettings)
            .GetProperty(propertyName)
            ?.GetCustomAttributes(typeof(TigerCliMultiSelectAttribute), inherit: false)
            .Cast<TigerCliMultiSelectAttribute>()
            .SingleOrDefault();
    }

    private static void AssertRemoveIdProvider<TSettings>(string idPropertyName, string expectedProvider)
    {
        var project = GetArgument<TSettings>("ProjectName");
        var id = GetOption<TSettings>(idPropertyName);

        Assert.Equal("projects", project.Provider);
        Assert.True(project.AutoSelectSingleChoice);
        Assert.True(id.Required);
        Assert.Equal(expectedProvider, id.Provider);
    }
}

[CollectionDefinition("TigerCli app tests")]
public sealed class TigerCliAppTestCollection;
