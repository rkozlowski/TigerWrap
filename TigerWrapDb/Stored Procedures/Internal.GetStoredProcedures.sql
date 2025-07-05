
CREATE PROCEDURE [Internal].[GetStoredProcedures]
	@projectId SMALLINT,
	@dbId SMALLINT,
	@langId TINYINT,
	@errorMessage NVARCHAR(2000) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rc INT;

	DECLARE @RC_OK INT = 0;
	DECLARE @RC_ERR_PROJECT INT = 21;
	DECLARE @RC_ERR_DB INT = 22;
	DECLARE @RC_ERR_LANG INT = 23;

    DECLARE @NM_EXACT_MATCH TINYINT = 1;
    DECLARE @NM_PREFIX TINYINT = 2;
    DECLARE @NM_SUFFIX TINYINT = 3;
    DECLARE @NM_LIKE TINYINT = 4;
    DECLARE @NM_ANY TINYINT = 255;

	IF NOT EXISTS (SELECT 1 FROM [dbo].[Project] WHERE [Id]=@projectId)
	BEGIN
		SELECT @rc = @RC_ERR_PROJECT, @errorMessage=N'Unknown project';
		RETURN @rc;
	END

	DECLARE @dbName NVARCHAR(128) = DB_NAME(@dbId);

	IF @dbName IS NULL
	BEGIN
		SELECT @rc = @RC_ERR_DB, @errorMessage=N'Database not found';
		RETURN @rc;
	END

    DECLARE @spSchemas NVARCHAR(4000);
    SELECT @spSchemas=STRING_AGG(QUOTENAME(sp.[Schema], N''''), ',') FROM (SELECT DISTINCT [Schema] FROM [dbo].[ProjectStoredProc] WHERE [ProjectId]=@projectId) sp;

    IF NULLIF(LTRIM(@spSchemas), '') IS NULL
    BEGIN
        SELECT @rc = @RC_OK;
		RETURN @rc;
    END

    DECLARE @query NVARCHAR(4000);

	SET @query = N'USE ' + QUOTENAME(@dbName) + N';
	';
	SET @query += N'SELECT SCHEMA_NAME(p.schema_id) [Schema], p.[name] [Name] '
	SET @query += N'FROM sys.procedures p '	
	SET @query += N'WHERE p.[Type]=''P''  '
	SET @query += N'AND SCHEMA_NAME(p.schema_id) IN (' + @spSchemas + N') '
	SET @query += N';
	';
	--PRINT(@query);


    DROP TABLE IF EXISTS #EveryStoredProc;
    CREATE TABLE #EveryStoredProc 
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
        [ProjectStoredProcId] INT NULL,
        UNIQUE ([Schema], [Name])
    );
	
	INSERT INTO #EveryStoredProc ([Schema], [Name])
	EXEC(@query);

    UPDATE sp
    SET sp.[ProjectStoredProcId]=psp.[Id], sp.[LanguageOptionsReset]=psp.[LanguageOptionsReset], sp.[LanguageOptionsSet]=psp.[LanguageOptionsSet]
    FROM #EveryStoredProc sp
    JOIN [dbo].[ProjectStoredProc] psp ON psp.[ProjectId]=@projectId AND psp.[Schema]=sp.[Schema] 
    AND [Internal].[IsNameMatch](sp.[Name], psp.[NameMatchId], psp.[NamePattern], psp.[EscChar])=1
    LEFT JOIN [dbo].[ProjectStoredProc] xpsp ON xpsp.[ProjectId]=@projectId AND xpsp.[Schema]=sp.[Schema] 
    AND [Internal].[IsNameMatch](sp.[Name], xpsp.[NameMatchId], xpsp.[NamePattern], xpsp.[EscChar])=1
    AND (xpsp.[NameMatchId]<psp.[NameMatchId] OR (xpsp.[NameMatchId]=psp.[NameMatchId] AND xpsp.[Id]<psp.[Id]))
    WHERE xpsp.[Id] IS NULL;

    INSERT INTO #StoredProc ([Schema], [Name], [LanguageOptionsReset], [LanguageOptionsSet])
    SELECT [Schema], [Name], [LanguageOptionsReset], [LanguageOptionsSet]
    FROM #EveryStoredProc
    WHERE [ProjectStoredProcId] IS NOT NULL
	ORDER BY [Schema], [Name];

    DROP TABLE IF EXISTS #EveryStoredProc;
END