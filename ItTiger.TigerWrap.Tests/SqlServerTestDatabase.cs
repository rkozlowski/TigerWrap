using System.Text.RegularExpressions;
using ItTiger.TigerQuery;
using ItTiger.TigerQuery.Engine;
using ItTiger.TigerQuery.Core;
using ItTiger.TigerWrap.Core;
using Microsoft.Data.SqlClient;

namespace ItTiger.TigerWrap.Tests;

/// <summary>
/// A disposable SQL Server database for tests that need a real server
/// (server '.', integrated security).
/// <para>
/// Every database created here is named <c>TWE2E_{timestamp}_{8-hex}</c>. The fixed prefix is
/// what makes the drop safe: <see cref="DisposeAsync"/> refuses to drop anything else, and the
/// orphan sweep can recognise leaked databases from an earlier, killed run.
/// </para>
/// <para>
/// Cleanup never throws. A leaked database is a nuisance the sweep handles; an exception from a
/// <c>finally</c> path would replace the failure the test was actually reporting.
/// </para>
/// </summary>
public sealed class SqlServerTestDatabase : IAsyncDisposable
{
    /// <summary>Prefix every disposable test database name carries. Never change it casually.</summary>
    public const string NamePrefix = "TWE2E_";

    /// <summary>Leaked databases older than this are swept by <see cref="SweepOrphansAsync"/>.</summary>
    private static readonly TimeSpan OrphanAge = TimeSpan.FromHours(6);

    public const string MasterConnectionString =
        "Data Source=.;Initial Catalog=master;Integrated Security=True;Encrypt=False;Connect Timeout=5";

    private SqlServerTestDatabase(string name)
    {
        Name = name;
    }

    public string Name { get; }

    public string ConnectionString => BuildConnectionString(Name);

    /// <summary>Cleanup failure, if any. Reported by the test rather than thrown from disposal.</summary>
    public Exception? CleanupError { get; private set; }

    public static string RepoRoot =>
        Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", ".."));

    public static string DeploymentScriptsFolder =>
        Path.Combine(RepoRoot, "TigerWrapDb", "DeploymentScripts");

    public static string BuildConnectionString(string databaseName) =>
        $"Data Source=.;Initial Catalog={databaseName};Integrated Security=True;Encrypt=False";

    /// <summary>Skips the calling test when no local SQL Server is reachable.</summary>
    public static async Task SkipUnlessAvailableAsync()
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

    /// <summary>Creates a uniquely named, empty disposable database.</summary>
    public static async Task<SqlServerTestDatabase> CreateAsync()
    {
        var name = NamePrefix
            + DateTime.UtcNow.ToString("yyyyMMddHHmmss")
            + "_"
            + Guid.NewGuid().ToString("N")[..8];
        await ExecuteOnMasterAsync(
            "DECLARE @sql NVARCHAR (MAX) = N'CREATE DATABASE ' + QUOTENAME(@name); EXEC sp_executesql @sql;",
            name);
        return new SqlServerTestDatabase(name);
    }

    /// <summary>Runs non-query SQL against this database. Batches may be separated by <c>GO</c>.</summary>
    public async Task ExecuteAsync(string sql)
    {
        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync();

        foreach (var batch in SplitBatches(sql))
        {
            await using var command = connection.CreateCommand();
            command.CommandText = batch;
            await command.ExecuteNonQueryAsync();
        }
    }

    public async Task<T?> ScalarAsync<T>(string sql)
    {
        await using var connection = new SqlConnection(ConnectionString);
        await connection.OpenAsync();
        await using var command = connection.CreateCommand();
        command.CommandText = sql;
        var value = await command.ExecuteScalarAsync();
        return value is null or DBNull ? default : (T)value;
    }

    public Task<int> CountTigerWrapSchemasAsync() =>
        ScalarAsync<int>(
            "SELECT COUNT(*) FROM sys.schemas WHERE [name] IN "
            + "(N'DbInfo', N'Enum', N'Flag', N'History', N'Internal', N'Parser', N'ParserEnum', "
            + "N'Project', N'Static', N'Toolkit', N'View');");

    public Task<int> CountUserObjectsAsync() =>
        ScalarAsync<int>("SELECT COUNT(*) FROM sys.objects WHERE [is_ms_shipped] = 0 AND [parent_object_id] = 0;");

    public Task SetCompatibilityLevelAsync(int level) =>
        ExecuteOnMasterAsync(
            $"DECLARE @sql NVARCHAR (MAX) = N'ALTER DATABASE ' + QUOTENAME(@name) + N' SET COMPATIBILITY_LEVEL = {level}'; EXEC sp_executesql @sql;",
            Name);

