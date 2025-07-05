


CREATE PROCEDURE [Internal].[GenerateResultTypeCode]
	@projectId SMALLINT,
	@dbId SMALLINT,
	@langId TINYINT,
	@rtId INT,
	@errorMessage NVARCHAR(2000) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rc INT;

	DECLARE @RC_OK INT = 0;
	
	DECLARE @errorCode VARCHAR(100) = 'InternalError';

	DECLARE @codePartId TINYINT = (SELECT [Id] FROM [Enum].[CodePart] WHERE [Name]='ResultTypes');

	DECLARE @TT_RESULT_TYPE_START TINYINT = 6;
	DECLARE @TT_RESULT_TYPE_END TINYINT = 7;
	DECLARE @TT_RESULT_TYPE_PROPERTY TINYINT = 8;

	DECLARE @NT_CLASS TINYINT = 1;
	DECLARE @NT_METHOD TINYINT = 2;
	DECLARE @NT_PROPERTY TINYINT = 3;
	DECLARE @NT_FIELD TINYINT = 4;
	DECLARE @NT_PARAMETER TINYINT = 5;
	DECLARE @NT_LOCAL_VARIABLE TINYINT = 6;
	DECLARE @NT_TUPLE_FIELD TINYINT = 7;
	DECLARE @NT_ENUM TINYINT = 8;
	DECLARE @NT_ENUM_MEMBER TINYINT = 9;

	DECLARE @spId INT;
	DECLARE @typeName NVARCHAR(200);
	DECLARE @spSchema NVARCHAR(128);
	DECLARE @spName NVARCHAR(128);

	DECLARE @className NVARCHAR(100);
	DECLARE @langOptions BIGINT;

	SELECT @className=p.[ClassName], @langOptions=p.[LanguageOptions]
	FROM [dbo].[Project] p
	JOIN [Enum].[ClassAccess] ca ON p.[ClassAccessId]=ca.[Id]
	WHERE p.[Id]=@projectId;

	IF @className IS NULL
	BEGIN
		SET @errorCode='UnknownProject';
		SELECT @rc=[Id], @errorMessage=[Description]
		FROM [Enum].[ToolkitResponseCode]
		WHERE [Name]=@errorCode;
		RETURN @rc;
	END

	SELECT @spId=rt.[StoredProcId], @typeName=rt.[Name], @spSchema=sp.[Schema], @spName=sp.[Name]
	FROM #StoredProcResultType rt
	JOIN #StoredProc sp ON rt.[StoredProcId]=sp.[Id]
	WHERE rt.[Id]=@rtId;

	IF @typeName IS NULL
	BEGIN		
		SET @errorCode='UnknownResultType';
		SELECT @rc=[Id], @errorMessage=[Description]
		FROM [Enum].[ToolkitResponseCode]
		WHERE [Name]=@errorCode;
		RETURN @rc;
	END

	DECLARE @dbName NVARCHAR(128) = DB_NAME(@dbId);

	IF @dbName IS NULL
	BEGIN
		SET @errorCode='InvalidDatabase';
		SELECT @rc=[Id], @errorMessage=[Description]
		FROM [Enum].[ToolkitResponseCode]
		WHERE [Name]=@errorCode;
        RETURN @rc;
	END

    

	DECLARE @vars [Internal].[Variable];
	INSERT INTO @vars ([Name], [Value]) VALUES (N'ClassName', @typeName);
	INSERT INTO @vars ([Name], [Value]) VALUES (N'SpSchema', [Internal].[EscapeString](@langId, QUOTENAME(@spSchema)));
	INSERT INTO @vars ([Name], [Value]) VALUES (N'SpName', [Internal].[EscapeString](@langId, QUOTENAME(@spName)));
	
	INSERT INTO @vars ([Name], [Value]) VALUES (N'ClassAccess', N'public');
	INSERT INTO @vars ([Name], [Value]) VALUES (N'PropertyAccess', N'public');
	INSERT INTO @vars ([Name], [Value]) VALUES (N'Type', NULL);
	INSERT INTO @vars ([Name], [Value]) VALUES (N'Name', NULL);
	INSERT INTO @vars ([Name], [Value]) VALUES (N'ColumnName', NULL);
	INSERT INTO @vars ([Name], [Value]) VALUES (N'Sep', N',');
	


	INSERT INTO #Output ([CodePartId], [Schema],  [Text])
	SELECT @codePartId, @spSchema, c.[Text]
	FROM [Static].[Template] t
	CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
	WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, @TT_RESULT_TYPE_START)
	ORDER BY c.[Id];

	DECLARE @id INT = (SELECT MIN([Id]) FROM #StoredProcResultSet WHERE [StoredProcId]=@spId);
	DECLARE @lastId INT = (SELECT MAX([Id]) FROM #StoredProcResultSet WHERE [StoredProcId]=@spId);
	DECLARE @name NVARCHAR(128);
	DECLARE @columnName NVARCHAR(128);
	DECLARE @type NVARCHAR(100);

	WHILE @id IS NOT NULL
	BEGIN		
		SELECT @columnName=[Internal].[EscapeString](@langId, rs.[Name]), @name=rs.[PropertyName], 
			@type=ISNULL(@className + N'.' + e.[EnumName], dtm.[NativeType]) + CASE WHEN rs.[IsNullable]=1 AND dtm.[IsNullable]=0 THEN N'?' ELSE N'' END
		FROM #StoredProcResultSet rs 
		JOIN [Static].[DataTypeMap] dtm ON dtm.[SqlType]=rs.[SqlType]
		LEFT JOIN #Enum e ON rs.[EnumId]=e.[Id]
		WHERE rs.[Id]=@id;

		UPDATE @vars
		SET [Value]=@name
		WHERE [Name]=N'Name';
		UPDATE @vars
		SET [Value]=@columnName
		WHERE [Name]=N'ColumnName';
		UPDATE @vars
		SET [Value]=@type
		WHERE [Name]=N'Type';
		
		IF @id=@lastId
		BEGIN
			UPDATE @vars
			SET [Value]=''
			WHERE [Name]=N'Sep';
		END

		INSERT INTO #Output ([CodePartId], [Schema],  [Text])
		SELECT @codePartId, @spSchema, c.[Text]
		FROM [Static].[Template] t
		CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
		WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, @TT_RESULT_TYPE_PROPERTY)
		ORDER BY c.[Id];

		SELECT @id=MIN([Id]) FROM #StoredProcResultSet WHERE [StoredProcId]=@spId AND [Id]>@id;
	END

	INSERT INTO #Output ([CodePartId], [Schema],  [Text])
	SELECT @codePartId, @spSchema, c.[Text]
	FROM [Static].[Template] t
	CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
	WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, @TT_RESULT_TYPE_END)
	ORDER BY c.[Id];

	

END