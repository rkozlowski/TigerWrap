using ItTiger.TigerCli.Commands;
using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Terminal;
using ItTiger.TigerCli.Tui.Themes;
using ItTiger.TigerWrap.Cli.Commands;
using ItTiger.TigerWrap.Cli.Commands.Db;
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
        return Build(new TigerQueryCliOptions
        {
            DefaultConnectionStoreFile = ToolkitHelper.PrepareDefaultConnectionStoreFile()
        });
    }

    /// <summary>
    /// Builds the app over one shared TigerQuery configuration. The run's connection store is
    /// selected by <see cref="TigerQueryCliContribution"/> (<c>--tq-connection-store-file</c>,
    /// then the TigerQuery environment variable, then the TigerWrap default file) before any
    /// provider or command factory runs, so every store access below is deferred to run time.
    /// </summary>
    internal static TigerCliApp Build(TigerQueryCliOptions tigerQuery)
    {
        ArgumentNullException.ThrowIfNull(tigerQuery);

        TigerConsole.CurrentTheme = new TigerBlueTheme();

        return TigerCliApp.CreateBuilder()
            .UseAssemblyMetadata(typeof(TigerWrapApp).Assembly)
            .AddContribution(new TigerQueryCliContribution(tigerQuery))
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
                    ctx => tigerQuery.Store.GetConnectionNamesAsync(ctx.CancellationToken)))
            .AddCommandGroup("connection", group =>
            {
                group.SetDescription("Manage TigerWrap database connections.");
                SqlServerConnectionCommands.Configure(group, options =>
                {
                    options.TigerQuery = tigerQuery;
                    options.ValidationPolicy = SqlServerConnectionValidationPolicy.DatabaseRequired;
                });
            })
            .AddCommandGroup("db", group =>
            {
                group.SetDescription("Install, inspect and upgrade a TigerWrap database.");
                group.AddCommand(
                    "info",
                    () => new DbInfoCommand(tigerQuery.Store),
                    "Show TigerWrap database version, API level and compatibility.");
                group.AddCommand(
                    "install",
                    () => new DbInstallCommand(tigerQuery.Store),
                    $"Install TigerWrapDb {ExpectedDbInfo.CurrentSchemaVersion} into an existing empty database.");
                group.AddCommand(
                    "upgrade",
                    () => new DbUpgradeCommand(tigerQuery.Store),
                    $"Upgrade a TigerWrap database ({DbCommandSupport.UpgradeSourceVersion} -> {DbCommandSupport.UpgradeTargetVersion}).");
                group.AddCommand(
                    "sqlcmd",
                    () => new DbSqlCmdCommand(tigerQuery.Store),
                    command => command.CommandMenu(CommandMenuMode.Disabled),
                    "Execute a SQL script file against a saved connection (for scripts and automation).");
            })
            .AddCommand(
                "languages-list",
                () => new LanguagesListCommand(tigerQuery.Store),
                command => command.CommandMenu(CommandMenuMode.Disabled),
                "List languages supported by a TigerWrap database.")
            .AddCommand(
                "generate-code",
                () => new GenerateCodeCommand(tigerQuery.Store),
                command => command
                    .SetPromptMode(TigerCliPromptMode.RequiredOnly)
                    .CommandMenu(CommandMenuMode.Disabled),
                "Generate code for a TigerWrap project.")
            .AddCommandGroup("project", group =>
            {
                group.SetDescription("View and manage TigerWrap projects.");
                group.AddAsyncProvider<string>(
                    "projects",
                    ctx => ProjectCommandProviders.GetProjectChoicesAsync(tigerQuery.Store, ctx),
                    configure: options => options.EmptyMessage("No projects were found for the selected connection."));
                group.AddCommand(
                    "list",
                    () => new ProjectsListCommand(tigerQuery.Store),
                    command => command.AddAsyncProvider<ToolkitDbHelper.Language>(
                        "languages",
                        ctx => ProjectCommandProviders.GetLanguageChoicesAsync(tigerQuery.Store, ctx),
                        configure: options => options.EmptyMessage("No languages were found for the selected connection.")),
                    "List projects.");
                group.AddCommand(
                    "show",
                    () => new ProjectsShowCommand(tigerQuery.Store),
                    "Show project details.");
                group.AddCommand(
                    "add",
                    () => new ProjectsAddCommand(tigerQuery.Store),
                    command => command
                        .AddAsyncProvider<ToolkitDbHelper.Language>(
                            "languages",
                            ctx => ProjectCommandProviders.GetLanguageChoicesAsync(tigerQuery.Store, ctx),
                            configure: options => options.EmptyMessage("No languages were found for the selected connection."))
                        .AddAsyncProvider<string>(
                            "databases",
                            ctx => ProjectCommandProviders.GetDatabaseChoicesAsync(tigerQuery.Store, ctx),
                            configure: options => options.EmptyMessage("No databases were found for the selected connection."))
                        .AddAsyncProvider<ProjectsAddCommand.Settings, long>(
                            "language-options",
                            (settings, ctx) => ProjectCommandProviders.GetLanguageOptionChoicesAsync(
                                tigerQuery.Store,
                                settings,
                                ctx)),
                    "Add project.");
                group.AddCommand(
                    "update",
                    () => new ProjectsUpdateCommand(tigerQuery.Store),
                    command => command
                        .AsEdit<ProjectsUpdateCommand.Settings>(
                            settings => ProjectsUpdateCommand.LoadAsync(tigerQuery.Store, settings))
                        .AddAsyncProvider<string>(
                            "databases",
                            ctx => ProjectCommandProviders.GetDatabaseChoicesAsync(tigerQuery.Store, ctx),
                            configure: options => options.EmptyMessage("No databases were found for the selected connection."))
                        .AddAsyncProvider<ProjectsUpdateCommand.Settings, long>(
                            "language-options",
                            (settings, ctx) => ProjectCommandProviders.GetLanguageOptionChoicesAsync(
                                tigerQuery.Store,
                                settings,
                                ctx)),
                    "Update project.");
                group.AddCommandGroup("sp", sp =>
                {
                    sp.SetDescription("Manage project stored procedure mappings.");
                    sp.AddAsyncProvider<ProjectsSpAddCommand.Settings, string>(
                        "schemas",
                        (settings, ctx) => ProjectCommandProviders.GetSchemaChoicesAsync(
                            tigerQuery.Store,
                            settings.ConnectionName,
                            settings.ProjectName,
                            ctx),
                        configure: options => options.EmptyMessage("No schemas were found for the selected project."));
                    sp.AddAsyncProvider<ProjectsSpAddCommand.Settings, long>(
                        "language-options",
                        (settings, ctx) => ProjectCommandProviders.GetStoredProcedureLanguageOptionChoicesAsync(
                            tigerQuery.Store,
                            settings.ConnectionName,
                            settings.ProjectName,
                            ctx));
                    sp.AddAsyncProvider<ProjectsSpRemoveCommand.Settings, int>(
                        "stored-procedure-mappings",
                        (settings, ctx) => ProjectCommandProviders.GetStoredProcedureMappingChoicesAsync(
                            tigerQuery.Store,
                            settings.ConnectionName,
                            settings.ProjectName,
                            ctx),
                        configure: options => options.EmptyMessage("No stored procedure mappings were found for the selected project."));
                    sp.AddCommand(
                        "add",
                        () => new ProjectsSpAddCommand(tigerQuery.Store),
                        "Add stored procedure mapping.");
                    sp.AddCommand(
                        "remove",
                        () => new ProjectsSpRemoveCommand(tigerQuery.Store),
                        "Remove stored procedure mapping.");
                });
                group.AddCommandGroup("enum", enumGroup =>
                {
                    enumGroup.SetDescription("Manage project enum mappings.");
                    enumGroup.AddAsyncProvider<ProjectsEnumAddCommand.Settings, string>(
                        "schemas",
                        (settings, ctx) => ProjectCommandProviders.GetSchemaChoicesAsync(
                            tigerQuery.Store,
                            settings.ConnectionName,
                            settings.ProjectName,
                            ctx),
                        configure: options => options.EmptyMessage("No schemas were found for the selected project."));
                    enumGroup.AddAsyncProvider<ProjectsEnumRemoveCommand.Settings, int>(
                        "enum-mappings",
                        (settings, ctx) => ProjectCommandProviders.GetEnumMappingChoicesAsync(
                            tigerQuery.Store,
                            settings.ConnectionName,
                            settings.ProjectName,
                            ctx),
                        configure: options => options.EmptyMessage("No enum mappings were found for the selected project."));
                    enumGroup.AddCommand(
                        "add",
                        () => new ProjectsEnumAddCommand(tigerQuery.Store),
                        "Add enum mapping.");
                    enumGroup.AddCommand(
                        "remove",
                        () => new ProjectsEnumRemoveCommand(tigerQuery.Store),
                        "Remove enum mapping.");
                });
                group.AddCommandGroup("norm", norm =>
                {
                    norm.SetDescription("Manage project name normalizations.");
                    norm.AddAsyncProvider<ProjectsNormRemoveCommand.Settings, int>(
                        "normalizations",
                        (settings, ctx) => ProjectCommandProviders.GetNameNormalizationChoicesAsync(
                            tigerQuery.Store,
                            settings.ConnectionName,
                            settings.ProjectName,
                            ctx),
                        configure: options => options.EmptyMessage("No name normalizations were found for the selected project."));
                    norm.AddCommand(
                        "add",
                        () => new ProjectsNormAddCommand(tigerQuery.Store),
                        "Add name normalization.");
                    norm.AddCommand(
                        "remove",
                        () => new ProjectsNormRemoveCommand(tigerQuery.Store),
                        "Remove name normalization.");
                });
            })
            .Build();
    }
}
