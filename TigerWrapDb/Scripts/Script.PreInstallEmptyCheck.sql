/*
	TigerWrapDb full-install guard.
--------------------------------------------------------------------------------------
	Include this file from Script.PreDeployment.sql ONLY when generating the
	FULL DEPLOY artifact (TigerWrapDb_FullDeploy_v_<version>.sql).
	It is mutually exclusive with .\Script.PreUpgradeVersionCheck.sql, which is
	included only when generating an UPGRADE artifact.

	The guard is authoritative: it runs before any TigerWrap object is created and
	refuses installation into a database that already contains user application
	objects, or whose compatibility level is too low.

	Users, roles, permissions and normal database infrastructure are deliberately
	ignored - only user-defined objects, user-defined types, user assemblies and
	TigerWrap-owned schemas make a database non-empty.

	The conflict query below is duplicated verbatim in the CLI preflight
	(ItTiger.TigerWrap.Cli/Commands/Db/DatabaseEmptinessCheck.cs). A shared
	implementation is impossible - this copy has to run with no TigerWrap objects
	present - so the two are kept identical by text and proven equal by test.
--------------------------------------------------------------------------------------
*/
USE [$(DatabaseName)];
GO
-- FOR XML PATH(...).value(...) below requires QUOTED_IDENTIFIER ON, which is not the
-- default for every client (sqlcmd runs with it OFF unless the script sets it).
SET ANSI_NULLS, QUOTED_IDENTIFIER ON;
GO
PRINT N'Checking that the target database is empty...';
GO
SET NOCOUNT ON;

DECLARE @minCompatibilityLevel TINYINT = 130;
DECLARE @compatibilityLevel TINYINT = (SELECT [compatibility_level] FROM sys.databases WHERE [database_id] = DB_ID());
DECLARE @conflicts TABLE ([Kind] NVARCHAR (30) NOT NULL, [Name] NVARCHAR (400) NOT NULL);

INSERT INTO @conflicts ([Kind], [Name])
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
WHERE s.[name] IN (N'DbInfo', N'Enum', N'Flag', N'History', N'Internal', N'Parser', N'ParserEnum', N'Project', N'Static', N'Toolkit', N'View');

DECLARE @conflictCount INT = (SELECT COUNT(*) FROM @conflicts);
DECLARE @byKind NVARCHAR (MAX);
DECLARE @sample NVARCHAR (MAX);

IF @conflictCount > 0 OR @compatibilityLevel < @minCompatibilityLevel
BEGIN
	PRINT N'';
	PRINT N'--------------------------------------------------------------------';
	PRINT N'TigerWrapDb installation refused.';
	PRINT N'--------------------------------------------------------------------';
	PRINT N'Server:   ' + ISNULL(@@SERVERNAME, N'<unknown>');
	PRINT N'Database: ' + QUOTENAME(DB_NAME());

	IF @conflictCount > 0
	BEGIN
		SELECT @byKind = STUFF((SELECT N', ' + g.[Kind] + N': ' + CONVERT (NVARCHAR (20), g.[Cnt])
		                        FROM (SELECT [Kind], COUNT(*) AS [Cnt] FROM @conflicts GROUP BY [Kind]) AS g
		                        ORDER BY g.[Kind]
		                        FOR XML PATH (N''), TYPE).value(N'.', N'NVARCHAR(MAX)'), 1, 2, N'');
		SELECT @sample = STUFF((SELECT N', ' + c.[Name]
		                        FROM (SELECT TOP (10) [Kind], [Name] FROM @conflicts ORDER BY [Kind], [Name]) AS c
		                        ORDER BY c.[Kind], c.[Name]
		                        FOR XML PATH (N''), TYPE).value(N'.', N'NVARCHAR(MAX)'), 1, 2, N'');

		PRINT N'';
		PRINT N'The database is not empty. TigerWrapDb must be installed into an empty';
		PRINT N'database. Users, roles and permissions do not count as content; only';
		PRINT N'user-defined objects and TigerWrap schemas do.';
		PRINT N'';
		PRINT N'Conflicting objects: ' + CONVERT (NVARCHAR (20), @conflictCount);
		PRINT N'By type:             ' + ISNULL(@byKind, N'');
		PRINT N'Sample:              ' + ISNULL(@sample, N'');
	END

	IF @compatibilityLevel < @minCompatibilityLevel
	BEGIN
		PRINT N'';
		PRINT N'The database compatibility level is ' + CONVERT (NVARCHAR (10), @compatibilityLevel) + N'; TigerWrapDb requires ' + CONVERT (NVARCHAR (10), @minCompatibilityLevel) + N' or higher.';
		PRINT N'Fix it with:';
		PRINT N'  ALTER DATABASE ' + QUOTENAME(DB_NAME()) + N' SET COMPATIBILITY_LEVEL = ' + CONVERT (NVARCHAR (10), @minCompatibilityLevel) + N';';
	END

	PRINT N'';
	PRINT N'No TigerWrap objects were created. Installation stopped.';
	PRINT N'--------------------------------------------------------------------';
	RAISERROR (N'TigerWrapDb installation refused: the target database is not empty or not capable.', 16, 1);
	SET NOEXEC ON;
END
ELSE
BEGIN
	PRINT N'Target database is empty. Installing TigerWrapDb...';
END
GO
