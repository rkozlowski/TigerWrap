using ItTiger.TigerQuery.Core;
using ItTiger.TigerWrap.Core;
using Microsoft.Data.SqlClient;

namespace ItTiger.TigerWrap.Cli.Commands.Db;

/// <summary>
/// Compatibility of a probed database with this tool version. Deliberately limited to the
/// single upgrade step this release supports (0.9.0 -> 0.9.1); not a version framework.
/// </summary>
internal enum TigerWrapDbStatus
{
    /// <summary>The database needs no upgrade: see <see cref="DbCommandSupport.NeedsNoUpgrade"/>.</summary>
    Current,

    /// <summary>Exactly the supported upgrade source version (0.9.0).</summary>
    UpgradeAvailable,

    /// <summary>Older than the supported upgrade source; must be upgraded manually first.</summary>
    OlderUnsupported,

    /// <summary>Newer than this tool version; the tool must be updated instead.</summary>
    NewerThanTool,

    /// <summary>[Toolkit].[GetDbInfo] did not identify the database as a TigerWrapDb.</summary>
    NotTigerWrapDb
}

internal sealed record TigerWrapDbInfo(string? DbName, string? Version, byte? ApiLevel, byte? MinApiLevel);

internal sealed record DbProbeResult(TigerWrapDbInfo? Info, string? Error, bool IsNotTigerWrapDb)
{
    public static DbProbeResult Success(TigerWrapDbInfo info) => new(info, null, false);
    public static DbProbeResult NotTigerWrapDb(string error) => new(null, error, true);
    public static DbProbeResult Inaccessible(string error) => new(null, error, false);
}

internal static class DbCommandSupport
{
    /// <summary>The only schema version <c>db upgrade</c> can upgrade from in this release.</summary>
    public const string UpgradeSourceVersion = "0.9.0";

    /// <summary>
    /// The version the packaged upgrade artifact produces. Pinned to the released
    /// <c>0.9.0 -> 0.9.1</c> step rather than derived from
    /// <see cref="ExpectedDbInfo.CurrentSchemaVersion"/>: TigerWrapDb 0.9.2 adds the install-time
    /// empty-database guard and the new version row, but no schema objects and no API level, so
    /// there is no <c>0.9.1 -> 0.9.2</c> upgrade script and a 0.9.1 database needs none. The
    /// upgrade-step catalogue that replaces this pair belongs to the chained-upgrade increment.
    /// </summary>
    public const string UpgradeTargetVersion = "0.9.1";

    public static string UpgradeScriptFileName =>
        $"TigerWrapDb_Upgrade_v_{UpgradeSourceVersion}_to_{UpgradeTargetVersion}.sql";

    /// <summary>
    /// The packaged full-install artifact <c>db install</c> executes. Always the artifact for the
    /// current schema version, so development against an unreleased TigerWrapDb never installs -
    /// or edits - a released artifact.
    /// </summary>
    public static string FullDeployScriptFileName =>
        $"TigerWrapDb_FullDeploy_v_{ExpectedDbInfo.CurrentSchemaVersion}.sql";

    // SQL Server error 2812: could not find stored procedure.
    private const int SqlErrorMissingStoredProcedure = 2812;

    /// <summary>
    /// Calls [Toolkit].[GetDbInfo] without requiring the database to pass API-level validation,
    /// classifying connection failures separately from "not a TigerWrapDb".
    /// </summary>
    public static async Task<DbProbeResult> ProbeAsync(string connectionString, CancellationToken cancellationToken = default)
    {
        var db = new ToolkitDbHelper(connectionString);
        try
        {
            var (_, dbName, version, apiLevel, minApiLevel) = await db.GetDbInfoAsync(cancellationToken);

            if (!string.Equals(dbName, ExpectedDbInfo.DbName, StringComparison.OrdinalIgnoreCase))
            {
                return DbProbeResult.NotTigerWrapDb(
                    $"The database reports type '{dbName ?? "<null>"}' instead of '{ExpectedDbInfo.DbName}'. " +
                    "It is not a TigerWrap metadata database.");
            }

            return DbProbeResult.Success(new TigerWrapDbInfo(dbName, version, apiLevel, minApiLevel));
        }
        catch (SqlException ex) when (ex.Number == SqlErrorMissingStoredProcedure)
        {
            return DbProbeResult.NotTigerWrapDb(
                $"[Toolkit].[GetDbInfo] was not found. The selected database is not a {ExpectedDbInfo.DbName} " +
                "(or is too old for this tool).");
        }
        catch (SqlException ex)
        {
            return DbProbeResult.Inaccessible($"Cannot access the database: {ex.Message}");
        }
        catch (InvalidOperationException ex)
        {
            return DbProbeResult.Inaccessible($"Cannot access the database: {ex.Message}");
        }
    }

    public static TigerWrapDbStatus Classify(TigerWrapDbInfo info)
    {
        if (!string.Equals(info.DbName, ExpectedDbInfo.DbName, StringComparison.OrdinalIgnoreCase))
        {
            return TigerWrapDbStatus.NotTigerWrapDb;
        }

        if (NeedsNoUpgrade(info.Version))
        {
            return TigerWrapDbStatus.Current;
        }

        if (string.Equals(info.Version, UpgradeSourceVersion, StringComparison.OrdinalIgnoreCase))
        {
            return TigerWrapDbStatus.UpgradeAvailable;
        }

        return Version.TryParse(info.Version, out var version)
            && Version.TryParse(ExpectedDbInfo.CurrentSchemaVersion, out var current)
            && version > current
                ? TigerWrapDbStatus.NewerThanTool
                : TigerWrapDbStatus.OlderUnsupported;
    }

    /// <summary>
    /// Versions this tool has nothing to upgrade: the current schema version, and the version the
    /// packaged upgrade artifact produces. They are listed separately because TigerWrapDb 0.9.2
    /// contains exactly the same schema objects and the same API level as 0.9.1 - it differs only
    /// in the install-time guard and the version row - so a 0.9.1 database is already usable and
    /// there is no upgrade script that would move it to 0.9.2.
    /// </summary>
    public static bool NeedsNoUpgrade(string? version) =>
        string.Equals(version, ExpectedDbInfo.CurrentSchemaVersion, StringComparison.OrdinalIgnoreCase)
        || string.Equals(version, UpgradeTargetVersion, StringComparison.OrdinalIgnoreCase);

    public static (string? connectionString, string? error) ResolveConnectionString(
        SqlServerConnectionStore connectionStore,
        string connectionName)
    {
        var resolution = SqlServerConnectionResolver.Resolve(connectionStore, connectionName);
        return resolution.IsSuccess
            ? (resolution.ConnectionString, null)
            : (null, resolution.ErrorMessage);
    }

    /// <summary>
    /// Default deployment-script folder for the installed layout:
    /// {app}\cli\tiger-wrap.exe with scripts in {app}\sql.
    /// </summary>
    public static string GetDefaultSqlFolder() =>
        Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "sql"));
}
