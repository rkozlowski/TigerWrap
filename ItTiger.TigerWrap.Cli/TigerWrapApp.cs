using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Terminal;
using ItTiger.TigerCli.Tui.Themes;
using ItTiger.TigerWrap.Cli.Commands;
using ItTiger.TigerWrap.Cli.Commands.Projects;
using ItTiger.TigerWrap.Cli.Commands.ReadOnly;
using ItTiger.TigerQuery.CliCore;
using ItTiger.TigerQuery.Core;
using ItTiger.TigerWrap.Core;
using ToolkitResponseCode = ItTiger.TigerWrap.Core.ToolkitDbHelper.ToolkitResponseCode;

namespace ItTiger.TigerWrap.Cli;

/// <summary>
/// Composes the future TigerCli application for TigerWrap.
/// </summary>
internal static class TigerWrapApp
{
    public static TigerCliApp Create()
    {
        return Build(ToolkitHelper.CreateDefaultConnectionStore());
    }

    internal static TigerCliApp Build(SqlServerConnectionStore connectionStore)
    {
        TigerConsole.CurrentTheme = new TigerBlueTheme();

        return TigerCliApp.CreateBuilder()            
            .UseAssemblyMetadata(typeof(TigerWrapApp).Assembly)
            .UseExitCodes<ToolkitResponseCode>(
                ToolkitResponseCode.Ok,
                ToolkitResponseCode.TigerCliGenericFail)
            .ExitRange(
                TigerCliExitKind.InvalidArguments,
                TigerCliExitKind.Cancelled,
                ToolkitResponseCode.TigerCliInvalidArguments)
            .SetDefaultPromptMode(TigerCliPromptMode.Yes)
            .UseCommandMenu(CommandMenuMode.Enabled)
            .ConfigureProviders(providers =>
                providers.Add(
                    "connections",
                    ctx => connectionStore.GetConnectionNamesAsync(ctx.CancellationToken)))
            .AddCommandGroup("connections", group =>
            {
                group.SetDescription("Manage TigerWrap database connections.");
                SqlServerConnectionCommands.Configure(group, options =>
                {
                    options.Store = connectionStore;
                    options.ValidationPolicy = SqlServerConnectionValidationPolicy.DatabaseRequired;
                });
            })
            .AddCommand(
                "languages-list",
                () => new LanguagesListCommand(connectionStore),
                command => command.CommandMenu(CommandMenuMode.Disabled),
                "List languages supported by a TigerWrap database.")
            .AddCommand(
                "generate-code",
                () => new GenerateCodeCommand(connectionStore),
                command => command
                    .SetPromptMode(TigerCliPromptMode.RequiredOnly)
                    .CommandMenu(CommandMenuMode.Disabled),
                "Generate code for a TigerWrap project.")
            .AddCommandGroup("projects", group =>
            {
                group.SetDescription("View and manage TigerWrap projects.");
                group.AddAsyncProvider<string>(
                    "projects",
                    ctx => ProjectCommandProviders.GetProjectChoicesAsync(connectionStore, ctx),
                    configure: options => options.EmptyMessage("No projects were found for the selected connection."));
                group.AddCommand(
                    "list",
                    () => new ProjectsListCommand(connectionStore),
                    "List projects.");
                group.AddCommand(
                    "show",
                    () => new ProjectsShowCommand(connectionStore),
                    "Show project details.");
                group.AddCommand(
                    "add",
                    () => new ProjectsAddCommand(connectionStore),
                    command => command
                        .AddAsyncProvider<ToolkitDbHelper.Language>(
                            "languages",
                            ctx => ProjectCommandProviders.GetLanguageChoicesAsync(connectionStore, ctx),
                            configure: options => options.EmptyMessage("No languages were found for the selected connection."))
                        .AddAsyncProvider<string>(
                            "databases",
                            ctx => ProjectCommandProviders.GetDatabaseChoicesAsync(connectionStore, ctx),
                            configure: options => options.EmptyMessage("No databases were found for the selected connection."))
                        .AddAsyncProvider<ProjectsAddCommand.Settings, long>(
                            "language-options",
                            (settings, ctx) => ProjectCommandProviders.GetLanguageOptionChoicesAsync(
                                connectionStore,
                                settings,
                                ctx)),
                    "Add project.");
                group.AddCommand(
                    "update",
                    () => new ProjectsUpdateCommand(connectionStore),
                    command => command
                        .AsEdit<ProjectsUpdateCommand.Settings>(
                            settings => ProjectsUpdateCommand.LoadAsync(connectionStore, settings))
                        .AddAsyncProvider<string>(
                            "databases",
                            ctx => ProjectCommandProviders.GetDatabaseChoicesAsync(connectionStore, ctx),
                            configure: options => options.EmptyMessage("No databases were found for the selected connection."))
                        .AddAsyncProvider<ProjectsUpdateCommand.Settings, long>(
                            "language-options",
                            (settings, ctx) => ProjectCommandProviders.GetLanguageOptionChoicesAsync(
                                connectionStore,
                                settings,
                                ctx)),
                    "Update project.");
                group.AddCommandGroup("sp", sp =>
                {
                    sp.SetDescription("Manage project stored procedure mappings.");
                    sp.AddAsyncProvider<ProjectsSpAddCommand.Settings, string>(
                        "schemas",
                        (settings, ctx) => ProjectCommandProviders.GetSchemaChoicesAsync(
                            connectionStore,
                            settings.ConnectionName,
                            settings.ProjectName,
                            ctx),
                        configure: options => options.EmptyMessage("No schemas were found for the selected project."));
                    sp.AddAsyncProvider<ProjectsSpAddCommand.Settings, long>(
                        "language-options",
                        (settings, ctx) => ProjectCommandProviders.GetStoredProcedureLanguageOptionChoicesAsync(
                            connectionStore,
                            settings.ConnectionName,
                            settings.ProjectName,
                            ctx));
                    sp.AddAsyncProvider<ProjectsSpRemoveCommand.Settings, int>(
                        "stored-procedure-mappings",
                        (settings, ctx) => ProjectCommandProviders.GetStoredProcedureMappingChoicesAsync(
                            connectionStore,
                            settings.ConnectionName,
                            settings.ProjectName,
                            ctx),
                        configure: options => options.EmptyMessage("No stored procedure mappings were found for the selected project."));
                    sp.AddCommand(
                        "add",
                        () => new ProjectsSpAddCommand(connectionStore),
                        "Add stored procedure mapping.");
                    sp.AddCommand(
                        "remove",
                        () => new ProjectsSpRemoveCommand(connectionStore),
                        "Remove stored procedure mapping.");
                });
                group.AddCommandGroup("enum", enumGroup =>
                {
                    enumGroup.SetDescription("Manage project enum mappings.");
                    enumGroup.AddAsyncProvider<ProjectsEnumAddCommand.Settings, string>(
                        "schemas",
                        (settings, ctx) => ProjectCommandProviders.GetSchemaChoicesAsync(
                            connectionStore,
                            settings.ConnectionName,
                            settings.ProjectName,
                            ctx),
                        configure: options => options.EmptyMessage("No schemas were found for the selected project."));
                    enumGroup.AddAsyncProvider<ProjectsEnumRemoveCommand.Settings, int>(
                        "enum-mappings",
                        (settings, ctx) => ProjectCommandProviders.GetEnumMappingChoicesAsync(
                            connectionStore,
                            settings.ConnectionName,
                            settings.ProjectName,
                            ctx),
                        configure: options => options.EmptyMessage("No enum mappings were found for the selected project."));
                    enumGroup.AddCommand(
                        "add",
                        () => new ProjectsEnumAddCommand(connectionStore),
                        "Add enum mapping.");
                    enumGroup.AddCommand(
                        "remove",
                        () => new ProjectsEnumRemoveCommand(connectionStore),
                        "Remove enum mapping.");
                });
                group.AddCommandGroup("norm", norm =>
                {
                    norm.SetDescription("Manage project name normalizations.");
                    norm.AddAsyncProvider<ProjectsNormRemoveCommand.Settings, int>(
                        "normalizations",
                        (settings, ctx) => ProjectCommandProviders.GetNameNormalizationChoicesAsync(
                            connectionStore,
                            settings.ConnectionName,
                            settings.ProjectName,
                            ctx),
                        configure: options => options.EmptyMessage("No name normalizations were found for the selected project."));
                    norm.AddCommand(
                        "add",
                        () => new ProjectsNormAddCommand(connectionStore),
                        "Add name normalization.");
                    norm.AddCommand(
                        "remove",
                        () => new ProjectsNormRemoveCommand(connectionStore),
                        "Remove name normalization.");
                });
            })
            .Build();
    }
}
