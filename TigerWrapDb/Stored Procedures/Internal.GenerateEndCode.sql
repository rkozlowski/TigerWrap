
CREATE PROCEDURE [Internal].[GenerateEndCode]
	@projectId SMALLINT,
	@dbId SMALLINT,
	@langId TINYINT,
	@errorMessage NVARCHAR(2000) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rc INT;

	DECLARE @RC_OK INT = 0;
	
	DECLARE @TT_START TINYINT = 1;
	DECLARE @TT_END TINYINT = 2;

	DECLARE @namespaceName NVARCHAR(100);
	DECLARE @className NVARCHAR(100);
	DECLARE @classAccess NVARCHAR(100);
	DECLARE @langOptions BIGINT;

	DECLARE @errorCode VARCHAR(100) = 'InternalError';

	DECLARE @codePartId TINYINT = (SELECT [Id] FROM [Enum].[CodePart] WHERE [Name]='CodeEnd');

	SELECT @namespaceName = p.[NamespaceName], @className=p.[ClassName], @classAccess=ca.[Name], @langOptions=p.[LanguageOptions]
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
	INSERT INTO @vars ([Name], [Value]) VALUES (N'NamespaceName', @namespaceName);
	INSERT INTO @vars ([Name], [Value]) VALUES (N'ClassName', @className);
	INSERT INTO @vars ([Name], [Value]) VALUES (N'ClassAccess', @classAccess);


	INSERT INTO #Output ([CodePartId], [Text])
	SELECT @codePartId, c.[Text]
	FROM [Static].[Template] t
	CROSS APPLY [Internal].[ProcessTemplate](t.[Template], @vars) c
	WHERE t.[Id]=[Internal].[GetTemplate](@langId, @langOptions, @TT_END)
	ORDER BY c.[Id];

END