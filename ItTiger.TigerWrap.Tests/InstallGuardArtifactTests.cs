using System.Text.RegularExpressions;
using ItTiger.TigerWrap.Cli.Commands.Db;
using ItTiger.TigerWrap.Core;

namespace ItTiger.TigerWrap.Tests;

/// <summary>
/// Structural checks over the shipped SQL artifacts. These need no SQL Server: they protect the
/// property that the release artifact actually carries the guard, and that the CLI preflight and
/// the SQL guard use the same "empty enough" predicate.
/// </summary>
public sealed class InstallGuardArtifactTests
{
    private static string GuardSourcePath =>
        Path.Combine(SqlServerTestDatabase.RepoRoot, "TigerWrapDb", "Scripts", "Script.PreInstallEmptyCheck.sql");

    private static string SchemaVersionSourcePath =>
        Path.Combine(SqlServerTestDatabase.RepoRoot, "TigerWrapDb", "Scripts", "Script.Version.sql");

    private static string BuildInstallerPath =>
        Path.Combine(SqlServerTestDatabase.RepoRoot, "ItTiger.TigerWrap.Installer", "BuildInstaller.ps1");

    private static string FullDeployArtifactPath =>
        Path.Combine(SqlServerTestDatabase.DeploymentScriptsFolder, DbCommandSupport.FullDeployScriptFileName);

    /// <summary>The version TigerWrapDb installs, read from the single source of truth.</summary>
    private static string SchemaVersionFromSql()
    {
        var match = Regex.Match(
            File.ReadAllText(SchemaVersionSourcePath),
            @"@version\s+VARCHAR\(50\)\s*=\s*'(?<v>[^']+)'");

        Assert.True(match.Success, $"Could not read the schema version from {SchemaVersionSourcePath}.");
        return match.Groups["v"].Value;
    }

    [Fact]
    public void ExpectedDbInfo_TracksTheSchemaVersionScript()
    {
        // ExpectedDbInfo drives the install artifact name, the install plan and post-install
        // verification; Script.Version.sql is what the artifact actually writes into the database.
        Assert.Equal(ExpectedDbInfo.CurrentSchemaVersion, SchemaVersionFromSql());
    }

    [Fact]
    public void DbInstall_ResolvesTheArtifactForTheCurrentSchemaVersion()
    {
        Assert.Equal(
            $"TigerWrapDb_FullDeploy_v_{SchemaVersionFromSql()}.sql",
            DbCommandSupport.FullDeployScriptFileName);
    }

    [Fact]
    public void FullDeployArtifact_ForTheCurrentSchemaVersion_IsPresentForPackaging()
    {
        // BuildInstaller.ps1 copies TigerWrapDb_FullDeploy_v_$schemaVersion.sql into {app}\sql,
        // which is exactly the path db install resolves by default.
        Assert.True(
            File.Exists(FullDeployArtifactPath),
            $"Full deploy artifact for {ExpectedDbInfo.CurrentSchemaVersion} not found: {FullDeployArtifactPath}");
    }

    [Fact]
    public void InstallerPackaging_ShipsTheArtifactForTheCurrentSchemaVersion()
    {
        var script = File.ReadAllText(BuildInstallerPath);

        // The full deploy is packaged by TigerWrapDb schema version, not by the CLI/product version
        // in Version.props: the two are released on their own schedules, and packaging by product
        // version would ship an artifact belonging to a different schema version.
        Assert.Contains("Script.Version.sql", script);
        Assert.Contains("TigerWrapDb_FullDeploy_v_$schemaVersion.sql", script);
        Assert.DoesNotContain("TigerWrapDb_FullDeploy_v_$version.sql", script);

        // A missing or unguarded artifact must break the installer build, not warn.
        Assert.Contains("Full deploy script not found", script);
        Assert.Contains("TigerWrapDb installation refused", script);
    }

    [Fact]
    public void ReleasedFullDeployArtifacts_DoNotCarryTheInstallGuard()
    {
        // The guard shipped with TigerWrapDb 0.9.2. The released artifacts predate it and must stay
        // exactly as they were published; ReleasedArtifactTests proves they are unchanged, and this
        // proves the current artifact is genuinely a new one rather than a rewritten old one.
        foreach (var released in ReleasedArtifactTests.ReleasedArtifacts
                     .Where(path => path.Contains("_FullDeploy_", StringComparison.Ordinal)))
        {
            var path = Path.Combine(
                SqlServerTestDatabase.RepoRoot,
                released.Replace('/', Path.DirectorySeparatorChar));

            Assert.NotEqual(Path.GetFullPath(FullDeployArtifactPath), Path.GetFullPath(path));
            Assert.DoesNotContain("TigerWrapDb installation refused.", File.ReadAllText(path));
        }
    }

    [Fact]
    public void GuardSource_AndCliPreflight_UseTheSameConflictQuery()
    {
        var guard = File.ReadAllText(GuardSourcePath);

        Assert.Equal(
            DbInstallLiveTests.Normalise(DatabaseEmptinessCheck.ConflictQuery),
            DbInstallLiveTests.Normalise(DbInstallLiveTests.ExtractSharedConflictQuery(guard)));
    }

    [Fact]
    public void FullDeployArtifact_ContainsTheGuardBeforeAnyObjectIsCreated()
    {
        var artifact = File.ReadAllText(FullDeployArtifactPath);

        var guardStart = artifact.IndexOf("Checking that the target database is empty...", StringComparison.Ordinal);
        Assert.True(guardStart >= 0, "The full deploy artifact does not contain the install guard.");

        // Search from the guard: the artifact's own SQLCMD-mode check uses SET NOEXEC ON earlier.
        var noExec = artifact.IndexOf("SET NOEXEC ON;", guardStart, StringComparison.Ordinal);
        var firstCreate = FirstObjectCreationIndex(artifact);

        Assert.True(noExec > guardStart, "The install guard does not stop execution.");
        Assert.True(firstCreate >= 0, "The full deploy artifact creates no objects at all.");
        Assert.True(
            noExec < firstCreate,
            "The install guard must run before the first object is created in the full deploy artifact.");
    }

    [Fact]
    public void FullDeployArtifact_EmbedsTheSameConflictQueryAsTheGuardSource()
    {
        var artifact = DbInstallLiveTests.Normalise(File.ReadAllText(FullDeployArtifactPath));

        Assert.Contains(DbInstallLiveTests.Normalise(DatabaseEmptinessCheck.ConflictQuery), artifact);
    }

    [Fact]
    public void FullDeployArtifact_DoesNotActivateTheUpgradeVersionCheck()
    {
        // The two pre-deployment guards are mutually exclusive; an active upgrade check inside a
        // full deploy would refuse every valid empty target.
        var artifact = File.ReadAllText(FullDeployArtifactPath);

        Assert.Contains("--:r .\\Script.PreUpgradeVersionCheck.sql", artifact);
        Assert.DoesNotContain("Checking database version before upgrade...", artifact);
    }

    private static int FirstObjectCreationIndex(string artifact)
    {
        int[] candidates =
        [
            artifact.IndexOf("CREATE SCHEMA ", StringComparison.Ordinal),
            artifact.IndexOf("CREATE TABLE ", StringComparison.Ordinal),
            artifact.IndexOf("CREATE PROCEDURE ", StringComparison.Ordinal),
            artifact.IndexOf("CREATE FUNCTION ", StringComparison.Ordinal),
            artifact.IndexOf("CREATE VIEW ", StringComparison.Ordinal)
        ];

        return candidates.Where(index => index >= 0).DefaultIfEmpty(-1).Min();
    }
}
