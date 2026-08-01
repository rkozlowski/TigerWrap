using System.Text.RegularExpressions;
using ItTiger.TigerCli.Testing;
using ItTiger.TigerWrap.Cli;
using ItTiger.TigerWrap.Cli.Commands.Db;
using ItTiger.TigerWrap.Core;
using ToolkitResponseCode = ItTiger.TigerWrap.Core.ToolkitDbHelper.ToolkitResponseCode;

namespace ItTiger.TigerWrap.Tests;

/// <summary>
/// End-to-end coverage for <c>db install</c> and for the SQL-side guard inside the packaged
/// full-install artifact. Skipped when no local SQL Server is available.
/// </summary>
[Collection("TigerCli app tests")]
[Trait("Category", "RequiresSqlServer")]
public sealed class DbInstallLiveTests
{
    private const string ConnectionName = "install-test";

    private static string FullDeployScript => DbCommandSupport.FullDeployScriptFileName;

    [Fact]
    public async Task DbInstall_IntoEmptyDatabase_InstallsAndVerifiesVersionAndApiLevel()
    {
        await SqlServerTestDatabase.SkipUnlessAvailableAsync();

        await using var database = await SqlServerTestDatabase.CreateAsync();
        var result = await RunInstallAsync(database, "--confirm");

        Assert.Equal(0, result.ExitCode);
        Assert.Contains("Installation completed successfully", result.StdOut);

        // Prepared execution: the batch total is known before execution and reported as N of M.
        Assert.Contains("Script prepared:", result.StdOut);
        Assert.Matches(new Regex(@"Batches executed:\D{0,4}\d+ of \d+"), Flatten(result.StdOut));

        var info = await database.GetDbInfoAsync();
        Assert.Equal(ExpectedDbInfo.DbName, info.DbName);
        Assert.Equal(ExpectedDbInfo.CurrentSchemaVersion, info.Version);
        Assert.Equal(ExpectedDbInfo.MaxApiLevel, info.ApiLevel);
        Assert.Equal(ExpectedDbInfo.MinApiLevel, info.MinApiLevel);

        Assert.Null(database.CleanupError);
    }

    [Fact]
    public async Task DbInstall_NonInteractiveWithoutConfirm_IsRefusedAndInstallsNothing()
    {
        await SqlServerTestDatabase.SkipUnlessAvailableAsync();

        await using var database = await SqlServerTestDatabase.CreateAsync();
        var result = await RunInstallAsync(database);

        Assert.Equal((int)ToolkitResponseCode.CliInteractiveNotAllowed, result.ExitCode);
        Assert.Equal(0, await database.CountTigerWrapSchemasAsync());
        Assert.Equal(0, await database.CountUserObjectsAsync());
    }

    [Fact]
    public async Task DbInstall_IntoDatabaseWithUserTable_IsRefusedBeforeAnyChange()
    {
        await SqlServerTestDatabase.SkipUnlessAvailableAsync();

        await using var database = await SqlServerTestDatabase.CreateAsync();
        await database.ExecuteAsync("CREATE TABLE [dbo].[Customer] ([Id] INT NOT NULL);");

        var result = await RunInstallAsync(database, "--confirm");

        Assert.Equal((int)ToolkitResponseCode.InvalidDatabase, result.ExitCode);

        var output = Flatten(result.StdOut + result.StdErr);
        Assert.Contains("is not empty", output);
        Assert.Contains("[dbo].[Customer]", output);
        Assert.Contains("Table", output);

        // Nothing was installed, and the pre-existing table is untouched.
        Assert.Equal(0, await database.CountTigerWrapSchemasAsync());
        Assert.Equal(1, await database.CountUserObjectsAsync());
    }

    [Fact]
    public async Task DbInstall_IntoDatabaseWithUsersAndRolesOnly_Succeeds()
    {
        await SqlServerTestDatabase.SkipUnlessAvailableAsync();

        await using var database = await SqlServerTestDatabase.CreateAsync();
        await database.ExecuteAsync(
            """
            CREATE USER [TigerWrapTestUser] WITHOUT LOGIN;
            GO
            CREATE ROLE [TigerWrapTestRole];
            GO
            ALTER ROLE [TigerWrapTestRole] ADD MEMBER [TigerWrapTestUser];
            GO
            GRANT SELECT TO [TigerWrapTestRole];
            """);

        var result = await RunInstallAsync(database, "--confirm");

        Assert.Equal(0, result.ExitCode);
        Assert.Contains("Installation completed successfully", result.StdOut);
        Assert.Equal(ExpectedDbInfo.CurrentSchemaVersion, (await database.GetDbInfoAsync()).Version);
    }

