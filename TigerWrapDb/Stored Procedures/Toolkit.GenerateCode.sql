CREATE PROCEDURE [Toolkit].[GenerateCode]
    @projectId SMALLINT,
	@databaseName NVARCHAR(128),
	@loggingLevelId TINYINT,
    @errorMessage NVARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE  @rc INT;

    DECLARE @RC_OK INT = 0;
    DECLARE @RC_ERR_UNKNOWN_PROJECT INT = 1;
    DECLARE @RC_ERR_UNKNOWN_DB INT = 2;

    SELECT @rc = @RC_OK, @errorMessage = NULL;

    DROP TABLE IF EXISTS #Output;

    DECLARE @OPT_GEN_ENUMS SMALLINT = 1;
    DECLARE @OPT_GEN_RESULT_TYPES SMALLINT = 2;
    DECLARE @OPT_GEN_TVP_TYPES SMALLINT = 4;
    DECLARE @OPT_GEN_SP_WRAPPERS SMALLINT = 8;

    DECLARE @langId TINYINT;
    
    SELECT @langId=[LanguageId], @databaseName=ISNULL(@databaseName, [DefaultDatabase]) 
	FROM [dbo].[Project] 
	WHERE [Id]=@projectId;

    IF @projectId IS NULL 
    BEGIN
        SELECT @rc = @RC_ERR_UNKNOWN_PROJECT, @errorMessage = 'Unknown project: ' + ISNULL(LOWER(@projectId), '<NULL>');
        RETURN @rc;
    END;

    DECLARE @dbId SMALLINT = DB_ID(@databaseName);

    IF @dbId IS NULL 
    BEGIN
        SELECT @rc = @RC_ERR_UNKNOWN_DB, @errorMessage = 'Unknown database: ' + ISNULL(@databaseName, '<NULL>')
        RETURN @rc;
    END;

    DECLARE @retVal int;
    
    CREATE TABLE #Output
	(
		[Id] INT IDENTITY(1,1) PRIMARY KEY,
		[CodePartId] TINYINT NOT NULL,
		[Schema] NVARCHAR(128) NULL,    -- Optional: e.g., for grouping (Enums, TVPs)
		[Text] NVARCHAR(MAX) NOT NULL
	);

    
    EXECUTE @retVal = [Internal].[GenerateCode] @projectId = @projectId, @dbId = @dbId, @errorMessage = @errorMessage OUTPUT;
    IF @retVal<>0
    BEGIN
        SELECT @rc = @retVal;
        RETURN @rc;
    END

	SELECT o.[Id], cp.[Id] [CodePartId], o.[Schema], o.[Text]
    FROM #Output o
	JOIN [Enum].[CodePart] cp ON cp.[Id]=o.[CodePartId]
    ORDER BY o.[Id];
    
    DROP TABLE IF EXISTS #Output;
    
    SET @rc = @RC_OK;
    RETURN @rc;
END