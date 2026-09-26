using System.Reflection;
using ItTiger.TigerCli.Testing;
using ItTiger.TigerQuery;
using ItTiger.TigerQuery.Core;
using ItTiger.TigerQuery.Engine;
using ItTiger.TigerQuery.Events;
using ItTiger.TigerWrap.Cli;
using ItTiger.TigerWrap.Cli.Commands.Db;
using ToolkitResponseCode = ItTiger.TigerWrap.Core.ToolkitDbHelper.ToolkitResponseCode;

namespace ItTiger.TigerWrap.Tests;

/// <summary>
/// <c>db sqlcmd</c> behavior that needs no SQL Server: argument validation, TigerQuery defaults,
/// and the in-process TigerQuery dependency. Registration and menu visibility are covered in
/// <see cref="TigerWrapAppTests"/>; execution against a server in <see cref="DbSqlCmdLiveTests"/>.
/// </summary>
[Collection("TigerCli app tests")]
public sealed class DbSqlCmdCommandTests
{
    [Fact]
    public void DbSqlCmd_DefaultsToTigerQueryExecutionSemantics()
    {
        var settings = new DbSqlCmdCommand.Settings();

        // Mirrors the engine defaults so db sqlcmd does not redefine TigerQuery's semantics.
        Assert.Equal(new TigerQueryEngineOptions().Mode, settings.Mode);
        Assert.Equal(SqlCmdMode.SqlCmd, settings.Mode);
        Assert.Null(settings.CommandTimeout);
    }

    [Fact]
    public async Task DbSqlCmd_NonInteractiveWithoutFile_FailsAsMissingRequiredOption()
    {
        // A known connection, so only the missing --file can fail the run.
        var app = TestApps.Build(SqlServerTestDatabase.CreateConnectionStore("any", "master"));

        var result = await TigerCliAppTestHost
            .For(app)
            .WithArgs("db", "sqlcmd", "any", "--non-interactive")
            .RunAsync(CancellationToken.None);

        // TigerCli reports a missing required option (unlike a missing positional argument) as a
        // validation error.
        Assert.Equal((int)ToolkitResponseCode.TigerCliValidationError, result.ExitCode);
        Assert.Contains("Missing required option: --file", result.StdErr);
    }

    [Fact]
    public void DbSqlCmd_RejectsMissingFileAndNegativeTimeout()
    {
        var missingFile = new DbSqlCmdCommand.Settings
        {
            ConnectionName = "any",
            FilePath = Path.Combine(CreateTempDirectory(), "missing.sql")
        }.Validate();
        var negativeTimeout = new DbSqlCmdCommand.Settings
        {
            ConnectionName = "any",
            CommandTimeout = -1
        }.Validate();

        Assert.False(missingFile.IsValid);
        Assert.Contains("not found", missingFile.ErrorMessage);
        Assert.False(negativeTimeout.IsValid);
        Assert.Contains("--command-timeout", negativeTimeout.ErrorMessage);
    }

    [Theory]
    [InlineData(10, "Raiserror (line 3): text")]
    [InlineData(16, "Error (line 3): text")]
    [InlineData(18, "Error (line 3): text")]
    public void ScriptIssues_LabelBatchFailingSeveritiesAsErrors(byte severity, string expected)
    {
        // TigerQuery categorizes severity 11-16 as "Warning" although those errors fail the batch.
        var message = new SqlCmdMessage { Text = "text", Severity = severity, LineNumber = 3 };

        Assert.Equal(expected, ScriptRunner.FormatIssue(message));
    }

    [Fact]
    public void TigerWrapCli_UsesTigerQueryInProcess_WithoutTheTigerSqlCmdExecutable()
    {
        var referenced = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var pending = new Queue<AssemblyName>(typeof(TigerWrapApp).Assembly.GetReferencedAssemblies());
        while (pending.Count > 0)
        {
            var name = pending.Dequeue();
            if (!referenced.Add(name.Name!) || !name.Name!.StartsWith("ItTiger.", StringComparison.Ordinal))
            {
                continue;
            }

            foreach (var child in Assembly.Load(name).GetReferencedAssemblies())
            {
                pending.Enqueue(child);
            }
        }

        // The SQL engine is the TigerQuery library, loaded in-process...
        Assert.Contains(typeof(TigerQueryEngine).Assembly.GetName().Name!, referenced);
        // ...and neither the tiger-sqlcmd executable assembly nor its package is in the graph.
        Assert.DoesNotContain("tiger-sqlcmd", referenced);
        Assert.DoesNotContain("ItTiger.TigerSqlCmd", referenced);

        var depsFile = Path.Combine(AppContext.BaseDirectory, "tiger-wrap.deps.json");
        Assert.True(File.Exists(depsFile), $"Missing {depsFile}");
        var deps = File.ReadAllText(depsFile);
        Assert.Contains("ItTiger.TigerQuery", deps);
        Assert.DoesNotContain("ItTiger.TigerSqlCmd", deps, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("tiger-sqlcmd", deps, StringComparison.OrdinalIgnoreCase);
    }

    private static SqlServerConnectionStore CreateStore() =>
        new(
            new SqlServerConnectionStoreOptions { FilePath = Path.Combine(CreateTempDirectory(), "connections.json") },
            new NoOpConnectionPasswordProtector());

    private static string CreateTempDirectory()
    {
        var directory = Path.Combine(Path.GetTempPath(), "TigerWrap.Tests", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(directory);
        return directory;
    }
}
