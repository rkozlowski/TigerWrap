using ItTiger.TigerCli.Testing;
using ItTiger.TigerWrap.Cli;
using ItTiger.TigerWrap.Core;
using ToolkitResponseCode = ItTiger.TigerWrap.Core.ToolkitDbHelper.ToolkitResponseCode;

namespace ItTiger.TigerWrap.Tests;

/// <summary>
/// End-to-end tests for the db command group against a local SQL Server
/// (server '.', integrated security). Each test provisions and drops its own
/// disposable database via <see cref="SqlServerTestDatabase"/>; the tests are
/// skipped when no local server is available.
/// </summary>
[Collection("TigerCli app tests")]
[Trait("Category", "RequiresSqlServer")]
public sealed class DbCommandsLiveTests
{
    [Fact]
    public async Task DbInfo_AgainstNonTigerWrapDatabase_FailsWithInvalidDatabase()
    {
        await SqlServerTestDatabase.SkipUnlessAvailableAsync();

        var store = SqlServerTestDatabase.CreateConnectionStore("probe", "master");
        var app = TigerWrapApp.Build(store);

        var result = await TigerCliAppTestHost
            .For(app)
            .WithArgs("db", "info", "probe", "--non-interactive")
            .RunAsync(CancellationToken.None);

        Assert.Equal((int)ToolkitResponseCode.InvalidDatabase, result.ExitCode);
        Assert.Contains("not a TigerWrapDb", result.StdErr, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task DbUpgradeJourney_From090_UpgradesTo091()
    {
        await SqlServerTestDatabase.SkipUnlessAvailableAsync();

        // Sweep databases leaked by an earlier killed run before provisioning a new one.
        await SqlServerTestDatabase.SweepOrphansAsync();

        await using var database = await SqlServerTestDatabase.CreateAsync();

        await database.DeployAsync("TigerWrapDb_FullDeploy_v_0.9.0.sql");

        var store = database.CreateConnectionStore("upgrade-test");
        var app = TigerWrapApp.Build(store);

        // db info reports the upgrade opportunity.
        var info = await TigerCliAppTestHost
            .For(app)
            .WithArgs("db", "info", "upgrade-test", "--non-interactive")
            .RunAsync(CancellationToken.None);
        Assert.Equal(0, info.ExitCode);
        Assert.Contains("0.9.0", info.StdOut);
        Assert.Contains("upgrade available", info.StdOut, StringComparison.OrdinalIgnoreCase);

        // Non-interactive upgrade without a backup confirmation is refused.
        var refused = await TigerCliAppTestHost
            .For(app)
            .WithArgs(
                "db", "upgrade", "upgrade-test",
                "--sql-folder", SqlServerTestDatabase.DeploymentScriptsFolder,
                "--non-interactive")
            .RunAsync(CancellationToken.None);
        Assert.Equal((int)ToolkitResponseCode.CliInteractiveNotAllowed, refused.ExitCode);
        Assert.Equal("0.9.0", (await database.GetDbInfoAsync()).Version);

        // Confirmed non-interactive upgrade succeeds and reports prepared-mode progress.
        var upgraded = await TigerCliAppTestHost
            .For(app)
            .WithArgs(
                "db", "upgrade", "upgrade-test",
                "--backup-confirmed",
                "--sql-folder", SqlServerTestDatabase.DeploymentScriptsFolder,
                "--non-interactive")
            .RunAsync(CancellationToken.None);
        Assert.Equal(0, upgraded.ExitCode);
        Assert.Contains("Script prepared:", upgraded.StdOut);
        Assert.Contains("Upgrading database from version 0.9.0 to version 0.9.1", upgraded.StdOut);
        Assert.Contains("Upgrade completed successfully", upgraded.StdOut);

        var dbInfo = await database.GetDbInfoAsync();
        Assert.Equal(ExpectedDbInfo.DbName, dbInfo.DbName);
        Assert.Equal("0.9.1", dbInfo.Version);
        Assert.Equal((byte)2, dbInfo.ApiLevel);
        Assert.Equal((byte)2, dbInfo.MinApiLevel);

        // A second upgrade attempt is a no-op success.
        var again = await TigerCliAppTestHost
            .For(app)
            .WithArgs(
                "db", "upgrade", "upgrade-test",
                "--backup-confirmed",
                "--sql-folder", SqlServerTestDatabase.DeploymentScriptsFolder,
                "--non-interactive")
            .RunAsync(CancellationToken.None);
        Assert.Equal(0, again.ExitCode);
        Assert.Contains("already at version 0.9.1", again.StdOut);
    }

    [Fact]
    public async Task TestDatabaseFixture_RefusesToDropDatabasesItDoesNotOwn()
    {
        // The safety check is what makes the fixture usable against a developer's own server.
        var drop = typeof(SqlServerTestDatabase)
            .GetMethod("DropAsync", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static);
        Assert.NotNull(drop);

        var exception = await Assert.ThrowsAsync<InvalidOperationException>(
            () => (Task)drop.Invoke(null, ["master"])!);

        Assert.Contains("Refusing to drop", exception.Message);
    }
}
