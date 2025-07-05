CREATE PROCEDURE [Internal].[GenerateCode]
    @projectId NVARCHAR(200),
	@dbId SMALLINT,
    @errorMessage NVARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE  @rc INT;

    DECLARE @RC_OK INT = 0;
	DECLARE @RC_DB_ERROR INT = 1;
	DECLARE @RC_INTERNAL_ERROR INT = 2;
    DECLARE @RC_ERR_UNKNOWN_PROJECT INT = 3;
    
    SELECT @rc = @RC_OK, @errorMessage = NULL;

	DECLARE @errorCode VARCHAR(100) = 'InternalError';

    DECLARE @OPT_GEN_ENUMS SMALLINT = 1;
    DECLARE @OPT_GEN_RESULT_TYPES SMALLINT = 2;
    DECLARE @OPT_GEN_TVP_TYPES SMALLINT = 4;
    DECLARE @OPT_GEN_SP_WRAPPERS SMALLINT = 8;

    DECLARE @C_PASCAL_CASE TINYINT = 1;
    DECLARE @C_CAMEL_CASE TINYINT = 2;
    DECLARE @C_SNAKE_CASE TINYINT = 3;
    DECLARE @C_UNDERSCORE_CAMEL_CASE TINYINT = 4;
    DECLARE @C_UPPER_SNAKE_CASE TINYINT = 5;

    DECLARE @NT_CLASS TINYINT = 1;
    DECLARE @NT_METHOD TINYINT = 2;
    DECLARE @NT_PROPERTY TINYINT = 3;
    DECLARE @NT_FIELD TINYINT = 4;
    DECLARE @NT_PARAMETER TINYINT = 5;
    DECLARE @NT_LOCAL_VARIABLE TINYINT = 6;
    DECLARE @NT_TUPLE_FIELD TINYINT = 7;
    DECLARE @NT_ENUM TINYINT = 8;
    DECLARE @NT_ENUM_MEMBER TINYINT = 9;

	DECLARE @NS_TABLE_NAME TINYINT = 1;
	DECLARE @NS_STORED_PROC_NAME TINYINT = 2;
	DECLARE @NS_TABLE_TYPE_NAME TINYINT = 3;

    DECLARE @langId TINYINT;
    
	SELECT @langId=[LanguageId]  FROM [dbo].[Project] WHERE [Id]=@projectId;

    IF @langId IS NULL 
    BEGIN
        SELECT @rc = @RC_ERR_UNKNOWN_PROJECT, @errorMessage = 'Unknown project: ' + ISNULL(LOWER(@projectId), '<NULL>');
        RETURN @rc;
    END;

    IF @dbId IS NULL 
    BEGIN
		SET @errorCode='InvalidDatabase';
		SELECT @rc=[Id], @errorMessage='Unknown database: ' + ISNULL(LOWER(@dbId), '<NULL>')
		FROM [Enum].[ToolkitResponseCode]
		WHERE [Name]=@errorCode;
        RETURN @rc;
    END;

    DROP TABLE IF EXISTS #Enum;
    CREATE TABLE #Enum
    (
        [Id] INT NOT NULL IDENTITY (1, 1) PRIMARY KEY,        
        [Schema] NVARCHAR(128) NOT NULL,
        [Table] NVARCHAR(128) NOT NULL,        
        [NameColumn] NVARCHAR(128) NOT NULL,
        [ValueColumn] NVARCHAR(128) NOT NULL,
        [EnumName] NVARCHAR(200) NULL,
        [ValueType] NVARCHAR(128) NOT NULL,
        [IsSetOfFlags] BIT NOT NULL DEFAULT (0),
        UNIQUE ([Schema], [Table])
    );

    DROP TABLE IF EXISTS #EnumVal;
    CREATE TABLE #EnumVal
    (
        [Id] INT NOT NULL IDENTITY (1, 1) PRIMARY KEY,        
        [EnumId] INT NOT NULL,        
        [Name] VARCHAR(200) NOT NULL,
        [Value] BIGINT NOT NULL,     
		[TempName] VARCHAR(200) NULL,
        UNIQUE ([EnumId], [Name]),
        UNIQUE ([EnumId], [Value]),
		UNIQUE ([EnumId], [TempName], [Value])
    );

    DROP TABLE IF EXISTS #EnumForeignKey;
    CREATE TABLE #EnumForeignKey
    (
        [Id] INT NOT NULL IDENTITY (1, 1) PRIMARY KEY,        
        [EnumId] INT NOT NULL,
        [ForeignSchema] NVARCHAR(128) NOT NULL,
        [ForeignTable] NVARCHAR(128) NOT NULL,
        [ForeignColumn] NVARCHAR(128) NOT NULL,        
        UNIQUE ([EnumId], [ForeignSchema], [ForeignTable], [ForeignColumn]),
        UNIQUE ([ForeignSchema], [ForeignTable], [ForeignColumn])        
    );

    DROP TABLE IF EXISTS #StoredProc;
    CREATE TABLE #StoredProc 
    (
        [Id] INT NOT NULL IDENTITY (1, 1) PRIMARY KEY,
        [Schema] NVARCHAR(128) NOT NULL, 
        [Name] NVARCHAR(128) NOT NULL,
        [WrapperName] NVARCHAR(200) NULL,
        [HasResultSet] BIT NOT NULL DEFAULT (0),
        [HasUnknownResultSet] BIT NOT NULL DEFAULT (0),
        [ResultType] NVARCHAR(200) NOT NULL DEFAULT(N'int'),
        [LanguageOptionsReset] BIGINT NULL,
        [LanguageOptionsSet] BIGINT NULL,
        UNIQUE ([Schema], [Name])
    );

    DROP TABLE IF EXISTS #StoredProcParam;
    CREATE TABLE #StoredProcParam
    (
        [Id] INT NOT NULL IDENTITY (1, 1) PRIMARY KEY,
        [StoredProcId] INT NOT NULL,
        [ParamId] INT NOT NULL, 
        [Name] NVARCHAR(128) NOT NULL, 
        [SqlType] NVARCHAR(128) NOT NULL, 
        [SqlTypeSchema] NVARCHAR(128) NOT NULL, 
        [MaxLen] SMALLINT NOT NULL, 
        [Precision] TINYINT NOT NULL, 
        [Scale] TINYINT NOT NULL, 
        [IsOutput] BIT NOT NULL, 
        [IsReadOnly] BIT NOT NULL, 
        [IsTypeUserDefined] BIT NOT NULL, 
        [IsTableType] BIT NOT NULL,
        [EnumId] INT NULL,
        [ParamName]  NVARCHAR(200) NULL,
        UNIQUE ([StoredProcId], [ParamId]),
        UNIQUE ([StoredProcId], [Name])
    );

    DROP TABLE IF EXISTS #SingleStoredProcResultSet;
    CREATE TABLE #SingleStoredProcResultSet (
        [is_hidden] BIT NULL,
        [column_ordinal] INT NULL,
        [name] SYSNAME NULL,
        [is_nullable] BIT NULL,
        [system_type_id] INT NULL,
        [system_type_name] NVARCHAR(256) NULL,
        [max_length] SMALLINT NULL,
        [precision] TINYINT NULL,
        [scale] TINYINT NULL,
        [collation_name] SYSNAME NULL,
        [user_type_id] INT NULL,
        [user_type_database] SYSNAME NULL,
        [user_type_schema] SYSNAME NULL,
        [user_type_name] SYSNAME NULL,
        [assembly_qualified_type_name] NVARCHAR(4000),
        [xml_collection_id] INT NULL,
        [xml_collection_database] SYSNAME NULL,
        [xml_collection_schema] SYSNAME NULL,
        [xml_collection_name] SYSNAME NULL,
        [is_xml_document] BIT NULL,
        [is_case_sensitive] BIT NULL,
        [is_fixed_length_clr_type] BIT NULL,
        [source_server] SYSNAME NULL,
        [source_database] SYSNAME NULL,
        [source_schema] SYSNAME NULL,
        [source_table] SYSNAME NULL,
        [source_column] SYSNAME NULL,
        [is_identity_column] BIT NULL,
        [is_part_of_unique_key] BIT NULL,
        [is_updateable] BIT NULL,
        [is_computed_column] BIT NULL,
        [is_sparse_column_set] BIT NULL,
        [ordinal_in_order_by_list] SMALLINT NULL,
        [order_by_list_length] SMALLINT NULL,
        [order_by_is_descending] SMALLINT NULL,
        /*
        [tds_type_id] INT NOT NULL,
        [tds_length] INT NOT NULL,
        [tds_collation_id] INT NULL,
        [tds_collation_sort_id] TINYINT NULL
        */
        [error_number] INT NULL,
        [error_severity] INT NULL,
        [error_state] INT NULL,
        [error_message] NVARCHAR(MAX) NULL,
        [error_type] INT NULL,
        [error_type_desc] NVARCHAR(60) NULL
    );

    DROP TABLE IF EXISTS #StoredProcResultSet;
    CREATE TABLE #StoredProcResultSet (
        [Id] INT NOT NULL IDENTITY (1, 1) PRIMARY KEY,
        [StoredProcId] INT NOT NULL,
        [ColumnOrdinal] INT NOT NULL,
        [Name] SYSNAME NULL,
        [IsNullable] BIT NOT NULL,
        [SqlType] NVARCHAR(128) NOT NULL, 
        [SqlTypeSchema] NVARCHAR(128) NOT NULL, 
        [MaxLen] SMALLINT NOT NULL, 
        [Precision] TINYINT NOT NULL, 
        [Scale] TINYINT NOT NULL,
        [EnumId] INT NULL,
		[PropertyName] NVARCHAR(200) NULL,
        UNIQUE ([StoredProcId], [ColumnOrdinal]),		
        UNIQUE ([StoredProcId], [PropertyName], [ColumnOrdinal])
    );

    DROP TABLE IF EXISTS #StoredProcResultType;
    CREATE TABLE #StoredProcResultType
    (
        [Id] INT NOT NULL IDENTITY (1, 1) PRIMARY KEY,
        [StoredProcId] INT NOT NULL UNIQUE,
        [Name] NVARCHAR(200) NOT NULL UNIQUE
    );

    DROP TABLE IF EXISTS #TableType;
    CREATE TABLE #TableType
    (
        [Id] INT NOT NULL IDENTITY (1, 1) PRIMARY KEY,
        [SqlType] NVARCHAR(128) NOT NULL, 
        [SqlTypeSchema] NVARCHAR(128) NOT NULL,
        [Name] NVARCHAR(200) NOT NULL UNIQUE,
        UNIQUE ([SqlType], [SqlTypeSchema])
    );

    DROP TABLE IF EXISTS #TableTypeColumn;
    CREATE TABLE #TableTypeColumn
    (
        [Id] INT NOT NULL IDENTITY (1, 1) PRIMARY KEY,
        [TableTypeId] INT NOT NULL,
        [ColumnId] INT NOT NULL,
        [ColumnNumber] INT NOT NULL,
        [Name] SYSNAME NULL,
        [IsNullable] BIT NOT NULL,
        [SqlType] NVARCHAR(128) NOT NULL, 
        [SqlTypeSchema] NVARCHAR(128) NOT NULL, 
        [MaxLen] SMALLINT NOT NULL, 
        [Precision] TINYINT NOT NULL, 
        [Scale] TINYINT NOT NULL,
        [IsIdentity] BIT NOT NULL,
        [EnumId] INT NULL,
        [PropertyName] NVARCHAR(200) NULL
    );

    DECLARE    @retVal int;
    
    
    EXEC @retVal = [Internal].[GetEnums] @projectId = @projectId, @dbId = @dbId, @langId = @langId, @errorMessage = @errorMessage OUTPUT;
    IF @retVal<>0
    BEGIN
        SELECT @rc = @retVal;
        RETURN @rc;
    END
	DECLARE @hasDuplicates BIT = 0;
	DECLARE @dupNo INT = 1;

    UPDATE #Enum SET [EnumName]=[Internal].[GetNameEx](@projectId, @NT_ENUM, @NS_TABLE_NAME, [Table], [Schema]);
	SELECT @hasDuplicates = CASE WHEN EXISTS (SELECT 1 FROM #Enum e1 JOIN #Enum e2 ON e1.[EnumName]=e2.[EnumName] AND e1.[Id]>e2.[Id]) THEN 1 ELSE 0 END;
	SET @dupNo = 1;
	WHILE @hasDuplicates=1 AND @dupNo < 20
	BEGIN
		UPDATE e2
		SET e2.[EnumName] = [Internal].[GetName](@projectId, @NT_ENUM, e2.[EnumName] + LOWER(@dupNo), NULL)
		FROM #Enum e1 
		JOIN #Enum e2 ON e1.[EnumName]=e2.[EnumName] AND e1.[Id]<e2.[Id]
		LEFT JOIN #Enum ex ON e1.[EnumName]=ex.[EnumName] AND e1.[Id]>ex.[Id]
		WHERE ex.[Id] IS NULL;

		SELECT @hasDuplicates = CASE WHEN EXISTS (SELECT 1 FROM #Enum e1 JOIN #Enum e2 ON e1.[EnumName]=e2.[EnumName] AND e1.[Id]>e2.[Id]) THEN 1 ELSE 0 END;
		SET @dupNo += 1;
	END

    DECLARE @id INT = (SELECT MIN([Id]) FROM #Enum);
    
    WHILE @id IS NOT NULL
    BEGIN
        EXEC @retVal = [Internal].[GetEnumValues] @projectId = @projectId, @dbId = @dbId, @langId = @langId, @enumId = @id, @errorMessage = @errorMessage OUTPUT;
        IF @retVal<>0
        BEGIN
            SELECT @rc = @retVal;
            RETURN @rc;
        END

        EXEC @retVal = [Internal].[GetEnumForeignKeys] @projectId = @projectId, @dbId = @dbId, @langId = @langId, @enumId = @id, @errorMessage = @errorMessage OUTPUT;
        IF @retVal<>0
        BEGIN
            SELECT @rc = @retVal;
            RETURN @rc;
        END
        

        SELECT @id = MIN([Id]) FROM #Enum WHERE [Id]>@id;
    END


	UPDATE #EnumVal SET [TempName]=[Internal].[GetName](@projectId, @NT_ENUM_MEMBER, [Name], NULL);
	
	SELECT @hasDuplicates = CASE WHEN EXISTS (SELECT 1 FROM #EnumVal v1 JOIN #EnumVal v2 ON v1.[EnumId]=v2.[EnumId] AND v1.[TempName]=v2.[TempName] AND v1.[Id]>v2.[Id]) THEN 1 ELSE 0 END;
	SET @dupNo = 1;
	WHILE @hasDuplicates=1 AND @dupNo < 20
	BEGIN
		UPDATE v2
		SET v2.[TempName] = [Internal].[GetName](@projectId, @NT_ENUM_MEMBER, v2.[TempName] + LOWER(@dupNo), NULL)
		FROM #EnumVal v1 
		JOIN #EnumVal v2 ON v1.[EnumId]=v2.[EnumId] AND v1.[TempName]=v2.[TempName] AND v1.[Id]<v2.[Id]
		LEFT JOIN #EnumVal vx ON v1.[EnumId]=vx.[EnumId] AND v1.[TempName]=vx.[TempName] AND v1.[Id]>vx.[Id]
		WHERE vx.[Id] IS NULL;

		SELECT @hasDuplicates = CASE WHEN EXISTS (SELECT 1 FROM #EnumVal v1 JOIN #EnumVal v2 ON v1.[EnumId]=v2.[EnumId] AND v1.[TempName]=v2.[TempName] AND v1.[Id]>v2.[Id]) THEN 1 ELSE 0 END;		
		SET @dupNo += 1;
	END

	UPDATE #EnumVal SET [Name]=[TempName];

    /*
    SELECT e.[Schema], e.[Table], e.[EnumName], fk.*
    FROM #Enum e
    JOIN #EnumForeignKey fk ON fk.[EnumId]=e.[Id]
    ORDER BY e.[Id], fk.[Id];
    */

    EXEC @retVal = [Internal].[GetStoredProcedures] @projectId = @projectId, @dbId = @dbId, @langId = @langId, @errorMessage = @errorMessage OUTPUT;
    IF @retVal<>0
    BEGIN
        SELECT @rc = @retVal;
        RETURN @rc;
    END

    SELECT @id=MIN([Id]) FROM #StoredProc;
    
    WHILE @id IS NOT NULL
    BEGIN
        EXEC @retVal = [Internal].[GetStoredProcParams] @projectId = @projectId, @dbId = @dbId, @langId = @langId, @spId = @id, @errorMessage = @errorMessage OUTPUT;
        IF @retVal<>0
        BEGIN
            SELECT @rc = @retVal;
            RETURN @rc;
        END
        
        EXEC @retVal = [Internal].[GetStoredProcResultSet] @projectId = @projectId, @dbId = @dbId, @langId = @langId, @spId = @id, @errorMessage = @errorMessage OUTPUT;
        IF @retVal<>0
        BEGIN
            SELECT @rc = @retVal;
            RETURN @rc;
        END

        SELECT @id = MIN([Id]) FROM #StoredProc WHERE [Id]>@id;
    END

    UPDATE #StoredProc SET [WrapperName]=[Internal].[GetNameEx](@projectId, @NT_METHOD, @NS_STORED_PROC_NAME, [Name], [Schema]);

	SELECT @hasDuplicates = CASE WHEN EXISTS (SELECT 1 FROM #StoredProc p1 JOIN #StoredProc p2 ON p1.[WrapperName]=p2.[WrapperName] AND p1.[Id]<p2.[Id]) THEN 1 ELSE 0 END;
	SET @dupNo = 1;
	WHILE @hasDuplicates=1 AND @dupNo < 20
	BEGIN
		UPDATE p2
		SET p2.[WrapperName] = [Internal].[GetName](@projectId, @NT_METHOD, p2.[WrapperName] + LOWER(@dupNo), NULL)
		FROM #StoredProc p1 
		JOIN #StoredProc p2 ON p1.[WrapperName]=p2.[WrapperName] AND p1.[Id]<p2.[Id]
		LEFT JOIN #StoredProc px ON p1.[WrapperName]=px.[WrapperName] AND p1.[Id]>px.[Id]
		WHERE px.[Id] IS NULL;

		SELECT @hasDuplicates = CASE WHEN EXISTS (SELECT 1 FROM #StoredProc p1 JOIN #StoredProc p2 ON p1.[WrapperName]=p2.[WrapperName] AND p1.[Id]<p2.[Id]) THEN 1 ELSE 0 END;
		SET @dupNo += 1;
	END


    UPDATE sp
    SET sp.[HasResultSet]=1, sp.[ResultType]=[Internal].[GetName](@projectId, @NT_CLASS, sp.[WrapperName] + N'Result', NULL)
    FROM #StoredProc sp
    WHERE EXISTS (SELECT 1 FROM #StoredProcResultSet rs WHERE rs.[StoredProcId]=sp.[Id]);

    UPDATE sp
    SET sp.[HasResultSet]=1, sp.[ResultType]=N'dynamic'
    FROM #StoredProc sp
    WHERE sp.[HasResultSet]=0 AND sp.[HasUnknownResultSet]=1;


	UPDATE rs
	SET rs.[PropertyName]=[Internal].[GetName](@projectId, @NT_PROPERTY, rs.[Name], NULL)
	FROM #StoredProcResultSet rs;

	SELECT @hasDuplicates = CASE WHEN EXISTS (
		SELECT 1 FROM #StoredProcResultSet rs1 JOIN #StoredProcResultSet rs2 ON rs1.[StoredProcId]=rs2.[StoredProcId] AND rs1.[PropertyName]=rs2.[PropertyName] AND rs1.[Id]<rs2.[Id]
	) THEN 1 ELSE 0 END;
	SET @dupNo = 1;
	WHILE @hasDuplicates=1 AND @dupNo < 20
	BEGIN
		UPDATE rs2
		SET rs2.[PropertyName] = [Internal].[GetName](@projectId, @NT_PROPERTY, rs2.[PropertyName] + LOWER(@dupNo), NULL)
		FROM #StoredProcResultSet rs1 
		JOIN #StoredProcResultSet rs2 ON rs1.[StoredProcId]=rs2.[StoredProcId] AND rs1.[PropertyName]=rs2.[PropertyName] AND rs1.[Id]<rs2.[Id]
		LEFT JOIN #StoredProcResultSet rsx ON rs1.[StoredProcId]=rsx.[StoredProcId] AND rs1.[PropertyName]=rsx.[PropertyName] AND rs1.[Id]>rsx.[Id]		
		WHERE rsx.[Id] IS NULL;

		SELECT @hasDuplicates = CASE WHEN EXISTS (
			SELECT 1 FROM #StoredProcResultSet rs1 JOIN #StoredProcResultSet rs2 ON rs1.[StoredProcId]=rs2.[StoredProcId] AND rs1.[PropertyName]=rs2.[PropertyName] AND rs1.[Id]<rs2.[Id]
		) THEN 1 ELSE 0 END;
		SET @dupNo += 1;
	END

    
    INSERT INTO #StoredProcResultType ([StoredProcId], [Name])
    SELECT [Id], [ResultType]
    FROM #StoredProc
    WHERE [HasResultSet]=1 AND [HasUnknownResultSet]=0;

    UPDATE #StoredProcParam SET [ParamName]=[Internal].[GetName](@projectId, @NT_PARAMETER, [Name], NULL);
	
	SELECT @hasDuplicates = CASE WHEN EXISTS (
		SELECT 1 FROM #StoredProcParam p1 JOIN #StoredProcParam p2 ON p1.[StoredProcId]=p2.[StoredProcId] AND p1.[ParamName]=p2.[ParamName] AND p1.[Id]<p2.[Id]
	) THEN 1 ELSE 0 END;
	SET @dupNo = 1;
	WHILE @hasDuplicates=1 AND @dupNo < 20
	BEGIN
		UPDATE p2
		SET p2.[ParamName] = [Internal].[GetName](@projectId, @NT_PARAMETER, p2.[ParamName] + LOWER(@dupNo), NULL)
		FROM #StoredProcParam p1 
		JOIN #StoredProcParam p2 ON p1.[StoredProcId]=p2.[StoredProcId] AND p1.[ParamName]=p2.[ParamName] AND p1.[Id]<p2.[Id]
		LEFT JOIN #StoredProcParam px ON p1.[StoredProcId]=px.[StoredProcId] AND p1.[ParamName]=px.[ParamName] AND p1.[Id]>px.[Id]		
		WHERE px.[Id] IS NULL;

		SELECT @hasDuplicates = CASE WHEN EXISTS (
			SELECT 1 FROM #StoredProcParam p1 JOIN #StoredProcParam p2 ON p1.[StoredProcId]=p2.[StoredProcId] AND p1.[ParamName]=p2.[ParamName] AND p1.[Id]<p2.[Id]
		) THEN 1 ELSE 0 END;
		SET @dupNo += 1;
	END


    INSERT INTO #TableType ([SqlType], [SqlTypeSchema], [Name])
    SELECT DISTINCT spp.[SqlType], spp.[SqlTypeSchema], [Internal].[GetNameEx](@projectId, @NT_CLASS, @NS_TABLE_TYPE_NAME, spp.[SqlType], spp.[SqlTypeSchema])
    FROM #StoredProcParam spp
    WHERE spp.[IsTypeUserDefined]=1 AND spp.IsTableType=1;

	SELECT @hasDuplicates = CASE WHEN EXISTS (SELECT 1 FROM #TableType t1 JOIN #TableType t2 ON t1.[Name]=t2.[Name] AND t1.[Id]<t2.[Id]) THEN 1 ELSE 0 END;
	SET @dupNo = 1;
	WHILE @hasDuplicates=1 AND @dupNo < 20
	BEGIN
		UPDATE t2
		SET t2.[Name] = [Internal].[GetName](@projectId, @NT_CLASS, t2.[Name] + LOWER(@dupNo), NULL)
		FROM #TableType t1 
		JOIN #TableType t2 ON t1.[Name]=t2.[Name] AND t1.[Id]<t2.[Id]
		LEFT JOIN #TableType tx ON t1.[Name]=tx.[Name] AND t1.[Id]>tx.[Id]
		WHERE tx.[Id] IS NULL;

		SELECT @hasDuplicates = CASE WHEN EXISTS (SELECT 1 FROM #TableType t1 JOIN #TableType t2 ON t1.[Name]=t2.[Name] AND t1.[Id]<t2.[Id]) THEN 1 ELSE 0 END;
		SET @dupNo += 1;
	END

    SELECT @id=MIN([Id]) FROM #TableType;
    
    WHILE @id IS NOT NULL
    BEGIN
        EXEC @retVal = [Internal].[GetTableTypeColumns] @projectId = @projectId, @dbId = @dbId, @langId = @langId, @ttId = @id, @errorMessage = @errorMessage OUTPUT;
        IF @retVal<>0
        BEGIN
            SELECT @rc = @retVal;
            RETURN @rc;
        END
        
        SELECT @id = MIN([Id]) FROM #TableType WHERE [Id]>@id;
    END

    UPDATE #TableTypeColumn
    SET [PropertyName]=[Internal].[GetName](@projectId, @NT_PROPERTY, [Name], NULL);

	SELECT @hasDuplicates = CASE WHEN EXISTS (
		SELECT 1 FROM #TableTypeColumn c1 JOIN #TableTypeColumn c2 ON c1.[TableTypeId]=c2.[TableTypeId] AND c1.[PropertyName]=c2.[PropertyName] AND c1.[Id]<c2.[Id]
	) THEN 1 ELSE 0 END;
	SET @dupNo = 1;
	WHILE @hasDuplicates=1 AND @dupNo < 20
	BEGIN
		UPDATE c2
		SET c2.[PropertyName] = [Internal].[GetName](@projectId, @NT_PROPERTY, c2.[PropertyName] + LOWER(@dupNo), NULL)
		FROM #TableTypeColumn c1 
		JOIN #TableTypeColumn c2 ON c1.[TableTypeId]=c2.[TableTypeId] AND c1.[PropertyName]=c2.[PropertyName] AND c1.[Id]<c2.[Id]
		LEFT JOIN #TableTypeColumn cx ON c1.[TableTypeId]=cx.[TableTypeId] AND c1.[PropertyName]=cx.[PropertyName] AND c1.[Id]>cx.[Id]		
		WHERE cx.[Id] IS NULL;

		SELECT @hasDuplicates = CASE WHEN EXISTS (
			SELECT 1 FROM #TableTypeColumn c1 JOIN #TableTypeColumn c2 ON c1.[TableTypeId]=c2.[TableTypeId] AND c1.[PropertyName]=c2.[PropertyName] AND c1.[Id]<c2.[Id]
		) THEN 1 ELSE 0 END;
		SET @dupNo += 1;
	END

    --SELECT * FROM #Enum ORDER BY [Id];
    --SELECT * FROM #EnumVal ORDER BY [Id];
    --SELECT * FROM #StoredProc ORDER BY [Id];
    --SELECT * FROM #StoredProcParam ORDER BY [Id];
    --SELECT * FROM #StoredProcResultSet ORDER BY [Id];
    --SELECT * FROM #TableType;
    --SELECT * FROM #TableTypeColumn ORDER BY [Id];

    EXECUTE @retVal = [Internal].[GenerateStartCode] @projectId = @projectId, @dbId = @dbId, @langId = @langId, @errorMessage = @errorMessage OUTPUT;
    IF @retVal<>0
    BEGIN
        SELECT @rc = @retVal;
        RETURN @rc;
    END

    
    SELECT @id=MIN([Id]) FROM #Enum;
    WHILE @id IS NOT NULL
    BEGIN
		EXEC @retVal = [Internal].[GenerateEnumCode] @projectId = @projectId, @dbId = @dbId, @langId = @langId, @enumId = @id, @errorMessage = @errorMessage OUTPUT;
		IF @retVal<>0
		BEGIN
			SELECT @rc = @retVal;
			RETURN @rc;
		END
		SELECT @id=MIN([Id]) FROM #Enum WHERE [Id] > @id;
    END
    

    
    SELECT @id=MIN([Id]) FROM #StoredProcResultType;
    WHILE @id IS NOT NULL
    BEGIN
		EXEC @retVal = [Internal].[GenerateResultTypeCode] @projectId = @projectId, @dbId = @dbId, @langId = @langId, @rtId = @id, @errorMessage = @errorMessage OUTPUT;
		IF @retVal<>0
		BEGIN
			SELECT @rc = @retVal;
			RETURN @rc;
		END
		SELECT @id=MIN([Id]) FROM #StoredProcResultType WHERE [Id] > @id;
    END

	SELECT @id=MIN([Id]) FROM #TableType;
    WHILE @id IS NOT NULL
    BEGIN
		EXEC @retVal = [Internal].[GenerateTableTypeCode] @projectId = @projectId, @dbId = @dbId, @langId = @langId, @ttId = @id, @errorMessage = @errorMessage OUTPUT;
		IF @retVal<>0
		BEGIN
			SELECT @rc = @retVal;
			RETURN @rc;
		END
		SELECT @id=MIN([Id]) FROM #TableType WHERE [Id] > @id;
    END

    SELECT @id=MIN([Id]) FROM #StoredProc;
    WHILE @id IS NOT NULL
    BEGIN
		EXEC @retVal = [Internal].[GenerateStoredProcWrapperCode] @projectId = @projectId, @dbId = @dbId, @langId = @langId, @spId = @id, @errorMessage = @errorMessage OUTPUT;
		IF @retVal<>0
		BEGIN
			SELECT @rc = @retVal;
			RETURN @rc;
		END
		SELECT @id=MIN([Id]) FROM #StoredProc WHERE [Id] > @id;
    END
    
    EXECUTE @retVal = [Internal].[GenerateEndCode] @projectId = @projectId, @dbId = @dbId, @langId = @langId, @errorMessage = @errorMessage OUTPUT;
    IF @retVal<>0
    BEGIN
        SELECT @rc = @retVal;
        RETURN @rc;
    END
        
    DROP TABLE IF EXISTS #Enum;
    DROP TABLE IF EXISTS #EnumVal;
    DROP TABLE IF EXISTS #StoredProc;
    DROP TABLE IF EXISTS #StoredProcParam;
    DROP TABLE IF EXISTS #SingleStoredProcResultSet;
    DROP TABLE IF EXISTS #EnumForeignKey;
    DROP TABLE IF EXISTS #StoredProcResultType;
    DROP TABLE IF EXISTS #TableType;
    DROP TABLE IF EXISTS #TableTypeColumn;

    SET @rc = @RC_OK;
    RETURN @rc;
END