using ItTiger.TigerCli.Testing;
using ToolkitResponseCode = ItTiger.TigerWrap.Core.ToolkitDbHelper.ToolkitResponseCode;

namespace ItTiger.TigerWrap.Tests;

/// <summary>
/// End-to-end tests for <c>db sqlcmd</c> against a local SQL Server (server '.', integrated
/// security): scripts run through the <c>tiger-wrap</c> app host and TigerQuery in-process, against
/// a saved connection from the run's selected store. Each test provisions and drops its own
/// disposable database via <see cref="SqlServerTestDatabase"/> and is skipped when no local server
/// is available.
/// </summary>
[Collection("TigerCli app tests")]
[Trait("Category", "RequiresSqlServer")]
public sealed class DbSqlCmdLiveTests
{
    private const string MarkerRowsQuery =
        "SELECT STRING_AGG(CAST([Step] AS NVARCHAR (10)), N',') WITHIN GROUP (ORDER BY [Step]) FROM [dbo].[Marker];";

    private const string MarkerTableCountQuery =
        "SELECT COUNT(*) FROM sys.tables WHERE [name] = N'Marker';";

    [Fact]
    public async Task DbSqlCmd_ExecutesScriptFile_AgainstManagedConnectionFromDefaultStore()
    {
        await SqlServerTestDatabase.SkipUnlessAvailableAsync();
        await using var database = await SqlServerTestDatabase.CreateAsync();

        var app = TestApps.Build(database.CreateConnectionStore("target"));
        var script = WriteScript(
            """
            :setvar LastStep 3
            CREATE TABLE [dbo].[Marker] ([Step] INT NOT NULL PRIMARY KEY);
            GO
            INSERT INTO [dbo].[Marker] ([Step]) VALUES (1), (2);
            GO
            INSERT INTO [dbo].[Marker] ([Step]) VALUES ($(LastStep));
            PRINT N'population done';
            GO
            """);

        var result = await TigerCliAppTestHost
            .For(app)
            .WithArgs("db", "sqlcmd", "target", "--file", script, "--mode", "SqlCmdEx", "--non-interactive")
            .RunAsync(CancellationToken.None);

        Assert.True(result.ExitCode == 0, $"Exit code {result.ExitCode}. StdErr: {result.StdErr}");
        Assert.Contains("Script prepared: 3 batch(es)", result.StdOut);
        Assert.Contains("population done", result.StdOut);
        Assert.Contains("Script completed successfully", result.StdOut);
        Assert.Equal("1,2,3", await database.ScalarAsync<string>(MarkerRowsQuery));
    }

    [Fact]
    public async Task DbSqlCmd_UsesExplicitlySelectedStore_InsteadOfTheDefaultStore()
    {
        await SqlServerTestDatabase.SkipUnlessAvailableAsync();
        await using var database = await SqlServerTestDatabase.CreateAsync();

        // The default store's "target" points at a database that does not exist, so running
        // against it would fail; the explicit store's "target" is the disposable database.
        var defaultStore = SqlServerTestDatabase.CreateConnectionStore(
            "target",
            SqlServerTestDatabase.NamePrefix + "missing_" + Guid.NewGuid().ToString("N"));
        var explicitStore = database.CreateConnectionStore("target");
        var app = TestApps.Build(defaultStore);
        var script = WriteScript("CREATE TABLE [dbo].[Marker] ([Step] INT NOT NULL);\nGO\n");

        var result = await TigerCliAppTestHost
            .For(app)
            .WithArgs(
                "db", "sqlcmd", "target",
                "--file", script,
                "--tq-connection-store-file", explicitStore.FilePath,
                "--non-interactive")
            .RunAsync(CancellationToken.None);

        Assert.True(result.ExitCode == 0, $"Exit code {result.ExitCode}. StdErr: {result.StdErr}");
        Assert.Equal(1, await database.ScalarAsync<int>(MarkerTableCountQuery));
    }

