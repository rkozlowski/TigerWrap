CREATE   PROCEDURE [Toolkit].[GetProjectInfo]
    @projectName NVARCHAR(200),
    @projectId SMALLINT OUTPUT,
    @languageId TINYINT OUTPUT,
    @defaultDatabase NVARCHAR(128) OUTPUT,
	@className VARCHAR(100) OUTPUT,
    @errorMessage NVARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RC_OK INT = 0;
    DECLARE @RC_UNKNOWN_PROJECT INT = 3;  -- Matches [Enum].[ToolkitResponseCode]
    DECLARE @rc INT = @RC_UNKNOWN_PROJECT;

    -- Look up project by name
    SELECT 
        @projectId = p.[Id],
        @languageId = p.[LanguageId],
        @defaultDatabase = p.[DefaultDatabase],
		@className = p.[ClassName]
    FROM [dbo].[Project] p
    WHERE p.[Name] = @projectName;

    IF @projectId IS NULL
    BEGIN
        SELECT @errorMessage = [Description]
        FROM [Enum].[ToolkitResponseCode]
        WHERE [Name] = 'UnknownProject';

        RETURN @RC_UNKNOWN_PROJECT;
    END

    -- Validate default database is a user DB only (database_id > 4)
    IF @defaultDatabase IS NOT NULL AND NOT EXISTS (
        SELECT 1 
        FROM sys.databases 
        WHERE [name] = @defaultDatabase AND [database_id] > 4
    )
    BEGIN
        SET @defaultDatabase = NULL;
    END

    SET @rc = @RC_OK;
    RETURN @rc;
END;