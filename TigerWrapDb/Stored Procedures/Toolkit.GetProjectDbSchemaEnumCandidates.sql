
CREATE   PROCEDURE [Toolkit].[GetProjectDbSchemaEnumCandidates]
    @projectId SMALLINT,
    @schema NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DROP TABLE IF EXISTS #Result;

    CREATE TABLE #Result
    (
        [Name] NVARCHAR(128) NOT NULL PRIMARY KEY, -- Table name
        [NameColumn] NVARCHAR(128) NULL,           -- Auto-detected name column (optional)
        [NameColumns] NVARCHAR(4000) NOT NULL      -- JSON array of char-like columns
    );

    DECLARE @dbName NVARCHAR(256);
    SELECT @dbName = d.[name]
    FROM [dbo].[Project] p
    JOIN [sys].[databases] d ON p.[DefaultDatabase] = d.[name]
    WHERE p.[Id] = @projectId;

    IF @dbName IS NULL
    BEGIN
        RAISERROR('Could not resolve target database name for the specified project.', 16, 1);
        RETURN;
    END

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
    WITH CandidateTables AS (
        SELECT t.[name] AS TableName, t.[object_id]
        FROM ' + QUOTENAME(@dbName) + '.sys.tables t
        JOIN ' + QUOTENAME(@dbName) + '.sys.schemas s ON t.[schema_id] = s.[schema_id]
        WHERE s.[name] = @schema
        AND EXISTS (
            SELECT 1
            FROM ' + QUOTENAME(@dbName) + '.sys.indexes i
            JOIN ' + QUOTENAME(@dbName) + '.sys.index_columns ic ON i.[object_id] = ic.[object_id] AND i.[index_id] = ic.[index_id]
            JOIN ' + QUOTENAME(@dbName) + '.sys.columns c ON ic.[object_id] = c.[object_id] AND ic.[column_id] = c.[column_id]
            WHERE i.[object_id] = t.[object_id]
              AND i.is_primary_key = 1
              AND c.system_type_id IN (48, 52, 56, 127) -- tinyint, smallint, int, bigint
            GROUP BY i.[object_id]
            HAVING COUNT(*) = 1
        )
        AND EXISTS (
            SELECT 1
            FROM ' + QUOTENAME(@dbName) + '.sys.columns c
            WHERE c.[object_id] = t.[object_id]
              AND c.system_type_id IN (175, 239, 167, 231) -- char, nchar, varchar, nvarchar
        )
    )
    INSERT INTO #Result ([Name], [NameColumn], [NameColumns])
    SELECT 
        ct.TableName,
        (
            SELECT TOP 1 c.[name]
            FROM ' + QUOTENAME(@dbName) + '.sys.indexes i
            JOIN ' + QUOTENAME(@dbName) + '.sys.index_columns ic ON i.[object_id] = ic.[object_id] AND i.[index_id] = ic.[index_id]
            JOIN ' + QUOTENAME(@dbName) + '.sys.columns c ON ic.[object_id] = c.[object_id] AND ic.[column_id] = c.[column_id]
            WHERE i.[object_id] = ct.[object_id]
              AND i.is_unique = 1
              AND c.system_type_id IN (175, 239, 167, 231)
            GROUP BY c.[name]
            HAVING COUNT(*) = 1
        ),
        (
            SELECT c.[name]
            FROM ' + QUOTENAME(@dbName) + '.sys.columns c
            WHERE c.[object_id] = ct.[object_id]
              AND c.system_type_id IN (175, 239, 167, 231)
            FOR JSON PATH
        )
    FROM CandidateTables ct;
    ';

    EXEC sp_executesql @sql, N'@schema NVARCHAR(128)', @schema = @schema;

    SELECT [Name], [NameColumn], [NameColumns]
    FROM #Result
    ORDER BY [Name];

    DROP TABLE IF EXISTS #Result;
END;