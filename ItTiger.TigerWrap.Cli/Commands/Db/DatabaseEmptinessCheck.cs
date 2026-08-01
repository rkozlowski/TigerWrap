using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;

namespace ItTiger.TigerWrap.Cli.Commands.Db;

/// <summary>One user-defined object that prevents a TigerWrapDb installation.</summary>
internal sealed record DatabaseConflict(string Kind, string Name);

/// <summary>
/// Result of the <c>db install</c> preflight: whether the target database is empty enough
/// to receive TigerWrapDb, and whether it is capable of running it.
/// </summary>
internal sealed record DatabaseEmptinessResult(
    int ConflictCount,
    IReadOnlyList<(string Kind, int Count)> ConflictsByKind,
    IReadOnlyList<DatabaseConflict> SampleConflicts,
    byte CompatibilityLevel,
    string Collation)
{
    public bool IsEmpty => ConflictCount == 0;

    public bool IsCapable => CompatibilityLevel >= DatabaseEmptinessCheck.MinCompatibilityLevel;

    public bool CanInstall => IsEmpty && IsCapable;
}

/// <summary>
/// CLI-side counterpart of the authoritative SQL guard in
/// <c>TigerWrapDb/Scripts/Script.PreInstallEmptyCheck.sql</c>.
/// <para>
/// The two cannot share an implementation - the SQL copy has to run inside the deployment
/// script with no TigerWrap objects present - so <see cref="ConflictQuery"/> is duplicated
/// verbatim in both places and <c>DbInstallLiveTests</c> proves they stay identical and
/// agree on the same database.
/// </para>
/// </summary>
internal static class DatabaseEmptinessCheck
{
    /// <summary>Minimum database compatibility level TigerWrapDb requires.</summary>
    public const byte MinCompatibilityLevel = 130;

    /// <summary>Number of conflicting objects listed in diagnostics.</summary>
    public const int SampleSize = 10;

    /// <summary>
    /// The canonical "what makes a database non-empty" predicate, kept byte-for-byte
    /// identical to the copy in Script.PreInstallEmptyCheck.sql. Users, roles, permissions,
    /// database settings and platform metadata are deliberately not included.
    /// </summary>
    public const string ConflictQuery = """
        SELECT CASE o.[type] WHEN 'U' THEN N'Table'
                             WHEN 'V' THEN N'View'
                             WHEN 'SO' THEN N'Sequence'
                             WHEN 'SN' THEN N'Synonym'
                             WHEN 'P' THEN N'Stored procedure'
                             WHEN 'PC' THEN N'Stored procedure'
                             WHEN 'X' THEN N'Stored procedure'
                             ELSE N'Function' END AS [Kind],
               QUOTENAME(s.[name]) + N'.' + QUOTENAME(o.[name]) AS [Name]
        FROM sys.objects AS o
        INNER JOIN sys.schemas AS s ON s.[schema_id] = o.[schema_id]
        WHERE o.[is_ms_shipped] = 0
          AND o.[parent_object_id] = 0
          AND o.[type] IN ('U', 'V', 'P', 'PC', 'X', 'FN', 'IF', 'TF', 'AF', 'FS', 'FT', 'SO', 'SN')
        UNION ALL
        SELECT N'User-defined type', QUOTENAME(s.[name]) + N'.' + QUOTENAME(t.[name])
        FROM sys.types AS t
        INNER JOIN sys.schemas AS s ON s.[schema_id] = t.[schema_id]
        WHERE t.[is_user_defined] = 1
        UNION ALL
        SELECT N'Assembly', QUOTENAME(a.[name])
        FROM sys.assemblies AS a
        WHERE a.[is_user_defined] = 1
        UNION ALL
        SELECT N'TigerWrap schema', QUOTENAME(s.[name])
        FROM sys.schemas AS s
        WHERE s.[name] IN (N'DbInfo', N'Enum', N'Flag', N'History', N'Internal', N'Parser', N'ParserEnum', N'Project', N'Static', N'Toolkit', N'View')
        """;

    private const string PreflightSql = $"""
        SET NOCOUNT ON;

        DECLARE @conflicts TABLE ([Kind] NVARCHAR (30) NOT NULL, [Name] NVARCHAR (400) NOT NULL);

        INSERT INTO @conflicts ([Kind], [Name])
        {ConflictQuery};

        SELECT [compatibility_level] AS [CompatibilityLevel], [collation_name] AS [Collation]
        FROM sys.databases
        WHERE [database_id] = DB_ID();

        SELECT COUNT(*) FROM @conflicts;

        SELECT [Kind], COUNT(*) AS [Count]
        FROM @conflicts
        GROUP BY [Kind]
        ORDER BY [Kind];

        SELECT TOP (@sampleSize) [Kind], [Name]
        FROM @conflicts
        ORDER BY [Kind], [Name];
        """;

    public static async Task<DatabaseEmptinessResult> InspectAsync(
        string connectionString,
        CancellationToken cancellationToken = default)
    {
        await using var connection = new SqlConnection(connectionString);
        var command = new CommandDefinition(
            PreflightSql,
            new { sampleSize = SampleSize },
            cancellationToken: cancellationToken);

        await using var reader = await connection.QueryMultipleAsync(command);

        var database = await reader.ReadSingleAsync<DatabaseFacts>();
        var conflictCount = await reader.ReadSingleAsync<int>();
        var byKind = (await reader.ReadAsync<KindCount>())
            .Select(row => (row.Kind, row.Count))
            .ToList();
        var sample = (await reader.ReadAsync<DatabaseConflict>()).ToList();

        return new DatabaseEmptinessResult(
            conflictCount,
            byKind,
            sample,
            (byte)database.CompatibilityLevel,
            database.Collation ?? string.Empty);
    }

    private sealed class DatabaseFacts
    {
        public byte CompatibilityLevel { get; init; }
        public string? Collation { get; init; }
    }

    private sealed class KindCount
    {
        public string Kind { get; init; } = string.Empty;
        public int Count { get; init; }
    }
}
