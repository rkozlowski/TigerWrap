CREATE   PROCEDURE [Toolkit].[AddProjectNameNormalization]
    @projectId SMALLINT,
    @namePart NVARCHAR(128),
    @namePartTypeId TINYINT,
    @id INT OUTPUT,
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

    SET @id = NULL;
    SET @errorMessage = NULL;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[Project] WHERE [Id] = @projectId)
    BEGIN
        SET @errorCode = 'UnknownProject';
        SELECT @rc = [Id], @errorMessage = [Description]
        FROM [Enum].[ToolkitResponseCode]
        WHERE [Name] = @errorCode;
        RETURN @rc;
    END

    IF NOT EXISTS (SELECT 1 FROM [Enum].[NamePartType] WHERE [Id] = @namePartTypeId)
    BEGIN
        SET @errorCode = 'InvalidNamePartType';
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

        INSERT INTO [dbo].[ProjectNameNormalization]
        (
            [ProjectId],
            [NamePart],
            [NamePartTypeId]
        )
        VALUES
        (
            @projectId,
            @namePart,
            @namePartTypeId
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