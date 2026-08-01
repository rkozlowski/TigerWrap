using System.Diagnostics;

namespace ItTiger.TigerWrap.Tests;

/// <summary>
/// Released deployment artifacts are immutable. Once a script has shipped, the file in the
/// repository is the file users ran, so a later change to <c>TigerWrapDb</c> must produce a new
/// versioned artifact instead of editing an old one in place.
/// <para>
/// The check compares each listed file with its blob in <c>git HEAD</c>, which catches an in-place
/// edit regardless of how it was made and needs no stored hashes to maintain. Blob ids are compared
/// rather than file bytes so that git's own line-ending filters are applied to both sides.
/// </para>
/// </summary>
public sealed class ReleasedArtifactTests
{
    /// <summary>
    /// Artifacts that have shipped. Add a file here when it is released; never remove one, and
    /// never edit a listed file - <see cref="AllTrackedDeploymentScripts_AreEitherReleasedOrUnderDevelopment"/>
    /// fails if a released artifact is missing from this list.
    /// </summary>
    public static readonly string[] ReleasedArtifacts =
    [
        "TigerWrapDb/DeploymentScripts/TigerWrapDb_FullDeploy_v_0.9.0.sql",
        "TigerWrapDb/DeploymentScripts/TigerWrapDb_FullDeploy_v_0.9.1.sql",
        "TigerWrapDb/DeploymentScripts/TigerWrapDb_Upgrade_v_0.8.5_to_0.9.0.sql",
        "TigerWrapDb/DeploymentScripts/TigerWrapDb_Upgrade_v_0.9.0_to_0.9.1.sql"
    ];

    public static TheoryData<string> ReleasedArtifactPaths()
    {
        var data = new TheoryData<string>();
        foreach (var path in ReleasedArtifacts)
        {
            data.Add(path);
        }

        return data;
    }

    [Theory]
    [MemberData(nameof(ReleasedArtifactPaths))]
    public void ReleasedArtifact_IsUnchangedFromGitHead(string repoRelativePath)
    {
        SkipUnlessGitIsAvailable();

        var absolutePath = Path.Combine(SqlServerTestDatabase.RepoRoot, repoRelativePath.Replace('/', Path.DirectorySeparatorChar));
        Assert.True(File.Exists(absolutePath), $"Released artifact is missing from the working tree: {repoRelativePath}");

        var head = Git($"rev-parse HEAD:\"{repoRelativePath}\"");
        Assert.True(
            head.ExitCode == 0,
            $"'{repoRelativePath}' is listed as released but is not tracked in git HEAD: {head.StdErr}");

        var working = Git($"hash-object -- \"{repoRelativePath}\"");
        Assert.True(working.ExitCode == 0, $"git hash-object failed for '{repoRelativePath}': {working.StdErr}");

        Assert.True(
            string.Equals(head.StdOut, working.StdOut, StringComparison.Ordinal),
            $"Released artifact '{repoRelativePath}' differs from git HEAD (HEAD blob {head.StdOut}, "
                + $"working tree blob {working.StdOut}). Released artifacts are immutable: revert the file "
                + "with 'git checkout -- <path>' and put the change in a new versioned artifact instead.");
    }

    [Fact]
    public void AllTrackedDeploymentScripts_AreEitherReleasedOrUnderDevelopment()
    {
        SkipUnlessGitIsAvailable();

        // Every deployment script already committed is by definition shipped, so it must be listed
        // above. A script for the version currently under development is untracked at HEAD and is
        // therefore absent from this listing until it is released.
        var listing = Git("ls-tree --name-only HEAD TigerWrapDb/DeploymentScripts/");
        Assert.True(listing.ExitCode == 0, $"git ls-tree failed: {listing.StdErr}");

        var tracked = listing.StdOut
            .Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Where(path => path.EndsWith(".sql", StringComparison.OrdinalIgnoreCase))
            .ToArray();

        Assert.NotEmpty(tracked);

        var unlisted = tracked.Except(ReleasedArtifacts, StringComparer.Ordinal).ToArray();
        Assert.True(
            unlisted.Length == 0,
            "These committed deployment artifacts are not covered by the immutability guard; add them to "
                + $"{nameof(ReleasedArtifacts)}: {string.Join(", ", unlisted)}");
    }

    private static void SkipUnlessGitIsAvailable()
    {
        var result = Git("rev-parse --git-dir");
        if (result.ExitCode != 0)
        {
            Assert.Skip($"git is not available in {SqlServerTestDatabase.RepoRoot}: {result.StdErr}");
        }
    }

    private static (int ExitCode, string StdOut, string StdErr) Git(string arguments)
    {
        try
        {
            using var process = Process.Start(new ProcessStartInfo("git", arguments)
            {
                WorkingDirectory = SqlServerTestDatabase.RepoRoot,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            });

            if (process is null)
            {
                return (-1, string.Empty, "git could not be started.");
            }

            var stdOut = process.StandardOutput.ReadToEnd();
            var stdErr = process.StandardError.ReadToEnd();
            process.WaitForExit();
            return (process.ExitCode, stdOut.Trim(), stdErr.Trim());
        }
        catch (Exception ex)
        {
            return (-1, string.Empty, ex.Message);
        }
    }
}
