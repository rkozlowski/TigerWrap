CREATE PROCEDURE [Internal].[GetEnums]
	@projectId SMALLINT,
	@dbId SMALLINT,
	@langId TINYINT,
	@errorMessage NVARCHAR(2000) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rc INT;

	DECLARE @RC_OK INT = 0;
	DECLARE @RC_ERR_PROJECT INT = 21;
	DECLARE @RC_ERR_DB INT = 22;
	DECLARE @RC_ERR_LANG INT = 23;

    DECLARE @NM_EXACT_MATCH TINYINT = 1;
    DECLARE @NM_PREFIX TINYINT = 2;
    DECLARE @NM_SUFFIX TINYINT = 3;
    DECLARE @NM_LIKE TINYINT = 4;
    DECLARE @NM_ANY TINYINT = 255;
	
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Project] WHERE [Id]=@projectId)
	BEGIN
		SELECT @rc = @RC_ERR_PROJECT, @errorMessage=N'Unknown project';
		RETURN @rc;
	END

	DECLARE @dbName NVARCHAR(128) = DB_NAME(@dbId);

	IF @dbName IS NULL
	BEGIN
		SELECT @rc = @RC_ERR_DB, @errorMessage=N'Database not found';
		RETURN @rc;
	END

    DECLARE @enumSchemas NVARCHAR(4000);
    SELECT @enumSchemas=STRING_AGG(QUOTENAME(e.[Schema], N''''), ',') FROM (SELECT DISTINCT [Schema] FROM [dbo].[ProjectEnum] WHERE [ProjectId]=@projectId) e;

    IF NULLIF(LTRIM(@enumSchemas), '') IS NULL
    BEGIN
        SELECT @rc = @RC_OK;
		RETURN @rc;
    END

    DROP TABLE IF EXISTS #EveryEnum;
    CREATE TABLE #EveryEnum
    (
        [Id] INT NOT NULL IDENTITY (1, 1) PRIMARY KEY,        
        [Schema] NVARCHAR(128) NOT NULL,
        [Table] NVARCHAR(128) NOT NULL,        
        [NameColumn] NVARCHAR(128) NOT NULL,
        [ValueColumn] NVARCHAR(128) NOT NULL,
        [EnumName] NVARCHAR(200) NULL,
        [ValueType] NVARCHAR(128) NOT NULL,
        [IsSetOfFlags] BIT NOT NULL DEFAULT (0),
        [ProjectEnumId] INT NULL,
        UNIQUE ([Schema], [Table])
    );

    DECLARE @query NVARCHAR(4000);

	

	SET @query = N'USE ' + QUOTENAME(@dbName) + N';
	';
	SET @query += N'SELECT SCHEMA_NAME(t.schema_id) [Schema], t.[name] [Table], nc.name [NameColumn], vc.name [ValueColumn], vct.[name] [ValueType] '
	SET @query += N'FROM sys.tables t '
	SET @query += N'JOIN sys.indexes pk ON pk.object_id=t.object_id AND pk.is_primary_key=1 '
	SET @query += N'JOIN sys.index_columns pkc ON pkc.object_id=pk.object_id AND pkc.index_id=pk.index_id AND pkc.index_column_id=1 AND pkc.is_included_column=0 '
	SET @query += N'JOIN sys.columns vc ON vc.object_id=pkc.object_id AND vc.column_id=pkc.column_id '
	SET @query += N'JOIN sys.types vct ON vct.system_type_id=vc.system_type_id AND vct.user_type_id=vc.user_type_id AND vct.name IN (''tinyint'', ''smallint'', ''int'', ''bigint'') '
	SET @query += N'JOIN sys.indexes ux ON ux.object_id=t.object_id AND ux.is_primary_key=0 AND ux.is_unique=1 '
	SET @query += N'JOIN sys.index_columns uxc ON uxc.object_id=ux.object_id AND uxc.index_id=ux.index_id AND uxc.index_column_id=1 AND uxc.is_included_column=0 '
	SET @query += N'JOIN sys.columns nc ON nc.object_id=uxc.object_id AND nc.column_id=uxc.column_id '
	SET @query += N'JOIN sys.types nct ON nct.system_type_id=nc.system_type_id AND nct.user_type_id=nc.user_type_id AND nct.name IN (''varchar'', ''nvarchar'') '
	SET @query += N'LEFT JOIN sys.index_columns pkc2 ON pkc2.object_id=pk.object_id AND pkc2.index_id=pk.index_id AND pkc2.index_column_id=2 '
	SET @query += N'LEFT JOIN sys.index_columns uxc2 ON uxc2.object_id=pk.object_id AND uxc2.index_id=ux.index_id AND uxc2.index_column_id=2 '
	SET @query += N'LEFT JOIN sys.columns idnc ON idnc.object_id=t.object_id AND idnc.is_identity=1 '
	SET @query += N'LEFT JOIN sys.indexes ux2 ON ux2.object_id=t.object_id AND ux2.is_primary_key=0 AND ux2.is_unique=1 AND ux2.index_id<>ux.index_id '
	SET @query += N'WHERE t.[Type]=''U'' AND idnc.column_id IS NULL AND pkc2.index_column_id IS NULL AND uxc2.index_column_id IS NULL AND ux2.index_id IS NULL '
	SET @query += N'AND SCHEMA_NAME(t.schema_id) IN (' + @enumSchemas + N') '
	SET @query += N'ORDER BY t.[name] '
	SET @query += N';
	';
	--PRINT(@query);
	
	INSERT INTO #EveryEnum ([Schema], [Table], [NameColumn], [ValueColumn], [ValueType])
	EXEC(@query);


	DECLARE c CURSOR LOCAL FAST_FORWARD FOR
	SELECT [Schema], [NamePattern], [NameColumn]
	FROM [dbo].[ProjectEnum]
	WHERE [ProjectId] = @projectId AND [NameColumn] IS NOT NULL;

	DECLARE @s NVARCHAR(128), @t NVARCHAR(200), @nc NVARCHAR(128);
	DECLARE @query2 NVARCHAR(MAX);

	OPEN c;
	FETCH NEXT FROM c INTO @s, @t, @nc;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @query2 = N'USE ' + QUOTENAME(@dbName) + N';
		SELECT 
			' + QUOTENAME(@s, '''') + N' AS [Schema],
			' + QUOTENAME(@t, '''') + N' AS [Table],
			' + QUOTENAME(@nc, '''') + N' AS [NameColumn],
			vc.[name] AS [ValueColumn],
			vct.[name] AS [ValueType]
		FROM sys.tables t
		JOIN sys.indexes pk ON pk.object_id = t.object_id AND pk.is_primary_key = 1
		JOIN sys.index_columns pkc ON pkc.object_id = pk.object_id AND pkc.index_id = pk.index_id AND pkc.index_column_id = 1 AND pkc.is_included_column = 0
		JOIN sys.columns vc ON vc.object_id = pkc.object_id AND vc.column_id = pkc.column_id
		JOIN sys.types vct ON vct.system_type_id = vc.system_type_id AND vct.user_type_id = vc.user_type_id AND vct.name IN (''tinyint'', ''smallint'', ''int'', ''bigint'')
		WHERE t.[name] = ' + QUOTENAME(@t, '''') + ' AND SCHEMA_NAME(t.schema_id) = ' + QUOTENAME(@s, '''') + ';
		';

		-- PRINT (@query2);

		INSERT INTO #EveryEnum ([Schema], [Table], [NameColumn], [ValueColumn], [ValueType])
		EXEC (@query2);

		FETCH NEXT FROM c INTO @s, @t, @nc;
	END

	CLOSE c; DEALLOCATE c;

    -- now filter only selected enums

    UPDATE e
    SET e.[ProjectEnumId]=pe.[Id], e.[IsSetOfFlags]=pe.[IsSetOfFlags]
    FROM #EveryEnum e
    JOIN [dbo].[ProjectEnum] pe ON pe.[ProjectId]=@projectId AND pe.[Schema]=e.[Schema] AND [Internal].[IsNameMatch](e.[Table], pe.[NameMatchId], pe.[NamePattern], pe.[EscChar])=1
    LEFT JOIN [dbo].[ProjectEnum] xpe ON xpe.[ProjectId]=@projectId AND xpe.[Schema]=e.[Schema] 
    AND [Internal].[IsNameMatch](e.[Table], xpe.[NameMatchId], xpe.[NamePattern], xpe.[EscChar])=1
    AND (xpe.[NameMatchId]<pe.[NameMatchId] OR (xpe.[NameMatchId]=pe.[NameMatchId] AND xpe.[Id]<pe.[Id]))
    WHERE xpe.[Id] IS NULL;
    
    INSERT INTO #Enum ([Schema], [Table], [NameColumn], [ValueColumn], [ValueType], [IsSetOfFlags])
    SELECT e.[Schema], e.[Table], e.[NameColumn], e.[ValueColumn], e.[ValueType], e.[IsSetOfFlags]
    FROM #EveryEnum e
    WHERE e.[ProjectEnumId] IS NOT NULL;

    DROP TABLE IF EXISTS #EveryEnum;
END