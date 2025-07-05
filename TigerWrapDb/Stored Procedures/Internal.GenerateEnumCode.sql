

CREATE PROCEDURE [Internal].[GenerateEnumCode]
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
	

	DECLARE @errorCode VARCHAR(100) = 'InternalError';

	DECLARE @codePartId TINYINT = (SELECT [Id] FROM [Enum].[CodePart] WHERE [Name]='Enums');

	DECLARE @TT_ENUM_START TINYINT = 3;
	DECLARE @TT_ENUM_END TINYINT = 4;
	DECLARE @TT_ENUM_ENTRY TINYINT = 5;
    DECLARE @TT_ENUM_START_FLAG TINYINT = 47;

	DECLARE @className NVARCHAR(100);	
	DECLARE @langOptions BIGINT;
	DECLARE @isSetOfFlags BIT;

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

	DECLARE @enumName NVARCHAR(100);
	DECLARE @enumSchema NVARCHAR(128);
	DECLARE @enumTable NVARCHAR(128);
	

	SELECT @enumName=[EnumName], @enumSchema=[Schema], @enumTable=[Table], @isSetOfFlags=[IsSetOfFlags]
	FROM #Enum	
	WHERE [Id]=@enumId;

	IF @enumName IS NULL
	BEGIN		
		SET @errorCode='UnknownEnum';
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
	INSERT INTO @vars ([Name], [Value]) VALUES (N'EnumName', @enumName);	
	INSERT INTO @vars ([Name], [Value]) VALUES (N'EnumSchema', [Internal].[EscapeString](@langId, QUOTENAME(@enumSchema)));	
	INSERT INTO @vars ([Name], [Value]) VALUES (N'EnumTable', [Internal].[EscapeString](@langId, QUOTENAME(@enumTable)));
	INSERT INTO @vars ([Name], [Value]) VALUES (N'EnumAccess', N'public');
	INSERT INTO @vars ([Name], [Value]) VALUES (N'Name', NULL);
	INSERT INTO @vars ([Name], [Value]) VALUES (N'Value', NULL);
	INSERT INTO @vars ([Name], [Value]) VALUES (N'Sep', N',');
	


	INSERT INTO #Output ([CodePartId], [Schema],  [Text])
	SELECT @codePartId, @enumSchema, c.[Text]
	FROM [Static].[Template] t
	CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
	WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, 
        CASE WHEN @isSetOfFlags=1 THEN @TT_ENUM_START_FLAG ELSE @TT_ENUM_START END
        )
	ORDER BY c.[Id];

	DECLARE @id INT = (SELECT MIN([Id]) FROM #EnumVal WHERE [EnumId]=@enumId);
	DECLARE @lastId INT = (SELECT MAX([Id]) FROM #EnumVal WHERE [EnumId]=@enumId);
	DECLARE @name NVARCHAR(100);
	DECLARE @value NVARCHAR(100);

	WHILE @id IS NOT NULL
	BEGIN		
		SELECT @name=[Name], @value=[Value] FROM #EnumVal WHERE [Id]=@id;
		UPDATE @vars
		SET [Value]=@name
		WHERE [Name]=N'Name';
		UPDATE @vars
		SET [Value]=@value
		WHERE [Name]=N'Value';
		
		IF @id=@lastId
		BEGIN
			UPDATE @vars
			SET [Value]=''
			WHERE [Name]=N'Sep';
		END

		INSERT INTO #Output ([CodePartId], [Schema],  [Text])
		SELECT @codePartId, @enumSchema, c.[Text]
		FROM [Static].[Template] t
		CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
		WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, @TT_ENUM_ENTRY)
		ORDER BY c.[Id];

		SELECT @id=MIN([Id]) FROM #EnumVal WHERE [EnumId]=@enumId AND [Id]>@id;
	END

	INSERT INTO #Output ([CodePartId], [Schema],  [Text])
	SELECT @codePartId, @enumSchema, c.[Text]
	FROM [Static].[Template] t
	CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
	WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, @TT_ENUM_END)
	ORDER BY c.[Id];

	

END