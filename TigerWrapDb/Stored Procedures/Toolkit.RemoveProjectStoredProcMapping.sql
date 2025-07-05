
-- =============================================
-- Author:      IT Tiger team
-- Created:     2025-07-02
-- Description: Removes a stored procedure mapping from a project.
-- Parameters:
--   @projectId             - Target project ID
--   @spMappingId           - ID of the mapping to be removed
--   @errorMessage          - Output error message if any
-- =============================================
CREATE   PROCEDURE [Toolkit].[RemoveProjectStoredProcMapping]
    @projectId SMALLINT,
    @spMappingId INT,
    @errorMessage NVARCHAR(4000) OUTPUT
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

    SET @errorMessage = NULL;

    -- Validation
    IF NOT EXISTS (
        SELECT 1 FROM [dbo].[ProjectStoredProc]
        WHERE [Id] = @spMappingId AND [ProjectId] = @projectId
    )
    BEGIN
        SELECT @rc = [Id], @errorMessage = [Description]
        FROM [Enum].[ToolkitResponseCode]
        WHERE [Name] = 'UnknownStoredProcMapping';
        RETURN @rc;
    END

    -- Delete
    BEGIN TRY
        IF @tranCount = 0
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION TrnSp;

        DELETE FROM [dbo].[ProjectStoredProc]
        WHERE [Id] = @spMappingId AND [ProjectId] = @projectId;

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