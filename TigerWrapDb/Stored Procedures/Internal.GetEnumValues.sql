
CREATE PROCEDURE [Internal].[GetEnumValues]
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
	DECLARE @descriptionColumn NVARCHAR(128);
	DECLARE @descriptionAttributeClassName VARCHAR(100);

	SELECT @enumSchema=[Schema], @enumTable=[Table], @nameColumn=[NameColumn], @valueColumn=[ValueColumn],
		@descriptionColumn=[DescriptionColumn], @descriptionAttributeClassName=[DescriptionAttributeClassName]
	FROM #Enum
	WHERE [Id]=@enumId;

	-- Member descriptions are only read when a description attribute class is configured
	-- and the configured column actually exists in the source enum table (a single mapping
	-- may match many tables and not all of them need to have the description column).
	IF @descriptionColumn IS NOT NULL AND @descriptionAttributeClassName IS NOT NULL
	BEGIN
		DECLARE @columnCount INT = 0;
		DECLARE @checkQuery NVARCHAR(1000) = N'SELECT @columnCount = COUNT(1) FROM ' + QUOTENAME(@dbName)
			+ N'.sys.columns c WHERE c.[object_id]=OBJECT_ID(@objectName) AND c.[name]=@columnName;';

		DECLARE @objectName NVARCHAR(500) = QUOTENAME(@dbName) + N'.' + QUOTENAME(@enumSchema) + N'.' + QUOTENAME(@enumTable);

		EXEC sp_executesql @checkQuery,
			N'@objectName NVARCHAR(500), @columnName NVARCHAR(128), @columnCount INT OUTPUT',
			@objectName=@objectName, @columnName=@descriptionColumn, @columnCount=@columnCount OUTPUT;

		IF @columnCount = 0
		BEGIN
			SET @descriptionColumn = NULL;
		END
	END
	ELSE
	BEGIN
		SET @descriptionColumn = NULL;
	END

    DECLARE @query NVARCHAR(4000);



	SET @query = N'USE ' + QUOTENAME(@dbName) + N';
	';
	SET @query += N'SELECT ' + LOWER(@enumId) + N' [EnumId], ' + QUOTENAME(@nameColumn) + N' [Name], ' + QUOTENAME(@valueColumn) + N' [Value], '
	SET @query += CASE WHEN @descriptionColumn IS NOT NULL THEN N'LEFT(' + QUOTENAME(@descriptionColumn) + N', 500)' ELSE N'CAST(NULL AS NVARCHAR(500))' END + N' [Description] '
	SET @query += N'FROM ' + QUOTENAME(@enumSchema) + N'.' + QUOTENAME(@enumTable) + N' '
	SET @query += N'ORDER BY ' + QUOTENAME(@valueColumn)
	SET @query += N';
	';
	--PRINT(@query);

	INSERT INTO #EnumVal ([EnumId], [Name], [Value], [Description])
	EXEC(@query);

END