    /// <summary>
    /// Runs a packaged deployment script against this database through TigerQuery, exactly as
    /// <c>db install</c> and <c>db upgrade</c> do, and returns everything the script printed.
    /// </summary>
    public async Task<(ExecutionResult Result, IReadOnlyList<string> Messages, int Errors)> RunDeploymentScriptAsync(
        string scriptFileName)
    {
        var scriptPath = Path.Combine(DeploymentScriptsFolder, scriptFileName);
        Assert.True(File.Exists(scriptPath), $"Deployment script not found: {scriptPath}");

        var messages = new List<string>();
        var errors = 0;

        var engine = new TigerQueryEngine(new TigerQueryEngineOptions
        {
            ConnectionString = ConnectionString,
            ExecutionMode = TigerQueryExecutionMode.Prepared,
            Mode = SqlCmdMode.SqlCmdEx,
            ContinueOnError = false,
            Variables = new Dictionary<string, string> { ["DatabaseName"] = Name },
            OnMessage = (message, _) =>
            {
                messages.Add(message.Text?.Trim() ?? string.Empty);
                if (message.IsError)
                {
                    Interlocked.Increment(ref errors);
                }
            }
        });

        var result = await engine.RunFromFileAsync(scriptPath);
        return (result, messages, errors);
    }

    /// <summary>Runs a packaged deployment script and asserts it succeeded without errors.</summary>
    public async Task DeployAsync(string scriptFileName)
    {
        var (result, _, errors) = await RunDeploymentScriptAsync(scriptFileName);
        Assert.Equal(ExecutionResultCode.Success, result.ResultCode);
        Assert.Equal(0, result.FailedBatches);
        Assert.Equal(0, errors);
    }

    public async Task<(string DbName, string Version, byte? ApiLevel, byte? MinApiLevel)> GetDbInfoAsync()
    {
        var db = new ToolkitDbHelper(ConnectionString);
        var (_, dbName, version, apiLevel, minApiLevel) = await db.GetDbInfoAsync();
        return (dbName, version, apiLevel, minApiLevel);
    }

    /// <summary>Creates a throwaway connection store holding one connection to this database.</summary>
    public SqlServerConnectionStore CreateConnectionStore(string connectionName) =>
        CreateConnectionStore(connectionName, Name);

    public static SqlServerConnectionStore CreateConnectionStore(string connectionName, string databaseName)
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

    /// <summary>
    /// Drops databases left behind by a killed run. Only touches <see cref="NamePrefix"/> databases
    /// older than <see cref="OrphanAge"/>, so a concurrently running suite is never disturbed.
    /// </summary>
    public static async Task SweepOrphansAsync()
    {
        try
        {
            await using var connection = new SqlConnection(MasterConnectionString);
            await connection.OpenAsync();

            var names = new List<string>();
            await using (var query = connection.CreateCommand())
            {
                query.CommandText =
                    "SELECT [name] FROM sys.databases "
                    + "WHERE [name] LIKE @prefix + N'%' AND [create_date] < DATEADD(HOUR, -@hours, SYSUTCDATETIME());";
                query.Parameters.AddWithValue("@prefix", NamePrefix);
                query.Parameters.AddWithValue("@hours", (int)OrphanAge.TotalHours);
                await using var reader = await query.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    names.Add(reader.GetString(0));
                }
            }

            foreach (var name in names)
            {
                await DropAsync(name);
            }
        }
        catch
        {
            // Sweeping is best effort and must never fail a test run.
        }
    }

    public async ValueTask DisposeAsync()
    {
        try
        {
            await DropAsync(Name);
        }
        catch (Exception ex)
        {
            // Never throw from cleanup: it would replace the failure the test is reporting.
            CleanupError = ex;
        }
    }

    private static async Task DropAsync(string databaseName)
    {
        if (!databaseName.StartsWith(NamePrefix, StringComparison.Ordinal))
        {
            throw new InvalidOperationException(
                $"Refusing to drop '{databaseName}': test databases must be named '{NamePrefix}*'.");
        }

        SqlConnection.ClearAllPools();
        await ExecuteOnMasterAsync(
            """
            IF DB_ID(@name) IS NOT NULL
            BEGIN
                DECLARE @sql NVARCHAR (MAX) =
                    N'ALTER DATABASE ' + QUOTENAME(@name) + N' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;'
                    + N'DROP DATABASE ' + QUOTENAME(@name) + N';';
                EXEC sp_executesql @sql;
            END
            """,
            databaseName);
    }

    private static async Task ExecuteOnMasterAsync(string sql, string databaseName)
    {
        await using var connection = new SqlConnection(MasterConnectionString);
        await connection.OpenAsync();
        await using var command = connection.CreateCommand();
        command.CommandText = sql;
        command.Parameters.AddWithValue("@name", databaseName);
        await command.ExecuteNonQueryAsync();
    }

    private static IEnumerable<string> SplitBatches(string sql) =>
        Regex.Split(sql, @"^\s*GO\s*$", RegexOptions.Multiline | RegexOptions.IgnoreCase)
            .Select(batch => batch.Trim())
            .Where(batch => batch.Length > 0);
}