    [Fact]
    public async Task DbInstall_IntoExistingTigerWrapDb_IsRefusedAndSuggestsUpgrade()
    {
        await SqlServerTestDatabase.SkipUnlessAvailableAsync();

        await using var database = await SqlServerTestDatabase.CreateAsync();
        Assert.Equal(0, (await RunInstallAsync(database, "--confirm")).ExitCode);

        var second = await RunInstallAsync(database, "--confirm");

        Assert.Equal((int)ToolkitResponseCode.InvalidDatabase, second.ExitCode);
        var output = Flatten(second.StdOut + second.StdErr);
        Assert.Contains("TigerWrap schema", output);
        Assert.Contains("tiger-wrap db upgrade", output);
    }

    [Fact]
    public async Task FullDeployScript_AgainstNonEmptyDatabase_RefusesAndCreatesNoTigerWrapObjects()
    {
        await SqlServerTestDatabase.SkipUnlessAvailableAsync();

        await using var database = await SqlServerTestDatabase.CreateAsync();
        await database.ExecuteAsync(
            """
            CREATE TABLE [dbo].[Orders] ([Id] INT NOT NULL);
            GO
            CREATE TYPE [dbo].[OrderList] AS TABLE ([Id] INT);
            """);

        // Executed directly, exactly as a DBA would run the packaged artifact - no CLI preflight.
        var (_, messages, errors) = await database.RunDeploymentScriptAsync(FullDeployScript);

        var output = Flatten(string.Join("\n", messages));
        Assert.Contains("TigerWrapDb installation refused.", output);
        Assert.Contains("The database is not empty.", output);
        Assert.Contains("[dbo].[Orders]", output);
        Assert.Contains("[dbo].[OrderList]", output);
        Assert.Contains("No TigerWrap objects were created. Installation stopped.", output);

        // The guard raises an error and sets NOEXEC ON, so the script reports errors rather than
        // silently doing nothing.
        Assert.True(errors > 0, "The install guard did not report an error.");

        // Nothing was installed.
        Assert.Equal(0, await database.CountTigerWrapSchemasAsync());

        // The pre-existing table is still the only sys.objects row (a table type is not one).
        Assert.Equal(1, await database.CountUserObjectsAsync());
    }

    [Fact]
    public async Task FullDeployScript_AgainstEmptyDatabase_InstallsSuccessfully()
    {
        await SqlServerTestDatabase.SkipUnlessAvailableAsync();

        await using var database = await SqlServerTestDatabase.CreateAsync();

        await database.DeployAsync(FullDeployScript);

        var info = await database.GetDbInfoAsync();
        Assert.Equal(ExpectedDbInfo.DbName, info.DbName);
        Assert.Equal(ExpectedDbInfo.CurrentSchemaVersion, info.Version);
    }

    [Fact]
    public async Task CliPreflightAndSqlGuard_AgreeOnTheSameDatabase()
    {
        await SqlServerTestDatabase.SkipUnlessAvailableAsync();

        await using var database = await SqlServerTestDatabase.CreateAsync();
        await database.ExecuteAsync(
            """
            CREATE TABLE [dbo].[T1] ([Id] INT NOT NULL CONSTRAINT [PK_T1] PRIMARY KEY);
            GO
            CREATE VIEW [dbo].[V1] AS SELECT [Id] FROM [dbo].[T1];
            GO
            CREATE PROCEDURE [dbo].[P1] AS SELECT 1;
            GO
            CREATE FUNCTION [dbo].[F1] () RETURNS INT AS BEGIN RETURN 1 END;
            GO
            CREATE SEQUENCE [dbo].[S1] AS INT START WITH 1;
            GO
            CREATE SYNONYM [dbo].[Y1] FOR [dbo].[T1];
            GO
            CREATE TYPE [dbo].[Tvp1] AS TABLE ([Id] INT);
            GO
            CREATE TYPE [dbo].[Alias1] FROM NVARCHAR (50);
            GO
            CREATE USER [TigerWrapAgreeUser] WITHOUT LOGIN;
            GO
            CREATE ROLE [TigerWrapAgreeRole];
            """);

        var cli = await DatabaseEmptinessCheck.InspectAsync(
            database.ConnectionString,
            TestContext.Current.CancellationToken);
        var sql = await RunGuardConflictQueryAsync(database);

        // Table, view, procedure, function, sequence, synonym, table type, alias type.
        // The user and the role contribute nothing.
        Assert.False(cli.IsEmpty);
        Assert.Equal(8, cli.ConflictCount);
        Assert.Equal(cli.ConflictCount, sql.Count);
        Assert.Equal(
            sql.OrderBy(name => name, StringComparer.Ordinal),
            cli.SampleConflicts.Select(conflict => conflict.Name).OrderBy(name => name, StringComparer.Ordinal));
    }

