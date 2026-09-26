using ItTiger.TigerCli.Commands;
using ItTiger.TigerQuery.CliCore;
using ItTiger.TigerQuery.Core;
using ItTiger.TigerWrap.Cli;

namespace ItTiger.TigerWrap.Tests;

/// <summary>
/// Builds the TigerWrap app over a test connection-store file.
/// </summary>
internal static class TestApps
{
    /// <summary>
    /// Builds the app so that every run selects <paramref name="store"/>'s file as the default
    /// store. The environment reader is empty, so a developer's TigerQuery store variable can
    /// never redirect a test run to another store.
    /// </summary>
    public static TigerCliApp Build(SqlServerConnectionStore store) =>
        TigerWrapApp.Build(new TigerQueryCliOptions
        {
            DefaultConnectionStoreFile = store.FilePath,
            PasswordProtectorFactory = () => new NoOpConnectionPasswordProtector(),
            EnvironmentReader = _ => null
        });
}
