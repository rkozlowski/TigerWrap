
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

	SELECT @enumSchema=[Schema], @enumTable=[Table], @nameColumn=[NameColumn], @valueColumn=[ValueColumn]
	FROM #Enum
	WHERE [Id]=@enumId;

    DECLARE @query NVARCHAR(4000);

	

	SET @query = N'USE ' + QUOTENAME(@dbName) + N';
	';
	SET @query += N'SELECT ' + LOWER(@enumId) + N' [EnumId], ' + QUOTENAME(@nameColumn) + N' [Name], ' + QUOTENAME(@valueColumn) + N' [Value] ' 
	SET @query += N'FROM ' + QUOTENAME(@enumSchema) + N'.' + QUOTENAME(@enumTable) + N' '
	SET @query += N'ORDER BY ' + QUOTENAME(@valueColumn)
	SET @query += N';
	';
	--PRINT(@query);
	
	INSERT INTO #EnumVal ([EnumId], [Name], [Value])
	EXEC(@query);

END