    [Fact]
    public async Task DbInstall_BelowMinimumCompatibilityLevel_IsRefused()
    {
        await SqlServerTestDatabase.SkipUnlessAvailableAsync();

        await using var database = await SqlServerTestDatabase.CreateAsync();
        await database.SetCompatibilityLevelAsync(120);

        var result = await RunInstallAsync(database, "--confirm");

        Assert.Equal((int)ToolkitResponseCode.InvalidDatabase, result.ExitCode);
        var output = Flatten(result.StdOut + result.StdErr);
        Assert.Contains("compatibility level 120", output);
        Assert.Contains("SET COMPATIBILITY_LEVEL = 130", output);
        Assert.Equal(0, await database.CountTigerWrapSchemasAsync());
    }

    /// <summary>
    /// Executes the conflict query lifted verbatim from the SQL guard, proving the CLI preflight
    /// and the script-side guard classify the same database the same way.
    /// </summary>
    private static async Task<List<string>> RunGuardConflictQueryAsync(SqlServerTestDatabase database)
    {
        var guard = await File.ReadAllTextAsync(
            Path.Combine(SqlServerTestDatabase.RepoRoot, "TigerWrapDb", "Scripts", "Script.PreInstallEmptyCheck.sql"));

        var query = ExtractSharedConflictQuery(guard);
        Assert.Equal(
            Normalise(DatabaseEmptinessCheck.ConflictQuery),
            Normalise(query));

        await using var connection = new Microsoft.Data.SqlClient.SqlConnection(database.ConnectionString);
        await connection.OpenAsync();
        await using var command = connection.CreateCommand();
        command.CommandText = "SET QUOTED_IDENTIFIER ON; " + query + ";";
        await using var reader = await command.ExecuteReaderAsync();

        var names = new List<string>();
        while (await reader.ReadAsync())
        {
            names.Add(reader.GetString(1));
        }

        return names;
    }

    internal static string ExtractSharedConflictQuery(string guardScript)
    {
        var start = guardScript.IndexOf("SELECT CASE o.[type]", StringComparison.Ordinal);
        Assert.True(start >= 0, "The install guard no longer contains the shared conflict query.");

        var end = guardScript.IndexOf("N'Toolkit', N'View')", start, StringComparison.Ordinal);
        Assert.True(end >= 0, "The install guard no longer contains the TigerWrap schema list.");

        return guardScript[start..(end + "N'Toolkit', N'View')".Length)];
    }

    internal static string Normalise(string sql) =>
        Regex.Replace(sql.Replace("\r\n", "\n"), @"\s+", " ").Trim();

    private static string Flatten(string text) => Regex.Replace(text, @"\s+", " ");

    private static async Task<TigerCliAppRunResult> RunInstallAsync(
        SqlServerTestDatabase database,
        params string[] extraArgs)
    {
        var app = TigerWrapApp.Build(database.CreateConnectionStore(ConnectionName));

        string[] args =
        [
            "db", "install", ConnectionName,
            "--sql-folder", SqlServerTestDatabase.DeploymentScriptsFolder,
            .. extraArgs,
            "--non-interactive"
        ];

        return await TigerCliAppTestHost.For(app).WithArgs(args).RunAsync(CancellationToken.None);
    }
}
