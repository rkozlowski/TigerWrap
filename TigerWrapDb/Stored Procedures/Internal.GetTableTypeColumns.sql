


CREATE PROCEDURE [Internal].[GetTableTypeColumns]
    @projectId SMALLINT,
    @dbId SMALLINT,
    @langId TINYINT,
    @ttId INT,
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

    DECLARE @schema NVARCHAR(128);
    DECLARE @name NVARCHAR(128);

    DECLARE @pemId TINYINT;

    SELECT @pemId=[ParamEnumMappingId]      
    FROM [dbo].[Project]
    WHERE [Id]=@projectId;

    IF @pemId IS NULL
    BEGIN
        SELECT @rc = @RC_ERR_PROJECT, @errorMessage=N'Unknown project';
        RETURN @rc;
    END
    

    SELECT @name=[SqlType], @schema=[SqlTypeSchema]
    FROM #TableType
    WHERE [Id]=@ttId;

    IF @name IS NULL
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
    SET @query += N'SELECT ' + LOWER(@ttId) + N' [TableTypeId], c.[column_id] [ColumnId],  ROW_NUMBER() OVER (ORDER BY c.[column_id]) - 1 [ColumnNumber], c.[name] [Name], ';
    SET @query += N'c.is_nullable [IsNullable], t.[name] [SqlType], SCHEMA_NAME(t.schema_id) [SqlTypeSchema], '
    SET @query += N'c.[max_length] [MaxLen], c.[precision] [Precision], c.[scale] [Scale], c.[is_identity] [IsIdentity] '
    SET @query += N'FROM sys.table_types tt '
    SET @query += N'JOIN sys.columns c on c.object_id = tt.type_table_object_id '
    SET @query += N'JOIN sys.types t ON c.system_type_id=t.system_type_id AND c.system_type_id = t.user_type_id '
    SET @query += N'WHERE SCHEMA_NAME(tt.schema_id)=' + QUOTENAME(@schema, N'''') + N' AND tt.[name]=' + QUOTENAME(@name, N'''') + N' '
    SET @query += N'ORDER BY c.[column_id] '
    SET @query += N';
    ';
    --PRINT(@query);
    
    INSERT INTO #TableTypeColumn
    ([TableTypeId], [ColumnId], [ColumnNumber], [Name], [IsNullable], [SqlType], [SqlTypeSchema], [MaxLen], [Precision], [Scale], [IsIdentity])
    EXEC(@query);

    IF (@pemId IN (@PEM_ENUM_NAME, @PEM_ENUM_NAME_WITH_ID, @PEM_ENUM_NAME_WITH_OR_WITHOUT_ID))
    BEGIN
        UPDATE ttc
        SET ttc.[EnumId]=e.[Id]
        FROM #TableTypeColumn ttc
        JOIN #Enum e ON ttc.[SqlType]=e.[ValueType] 
        AND ((e.[EnumName]=[Internal].[RemoveFromStart](ttc.[Name], N'@') AND @pemId IN (@PEM_ENUM_NAME, @PEM_ENUM_NAME_WITH_OR_WITHOUT_ID)) 
        OR (ttc.[Name] LIKE N'%Id' AND e.[EnumName]=[Internal].[RemoveFromEnd]([Internal].[RemoveFromStart](ttc.[Name], N'@'), N'Id') AND @pemId IN (@PEM_ENUM_NAME_WITH_ID, @PEM_ENUM_NAME_WITH_OR_WITHOUT_ID)))
    END
    SET @rc=@RC_OK;
    RETURN @rc;
END