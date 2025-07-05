CREATE   PROCEDURE [Toolkit].[RemoveProjectNameNormalization]
    @projectId SMALLINT,
    @normalizationId INT,
    @errorMessage NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE 
        @RC_OK INT = 0,
        @RC_DB_ERROR INT = 1,
        @RC_INTERNAL_ERROR INT = 2;

    DECLARE @rc INT = @RC_INTERNAL_ERROR,
        @errorCode VARCHAR(100) = 'InternalError',
        @tranCount INT = @@TRANCOUNT;

    SET @errorMessage = NULL;

    IF NOT EXISTS (
        SELECT 1 FROM [dbo].[ProjectNameNormalization]
        WHERE [Id] = @normalizationId AND [ProjectId] = @projectId
    )
    BEGIN
        SET @errorCode = 'UnknownNameNormalization';
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

        DELETE FROM [dbo].[ProjectNameNormalization]
        WHERE [Id] = @normalizationId AND [ProjectId] = @projectId;

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