    [Fact]
    public async Task DbSqlCmd_ExplicitStoreWithoutTheConnection_FailsWithoutFallingBackToTheDefaultStore()
    {
        await SqlServerTestDatabase.SkipUnlessAvailableAsync();
        await using var database = await SqlServerTestDatabase.CreateAsync();

        // Only the default store knows "target"; the explicitly selected store does not.
        var app = TestApps.Build(database.CreateConnectionStore("target"));
        var explicitStore = database.CreateConnectionStore("other");
        var script = WriteScript("CREATE TABLE [dbo].[Marker] ([Step] INT NOT NULL);\nGO\n");

        var result = await TigerCliAppTestHost
            .For(app)
            .WithArgs(
                "db", "sqlcmd", "target",
                "--file", script,
                "--tq-connection-store-file", explicitStore.FilePath,
                "--non-interactive")
            .RunAsync(CancellationToken.None);

        Assert.Equal((int)ToolkitResponseCode.TigerCliValidationError, result.ExitCode);
        Assert.Equal(0, await database.ScalarAsync<int>(MarkerTableCountQuery));
    }

    [Fact]
    public async Task DbSqlCmd_FailedBatch_FailsTheCommand_WhileTigerQueryContinuesByDefault()
    {
        await SqlServerTestDatabase.SkipUnlessAvailableAsync();
        await using var database = await SqlServerTestDatabase.CreateAsync();

        var app = TestApps.Build(database.CreateConnectionStore("target"));
        var script = WriteScript(
            """
            CREATE TABLE [dbo].[Marker] ([Step] INT NOT NULL);
            INSERT INTO [dbo].[Marker] ([Step]) VALUES (1);
            GO
            INSERT INTO [dbo].[DoesNotExist] ([Step]) VALUES (2);
            GO
            INSERT INTO [dbo].[Marker] ([Step]) VALUES (3);
            GO
            """);

        var result = await TigerCliAppTestHost
            .For(app)
            .WithArgs("db", "sqlcmd", "target", "--file", script, "--non-interactive")
            .RunAsync(CancellationToken.None);

        Assert.Equal((int)ToolkitResponseCode.DbError, result.ExitCode);
        Assert.Contains("DoesNotExist", result.StdErr);
        Assert.Contains("Script failed (BatchFailed; 1 failed batch(es)", result.StdErr);
        // Without :on error exit TigerQuery keeps the sqlcmd default and runs the later batch.
        Assert.Equal("1,3", await database.ScalarAsync<string>(MarkerRowsQuery));
    }

    [Theory]
    [InlineData("SqlCmd")]
    [InlineData("SqlCmdEx")]
    public async Task DbSqlCmd_OnErrorExit_StopsLaterBatchesAndFailsTheCommand(string mode)
    {
        await SqlServerTestDatabase.SkipUnlessAvailableAsync();
        await using var database = await SqlServerTestDatabase.CreateAsync();

        var app = TestApps.Build(database.CreateConnectionStore("target"));
        var script = WriteScript(
            """
            :on error exit
            CREATE TABLE [dbo].[Marker] ([Step] INT NOT NULL);
            INSERT INTO [dbo].[Marker] ([Step]) VALUES (1);
            GO
            RAISERROR (N'db sqlcmd stop marker', 16, 1);
            GO
            INSERT INTO [dbo].[Marker] ([Step]) VALUES (3);
            GO
            CREATE TABLE [dbo].[NeverCreated] ([Id] INT NOT NULL);
            GO
            """);

        var result = await TigerCliAppTestHost
            .For(app)
            .WithArgs("db", "sqlcmd", "target", "--file", script, "--mode", mode, "--non-interactive")
            .RunAsync(CancellationToken.None);

        Assert.Equal((int)ToolkitResponseCode.DbError, result.ExitCode);
        Assert.Contains("Error (line 1): db sqlcmd stop marker", result.StdErr);
        Assert.Contains("Script failed (", result.StdErr);
        Assert.DoesNotContain("Script completed successfully", result.StdOut);
        Assert.Equal("1", await database.ScalarAsync<string>(MarkerRowsQuery));
        Assert.Equal(
            0,
            await database.ScalarAsync<int>("SELECT COUNT(*) FROM sys.tables WHERE [name] = N'NeverCreated';"));
    }

    private static string WriteScript(string sql)
    {
        var directory = Path.Combine(Path.GetTempPath(), "TigerWrap.Tests", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(directory);
        var path = Path.Combine(directory, "script.sql");
        File.WriteAllText(path, sql);
        return path;
    }
}
