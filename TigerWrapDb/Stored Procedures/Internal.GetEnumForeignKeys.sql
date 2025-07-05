

CREATE PROCEDURE [Internal].[GetEnumForeignKeys]
	@projectId SMALLINT,
	@dbId SMALLINT,
	@langId TINYINT,
	@enumId INT,
	@errorMessage NVARCHAR(2000) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rc INT;

	DECLARE @RC_OK INT = 0;
	DECLARE @RC_ERR_PROJECT INT = 21;
	DECLARE @RC_ERR_DB INT = 22;
	DECLARE @RC_ERR_LANG INT = 23;
	

	DECLARE @dbName NVARCHAR(128) = DB_NAME(@dbId);

	IF @dbName IS NULL
	BEGIN
		SELECT @rc = @RC_ERR_DB, @errorMessage=N'Database not found';
		RETURN @rc;
	END
	
	DECLARE @enumSchema NVARCHAR(128);
	DECLARE @enumTable NVARCHAR(128);
	DECLARE @nameColumn NVARCHAR(128);
	DECLARE @valueColumn NVARCHAR(128);

	SELECT @enumSchema=[Schema], @enumTable=[Table], @nameColumn=[NameColumn], @valueColumn=[ValueColumn]
	FROM #Enum
	WHERE [Id]=@enumId;

    DECLARE @query NVARCHAR(4000);

	

	SET @query = N'USE ' + QUOTENAME(@dbName) + N';
	';
	SET @query += N'SELECT ' + LOWER(@enumId) + N' [EnumId], sch.name [ForeignSchema], tab1.name [ForeignTable], col1.name [ForeignColumn] ' 
	SET @query += N'FROM sys.foreign_key_columns fkc '
	SET @query += N'INNER JOIN sys.objects obj ON obj.object_id = fkc.constraint_object_id '
	SET @query += N'INNER JOIN sys.tables tab1 ON tab1.object_id = fkc.parent_object_id '
	SET @query += N'INNER JOIN sys.schemas sch ON tab1.schema_id = sch.schema_id '
	SET @query += N'INNER JOIN sys.columns col1 ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id '
	SET @query += N'INNER JOIN sys.tables tab2 ON tab2.object_id = fkc.referenced_object_id '
	SET @query += N'INNER JOIN sys.schemas sch2 ON tab2.schema_id = sch2.schema_id '
	SET @query += N'INNER JOIN sys.columns col2 ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id '
	SET @query += N'WHERE sch2.name=' + QUOTENAME(@enumSchema, '''') + N' AND tab2.name=' + QUOTENAME(@enumTable, '''') + N' AND col2.name=' + QUOTENAME(@valueColumn, '''');
	SET @query += N';
	';
	--PRINT(@query);
	
	INSERT INTO #EnumForeignKey ([EnumId], [ForeignSchema], [ForeignTable], [ForeignColumn])
	EXEC(@query);

END