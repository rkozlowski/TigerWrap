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
    /// <summary>Schema version and API level match this tool version.</summary>
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

    public static string UpgradeScriptFileName =>
        $"TigerWrapDb_Upgrade_v_{UpgradeSourceVersion}_to_{ExpectedDbInfo.CurrentSchemaVersion}.sql";

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

        if (string.Equals(info.Version, ExpectedDbInfo.CurrentSchemaVersion, StringComparison.OrdinalIgnoreCase))
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
