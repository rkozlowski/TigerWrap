CREATE PROCEDURE [Project].[GenerateCode]
    @projectName NVARCHAR(200),
    @errorMessage NVARCHAR(2000) OUTPUT,
    @databaseName NVARCHAR(128) = NULL,
    @codeGenOptions VARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE  @rc INT;

    DECLARE @RC_OK INT = 0;
    DECLARE @RC_ERR_UNKNOWN_PROJECT INT = 1;
    DECLARE @RC_ERR_UNKNOWN_DB INT = 2;

    SELECT @rc = @RC_OK, @errorMessage = NULL;

    DROP TABLE IF EXISTS #Output;

    DECLARE @projectId SMALLINT;
    DECLARE @langId TINYINT;
    
	SELECT @projectId=[Id], @langId=[LanguageId], @databaseName=ISNULL(@databaseName, [DefaultDatabase]) FROM [dbo].[Project] WHERE [Name]=@projectName;

    IF @projectId IS NULL 
    BEGIN
        SELECT @rc = @RC_ERR_UNKNOWN_PROJECT, @errorMessage = 'Unknown project: ' + ISNULL(@projectName, '<NULL>');
        RETURN @rc;
    END;

    DECLARE @dbId SMALLINT = DB_ID(@databaseName);

    IF @dbId IS NULL 
    BEGIN
        SELECT @rc = @RC_ERR_UNKNOWN_DB, @errorMessage = 'Unknown database: ' + ISNULL(@databaseName, '<NULL>')
        RETURN @rc;
    END;

    DECLARE    @retVal int;
    
    CREATE TABLE #Output
	(
		[Id] INT IDENTITY(1,1) PRIMARY KEY,
		[CodePartId] TINYINT NULL,     -- for now mustr be NULLable, untill we would fix all [Internal].[Generate*Code] SPs
		[Schema] NVARCHAR(128) NULL,    -- Optional: e.g., for grouping (Enums, TVPs)
		[Text] NVARCHAR(MAX) NOT NULL
	);

    
    EXECUTE @retVal = [Internal].[GenerateCode] @projectId = @projectId, @dbId = @dbId, @errorMessage = @errorMessage OUTPUT;
    IF @retVal<>0
    BEGIN
        SELECT @rc = @retVal;
        RETURN @rc;
    END

	SELECT [Text]
    FROM #Output
    ORDER BY [Id];
    
    DROP TABLE IF EXISTS #Output;
    
    SET @rc = @RC_OK;
    RETURN @rc;
END