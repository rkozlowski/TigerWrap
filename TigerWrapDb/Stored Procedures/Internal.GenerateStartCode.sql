
CREATE PROCEDURE [Internal].[GenerateStartCode]
	@projectId SMALLINT,
	@dbId SMALLINT,
	@langId TINYINT,
	@errorMessage NVARCHAR(2000) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rc INT;

	DECLARE @RC_OK INT = 0;

	DECLARE @errorCode VARCHAR(100) = 'InternalError';
	
	DECLARE @codeHeaderPartId TINYINT = (SELECT [Id] FROM [Enum].[CodePart] WHERE [Name]='CodeHeader');
	DECLARE @CodeBootstrapPartId TINYINT = (SELECT [Id] FROM [Enum].[CodePart] WHERE [Name]='CodeBootstrap');
	


	DECLARE @TT_START_COMMENT TINYINT = 1;
	DECLARE @TT_START_USING TINYINT = 37;
	DECLARE @TT_START_CLASS TINYINT = 38;
	DECLARE @TT_START_COMMENT_TOOL TINYINT = 39;
	DECLARE @TT_START_COMMENT_ENV TINYINT = 40;
	DECLARE @TT_START_COMMENT_END TINYINT = 41;
	DECLARE @TT_STATIC_CTOR_END TINYINT = 42;
	DECLARE @TT_RS_MAPPING_SETUP TINYINT = 43;
	DECLARE @TT_WRAPPER_ENUM_START TINYINT = 48;
	DECLARE @TT_WRAPPER_ENUM_END TINYINT = 49;
	DECLARE @TT_WRAPPER_ENUM_ITEM TINYINT = 50;
	DECLARE @TT_START_CLASS_BOOTSTRAP TINYINT = 51;

	DECLARE @namespaceName NVARCHAR(100);
	DECLARE @className NVARCHAR(100);
	DECLARE @classAccess NVARCHAR(100);
	DECLARE @projectName NVARCHAR(200);
	DECLARE @genStaticClass BIT; 
	DECLARE @langOptions BIGINT;
	

	SELECT @namespaceName = p.[NamespaceName], @className=p.[ClassName], @classAccess=ca.[Name], @projectName=p.[Name], @langOptions=p.[LanguageOptions]	
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
	 
	INSERT INTO @vars ([Name], [Value]) VALUES (N'ServerName', CAST(serverproperty('servername') AS NVARCHAR(500)));
	INSERT INTO @vars ([Name], [Value]) VALUES (N'InstanceName', @@SERVICENAME);
	INSERT INTO @vars ([Name], [Value]) VALUES (N'Database', @dbName);
	INSERT INTO @vars ([Name], [Value]) VALUES (N'ProjectName', @projectName);
	INSERT INTO @vars ([Name], [Value]) VALUES (N'NamespaceName', @namespaceName);
	INSERT INTO @vars ([Name], [Value]) VALUES (N'ClassName', @className);
	INSERT INTO @vars ([Name], [Value]) VALUES (N'ClassAccess', @classAccess);
	INSERT INTO @vars ([Name], [Value]) VALUES (N'Timestamp', CONVERT(NVARCHAR(50), CAST(SYSDATETIME() AS DATETIME2(0)), 120));
	INSERT INTO @vars ([Name], [Value]) VALUES (N'DbUser', ORIGINAL_LOGIN());
	INSERT INTO @vars ([Name], [Value]) VALUES (N'ToolDatabase', DB_NAME());
	INSERT INTO @vars ([Name], [Value]) VALUES (N'ToolName', N'TigerWrap');
	INSERT INTO @vars ([Name], [Value]) VALUES (N'ToolUrl', N'https://github.com/rkozlowski/TigerWrap');	
	INSERT INTO @vars ([Name], [Value]) 
	SELECT TOP(1) N'ToolVersion', [Version]
	FROM [dbo].[SchemaVersion]
	ORDER BY [Id] DESC;
	INSERT INTO @vars ([Name], [Value]) VALUES (N'RsType', NULL);


	INSERT INTO #Output ([CodePartId], [Text])
	SELECT @codeHeaderPartId, c.[Text]
	FROM [Static].[Template] t
	CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
	WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, @TT_START_COMMENT)
	ORDER BY c.[Id];

	INSERT INTO #Output ([CodePartId], [Text])
	SELECT @codeHeaderPartId, c.[Text]
	FROM [Static].[Template] t
	CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
	WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, @TT_START_COMMENT_ENV)
	ORDER BY c.[Id];

	INSERT INTO #Output ([CodePartId], [Text])
	SELECT @codeHeaderPartId, c.[Text]
	FROM [Static].[Template] t
	CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
	WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, @TT_START_COMMENT_TOOL)
	ORDER BY c.[Id];

	INSERT INTO #Output ([CodePartId], [Text])
	SELECT @codeHeaderPartId, c.[Text]
	FROM [Static].[Template] t
	CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
	WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, @TT_START_COMMENT_END)
	ORDER BY c.[Id];

	INSERT INTO #Output ([CodePartId], [Text])
	SELECT @codeHeaderPartId, c.[Text]
	FROM [Static].[Template] t
	CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
	WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, @TT_START_USING)
	ORDER BY c.[Id];

	INSERT INTO #Output ([CodePartId], [Text])
	SELECT @codeHeaderPartId, c.[Text]
	FROM [Static].[Template] t
	CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
	WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, @TT_START_CLASS)
	ORDER BY c.[Id];

	INSERT INTO #Output ([CodePartId], [Text])
	SELECT @CodeBootstrapPartId, c.[Text]
	FROM [Static].[Template] t
	CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
	WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, @TT_START_CLASS_BOOTSTRAP)
	ORDER BY c.[Id];

	DECLARE @id INT;
	DECLARE @rsType VARCHAR(200);

	SELECT @id=MIN([Id]) FROM #StoredProcResultType;	
	WHILE @id IS NOT NULL
	BEGIN
		SELECT @rsType=rt.[Name]
		FROM #StoredProcResultType rt		
		WHERE rt.[Id]=@id;

		UPDATE @vars
		SET [Value]=@rsType
		WHERE [Name]=N'RsType';

		INSERT INTO #Output ([CodePartId], [Text])
		SELECT @CodeBootstrapPartId, c.[Text]
		FROM [Static].[Template] t
		CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
		WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, @TT_RS_MAPPING_SETUP)
		ORDER BY c.[Id];

		

		SELECT @id=MIN([Id]) FROM #StoredProcResultType WHERE [Id] > @id;
	END

	INSERT INTO #Output ([CodePartId], [Text])
	SELECT @CodeBootstrapPartId, c.[Text]
	FROM [Static].[Template] t
	CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
	WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, @TT_STATIC_CTOR_END)
	ORDER BY c.[Id];

	INSERT INTO @vars ([Name], [Value]) VALUES (N'EnumAccess', 'public');
	INSERT INTO @vars ([Name], [Value]) VALUES (N'EnumName', 'StoredProcedureWrapper');
	INSERT INTO @vars ([Name], [Value]) VALUES (N'Name', '');
	INSERT INTO @vars ([Name], [Value]) VALUES (N'Sep', ',');

	INSERT INTO #Output ([CodePartId], [Text])
	SELECT @CodeBootstrapPartId, c.[Text]
	FROM [Static].[Template] t
	CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
	WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, @TT_WRAPPER_ENUM_START)
	ORDER BY c.[Id];



	SELECT @id=MIN([Id]) FROM #StoredProc;
	DECLARE @lastId INT = (SELECT MAX([Id]) FROM #StoredProc);
	DECLARE @wrapperName NVARCHAR(200);
	WHILE @id IS NOT NULL
	BEGIN
		SELECT @wrapperName=[WrapperName]
		FROM #StoredProc WHERE [Id]=@id;

		UPDATE @vars
		SET [Value]=@wrapperName
		WHERE [Name]=N'Name';

		IF @id=@lastId
		BEGIN
			UPDATE @vars
			SET [Value]=''
			WHERE [Name]=N'Sep';
		END

		INSERT INTO #Output ([CodePartId], [Text])
		SELECT @CodeBootstrapPartId, c.[Text]
		FROM [Static].[Template] t
		CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
		WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, @TT_WRAPPER_ENUM_ITEM)
		ORDER BY c.[Id];

		SELECT @id=MIN([Id]) FROM #StoredProc WHERE [Id] > @id;
	END

	INSERT INTO #Output ([CodePartId], [Text])
	SELECT @CodeBootstrapPartId, c.[Text]
	FROM [Static].[Template] t
	CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
	WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, @TT_WRAPPER_ENUM_END)
	ORDER BY c.[Id];
	
END