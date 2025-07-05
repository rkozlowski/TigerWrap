

CREATE PROCEDURE [Internal].[GetStoredProcParams]
	@projectId SMALLINT,
	@dbId SMALLINT,
	@langId TINYINT,
	@spId INT,
	@errorMessage NVARCHAR(2000) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rc INT;

	DECLARE @RC_OK INT = 0;
	DECLARE @RC_ERR_PROJECT INT = 21;
	DECLARE @RC_ERR_DB INT = 22;
	DECLARE @RC_ERR_LANG INT = 23;

	DECLARE @PEM_EXPLICIT_ONLY TINYINT = 1;
	DECLARE @PEM_ENUM_NAME TINYINT = 2;
	DECLARE @PEM_ENUM_NAME_WITH_ID TINYINT = 3;
	DECLARE @PEM_ENUM_NAME_WITH_OR_WITHOUT_ID TINYINT = 4;

	DECLARE @spSchema NVARCHAR(128);
	DECLARE @spName NVARCHAR(128);

	DECLARE @pemId TINYINT;

	SELECT @pemId=[ParamEnumMappingId]      
	FROM [dbo].[Project]
	WHERE [Id]=@projectId;

	IF @pemId IS NULL
	BEGIN
		SELECT @rc = @RC_ERR_PROJECT, @errorMessage=N'Unknown project';
		RETURN @rc;
	END
	

	SELECT @spSchema=[Schema], @spName=[Name]
	FROM #StoredProc
	WHERE [Id]=@spId;

	IF @spSchema IS NULL
	BEGIN
		SELECT @rc = @RC_ERR_PROJECT, @errorMessage=N'Unknown project or unsupported project options';
		RETURN @rc;
	END

	DECLARE @dbName NVARCHAR(128) = DB_NAME(@dbId);

	IF @dbName IS NULL
	BEGIN
		SELECT @rc = @RC_ERR_DB, @errorMessage=N'Database not found';
		RETURN @rc;
	END

    DECLARE @query NVARCHAR(4000);

	

	SET @query = N'USE ' + QUOTENAME(@dbName) + N';
	';
	SET @query += N'SELECT ' + LOWER(@spId) + N' [StoredProcId], p.[parameter_id] [ParamId], p.[name] [Name], t.[name] [SqlType], SCHEMA_NAME(t.schema_id) [SqlTypeSchema], '
	SET @query += N'p.[max_length] [MaxLen], p.[precision] [Precision], p.[scale] [Scale], p.[is_output] [IsOutput], p.[is_readonly] [IsReadOnly], '
	SET @query += N't.[is_user_defined] [IsTypeUserDefined], t.[is_table_type] [IsTableType] '
	SET @query += N'FROM sys.procedures sp '
	SET @query += N'JOIN sys.parameters p ON p.[object_id]=sp.[object_id] '
	SET @query += N'JOIN sys.types t ON p.[user_type_id]=t.[user_type_id] '
	SET @query += N'WHERE sp.[Type]=''P'' '
	SET @query += N'AND SCHEMA_NAME(sp.schema_id)=' + QUOTENAME(@spSchema, N'''') + N' AND sp.[name]=' + QUOTENAME(@spName, N'''') + N' '
	SET @query += N'ORDER BY p.[parameter_id] '
	SET @query += N';
	';
	--PRINT(@query);
	
	INSERT INTO #StoredProcParam ([StoredProcId], [ParamId], [Name], [SqlType], [SqlTypeSchema], [MaxLen], [Precision], [Scale], [IsOutput], [IsReadOnly], [IsTypeUserDefined], [IsTableType])
	EXEC(@query);

	IF (@pemId IN (@PEM_ENUM_NAME, @PEM_ENUM_NAME_WITH_ID, @PEM_ENUM_NAME_WITH_OR_WITHOUT_ID))
	BEGIN
		UPDATE spp
		SET spp.[EnumId]=e.[Id]
		FROM #StoredProcParam spp
		JOIN #Enum e ON spp.[SqlType]=e.[ValueType] 
		AND ((e.[EnumName]=[Internal].[RemoveFromStart](spp.[Name], N'@') AND @pemId IN (@PEM_ENUM_NAME, @PEM_ENUM_NAME_WITH_OR_WITHOUT_ID)) 
		OR (spp.[Name] LIKE N'%Id' AND e.[EnumName]=[Internal].[RemoveFromEnd]([Internal].[RemoveFromStart](spp.[Name], N'@'), N'Id') AND @pemId IN (@PEM_ENUM_NAME_WITH_ID, @PEM_ENUM_NAME_WITH_OR_WITHOUT_ID)))
	END
	SET @rc=@RC_OK;
	RETURN @rc;
END