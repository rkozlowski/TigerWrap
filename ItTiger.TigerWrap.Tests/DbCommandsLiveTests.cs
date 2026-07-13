using ItTiger.TigerCli.Testing;
using ItTiger.TigerQuery;
using ItTiger.TigerQuery.Engine;
using ItTiger.TigerQuery.Core;
using ItTiger.TigerWrap.Cli;
using ItTiger.TigerWrap.Core;
using Microsoft.Data.SqlClient;
using ToolkitResponseCode = ItTiger.TigerWrap.Core.ToolkitDbHelper.ToolkitResponseCode;

namespace ItTiger.TigerWrap.Tests;

/// <summary>
/// End-to-end tests for the db command group against a local SQL Server
/// (server '.', integrated security). Each test provisions and drops its own
/// disposable database; the tests are skipped when no local server is available.
/// </summary>
[Collection("TigerCli app tests")]
[Trait("Category", "RequiresSqlServer")]
public sealed class DbCommandsLiveTests
{
    private const string MasterConnectionString =
        "Data Source=.;Initial Catalog=master;Integrated Security=True;Encrypt=False;Connect Timeout=5";

    private static string RepoRoot =>
        Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", ".."));

    private static string DeploymentScriptsFolder =>
        Path.Combine(RepoRoot, "TigerWrapDb", "DeploymentScripts");

    [Fact]
    public async Task DbInfo_AgainstNonTigerWrapDatabase_FailsWithInvalidDatabase()
    {
        await SkipUnlessSqlServerAvailableAsync();

        var store = CreateStore("probe", "master");
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
        await SkipUnlessSqlServerAvailableAsync();

        var databaseName = $"TigerWrapDb_UpgradeTest_{Guid.NewGuid():N}";
        await CreateDatabaseAsync(databaseName);
        try
        {
            await DeployAsync(databaseName, "TigerWrapDb_FullDeploy_v_0.9.0.sql");

            var store = CreateStore("upgrade-test", databaseName);
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
                    "--sql-folder", DeploymentScriptsFolder,
                    "--non-interactive")
                .RunAsync(CancellationToken.None);
            Assert.Equal((int)ToolkitResponseCode.CliInteractiveNotAllowed, refused.ExitCode);
            Assert.Equal("0.9.0", (await GetDbInfoAsync(databaseName)).Version);

            // Confirmed non-interactive upgrade succeeds and reports progress.
            var upgraded = await TigerCliAppTestHost
                .For(app)
                .WithArgs(
                    "db", "upgrade", "upgrade-test",
                    "--backup-confirmed",
                    "--sql-folder", DeploymentScriptsFolder,
                    "--non-interactive")
                .RunAsync(CancellationToken.None);
            Assert.Equal(0, upgraded.ExitCode);
            Assert.Contains("Upgrading database from version 0.9.0 to version 0.9.1", upgraded.StdOut);
            Assert.Contains("Upgrade completed successfully", upgraded.StdOut);

            var dbInfo = await GetDbInfoAsync(databaseName);
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
                    "--sql-folder", DeploymentScriptsFolder,
                    "--non-interactive")
                .RunAsync(CancellationToken.None);
            Assert.Equal(0, again.ExitCode);
            Assert.Contains("already at version 0.9.1", again.StdOut);
        }
        finally
        {
            await DropDatabaseAsync(databaseName);
        }
    }

    private static SqlServerConnectionStore CreateStore(string connectionName, string databaseName)
    {
        var directory = Path.Combine(Path.GetTempPath(), "TigerWrap.Tests", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(directory);
        var store = new SqlServerConnectionStore(
            new SqlServerConnectionStoreOptions { FilePath = Path.Combine(directory, "connections.json") },
            new NoOpConnectionPasswordProtector());
        store.Add(new SqlServerConnectionProfile
        {
            Name = connectionName,
            Server = ".",
            Database = databaseName,
            Authentication = AuthenticationType.Integrated,
            Encrypt = EncryptOption.Optional,
            TrustServerCertificate = true
        });
        return store;
    }

    private static async Task SkipUnlessSqlServerAvailableAsync()
    {
        try
        {
            await using var connection = new SqlConnection(MasterConnectionString);
            await connection.OpenAsync();
        }
        catch (Exception ex)
        {
            Assert.Skip($"Local SQL Server is not available: {ex.Message}");
        }
    }

    private static async Task CreateDatabaseAsync(string databaseName)
    {
        await using var connection = new SqlConnection(MasterConnectionString);
        await connection.OpenAsync();
        await using var command = connection.CreateCommand();
        command.CommandText = $"CREATE DATABASE [{databaseName}]";
        await command.ExecuteNonQueryAsync();
    }

    private static async Task DropDatabaseAsync(string databaseName)
    {
        SqlConnection.ClearAllPools();
        await using var connection = new SqlConnection(MasterConnectionString);
        await connection.OpenAsync();
        await using var command = connection.CreateCommand();
        command.CommandText =
            $"IF DB_ID('{databaseName}') IS NOT NULL BEGIN "
            + $"ALTER DATABASE [{databaseName}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; "
            + $"DROP DATABASE [{databaseName}]; END";
        await command.ExecuteNonQueryAsync();
    }

    private static async Task DeployAsync(string databaseName, string scriptFileName)
    {
        var scriptPath = Path.Combine(DeploymentScriptsFolder, scriptFileName);
        Assert.True(File.Exists(scriptPath), $"Deployment script not found: {scriptPath}");

        var engine = new TigerQueryEngine(new TigerQueryEngineOptions
        {
            ConnectionString = BuildConnectionString(databaseName),
            Mode = SqlCmdMode.SqlCmdEx,
            ContinueOnError = false,
            Variables = new Dictionary<string, string> { ["DatabaseName"] = databaseName }
        });

        var result = await engine.RunFromFileAsync(scriptPath);
        Assert.Equal(ExecutionResultCode.Success, result.ResultCode);
        Assert.Equal(0, result.FailedBatches);
    }

    private static string BuildConnectionString(string databaseName) =>
        $"Data Source=.;Initial Catalog={databaseName};Integrated Security=True;Encrypt=False";

    private static async Task<(string DbName, string Version, byte? ApiLevel, byte? MinApiLevel)> GetDbInfoAsync(
        string databaseName)
    {
        var db = new ToolkitDbHelper(BuildConnectionString(databaseName));
        var (_, dbName, version, apiLevel, minApiLevel) = await db.GetDbInfoAsync();
        return (dbName, version, apiLevel, minApiLevel);
    }
}
