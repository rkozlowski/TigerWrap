
-- =============================================
-- Author:      IT Tiger team
-- Created:     2025-06-29
-- Updated:     2025-07-02
-- Description: Adds a stored procedure mapping to a project.
-- Parameters:
--   @projectId             - Target project ID
--   @schema                - Schema of the procedure
--   @nameMatchId           - Name matching strategy
--   @namePattern           - Pattern for matching
--   @escChar               - Escape character for LIKE pattern
--   @languageOptionsReset  - Options to reset (bitmask)
--   @languageOptionsSet    - Options to set (bitmask)
--   @id                    - Output ID of new row
--   @errorMessage          - Output error message if any
-- =============================================
CREATE PROCEDURE [Toolkit].[AddProjectStoredProcMapping]
    @projectId             SMALLINT,
    @schema                NVARCHAR(128),
    @nameMatchId           TINYINT,
    @namePattern           NVARCHAR(200),
    @escChar               NCHAR(1),
    @languageOptionsReset  BIGINT,
    @languageOptionsSet    BIGINT,
    @id                    INT OUTPUT,
    @errorMessage          NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @RC_OK INT = 0,
        @RC_DB_ERROR INT = 1,
        @RC_INTERNAL_ERROR INT = 2;
    
	DECLARE @rc INT = @RC_INTERNAL_ERROR;
    DECLARE @tranCount INT = @@TRANCOUNT;

    DECLARE @NM_LIKE TINYINT = 4;
    DECLARE @NM_ANY TINYINT = 255;

    SET @id = NULL;
    SET @errorMessage = NULL;

    -- Validation
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Project] WHERE [Id] = @projectId)
    BEGIN
        SELECT @rc = [Id], @errorMessage = [Description]
        FROM [Enum].[ToolkitResponseCode]
        WHERE [Name] = 'UnknownProject';
        RETURN @rc;
    END

	IF ISNULL(@schema, '') = ''
    BEGIN
        SELECT @rc = [Id], @errorMessage = [Description]
        FROM [Enum].[ToolkitResponseCode]
        WHERE [Name] = 'SchemaNotProvided';
        RETURN @rc;
    END

    IF @nameMatchId <> @NM_ANY AND ISNULL(@namePattern, '') = ''
    BEGIN
        SELECT @rc = [Id], @errorMessage = [Description]
        FROM [Enum].[ToolkitResponseCode]
        WHERE [Name] = 'NamePatternNotProvided';
        RETURN @rc;
    END

    IF @nameMatchId <> @NM_LIKE AND @escChar IS NOT NULL
    BEGIN
        SELECT @rc = [Id], @errorMessage = [Description]
        FROM [Enum].[ToolkitResponseCode]
        WHERE [Name] = 'UnexpectedEscChar';
        RETURN @rc;
    END

    IF EXISTS (
        SELECT 1 FROM [dbo].[ProjectStoredProc]
        WHERE [ProjectId] = @projectId AND [Schema] = @schema AND [NamePattern] = @namePattern
    )
    BEGIN
        SELECT @rc = [Id], @errorMessage = [Description]
        FROM [Enum].[ToolkitResponseCode]
        WHERE [Name] = 'DuplicateStoredProcMapping';
        RETURN @rc;
    END

    -- Insert
    BEGIN TRY
        IF @tranCount = 0
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION TrnSp;

        INSERT INTO [dbo].[ProjectStoredProc]
        (
            [ProjectId],
            [Schema],
            [NameMatchId],
            [NamePattern],
            [EscChar],
            [LanguageOptionsReset],
            [LanguageOptionsSet]
        )
        VALUES
        (
            @projectId,
            @schema,
            @nameMatchId,
            @namePattern,
            @escChar,
            @languageOptionsReset,
            @languageOptionsSet
        );

        SET @id = SCOPE_IDENTITY();
        SET @rc = @RC_OK;

        IF @tranCount = 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        SET @rc = @RC_DB_ERROR;
        SET @errorMessage = ERROR_MESSAGE();

        IF XACT_STATE() = -1 ROLLBACK;
        ELSE IF XACT_STATE() = 1
            IF @tranCount = 0 ROLLBACK;
            ELSE ROLLBACK TRANSACTION TrnSp;

        EXEC [Internal].[LogError];
    END CATCH

    RETURN @rc;
END;