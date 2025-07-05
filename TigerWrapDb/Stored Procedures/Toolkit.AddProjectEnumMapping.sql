-- =============================================
-- Author:      IT Tiger team
-- Created:     2025-06-29
-- Updated:     2025-07-02
-- Description: Adds an enum mapping to a project, avoiding duplicates.
-- Parameters:
--   @projectId      - Target project ID
--   @schema         - Schema of the enum table
--   @nameMatchId    - Name matching strategy (from enum)
--   @namePattern    - Pattern used to match the enum
--   @escChar        - Escape character used in pattern (if any)
--   @isSetOfFlags   - Whether this enum is a set of flags
--   @nameColumn     - Column name for enum display name
--   @id             - ID of the inserted or existing row
--   @errorMessage   - detailed error message if any
-- =============================================
CREATE PROCEDURE [Toolkit].[AddProjectEnumMapping]
    @projectId      SMALLINT,
    @schema         NVARCHAR(128),
    @nameMatchId    TINYINT,
    @namePattern    NVARCHAR(200),
    @escChar        NCHAR(1),
    @isSetOfFlags   BIT,
    @nameColumn     NVARCHAR(128),
    @id             INT OUTPUT,
    @errorMessage   NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
	SET XACT_ABORT ON;

    DECLARE 
        @RC_OK INT = 0,
        @RC_DB_ERROR INT = 1,
        @RC_INTERNAL_ERROR INT = 2;

	
	DECLARE @NM_LIKE TINYINT = 4;
	DECLARE @NM_ANY TINYINT = 255;

    SET @id = NULL;
    SET @errorMessage = NULL;
	DECLARE @errorCode VARCHAR(100) = 'InternalError';
	SET @id = NULL;

    DECLARE @rc INT = @RC_INTERNAL_ERROR;
    DECLARE @tranCount INT = @@TRANCOUNT;

	IF NOT EXISTS (SELECT 1 FROM [dbo].[Project] WHERE [Id] = @projectId)
    BEGIN
        SET @errorCode = 'UnknownProject';
        SELECT @rc = [Id], @errorMessage = [Description]
        FROM [Enum].[ToolkitResponseCode]
        WHERE [Name] = @errorCode;
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
        SET @errorCode = 'NamePatternNotProvided';
        SELECT @rc = [Id], @errorMessage = [Description]
        FROM [Enum].[ToolkitResponseCode]
        WHERE [Name] = @errorCode;
        RETURN @rc;
    END

	IF @nameMatchId <> @NM_LIKE AND @escChar IS NOT NULL
	BEGIN
        SET @errorCode = 'UnexpectedEscChar';
        SELECT @rc = [Id], @errorMessage = [Description]
        FROM [Enum].[ToolkitResponseCode]
        WHERE [Name] = @errorCode;
        RETURN @rc;
    END

	IF EXISTS (
		SELECT 1 FROM [dbo].[ProjectEnum] 
		WHERE [ProjectId] = @projectId AND [Schema] = @schema AND [NamePattern] = @namePattern
	)
	BEGIN
        SET @errorCode = 'DuplicateEnumMapping';
        SELECT @rc = [Id], @errorMessage = [Description]
        FROM [Enum].[ToolkitResponseCode]
        WHERE [Name] = @errorCode;
        RETURN @rc;
    END

    BEGIN TRY
        IF @tranCount = 0
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION TrnSp;

        INSERT INTO [dbo].[ProjectEnum]
        (
			[ProjectId], [Schema], [NameMatchId], [NamePattern], [EscChar], [IsSetOfFlags], [NameColumn]
        )
        VALUES
        (
			@projectId, @schema, @nameMatchId, @namePattern, @escChar, @isSetOfFlags, @nameColumn
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
END