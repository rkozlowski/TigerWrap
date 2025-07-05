
CREATE   PROCEDURE [Toolkit].[UpdateProject]
    @projectId SMALLINT,
    @name NVARCHAR(200) = NULL,
    @namespaceName VARCHAR(100) = NULL,
    @className VARCHAR(100) = NULL,
    @classAccessId TINYINT = NULL,
    @paramEnumMappingId TINYINT = NULL,
    @mapResultSetEnums BIT = NULL,
    @languageOptions BIGINT = NULL,
    @defaultDatabase NVARCHAR(128) = NULL,
    @errorMessage NVARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RC_OK INT = 0;
    DECLARE @RC_DB_ERROR INT = 1;
    DECLARE @RC_INTERNAL_ERROR INT = 2;
    DECLARE @rc INT = @RC_INTERNAL_ERROR;
    DECLARE @tranCount INT = @@TRANCOUNT;
    DECLARE @errorCode VARCHAR(100) = 'InternalError';

    IF NOT EXISTS (SELECT 1 FROM [dbo].[Project] WHERE [Id] = @projectId)
    BEGIN
        SET @errorCode = 'MissingProject';
        SELECT @rc = [Id], @errorMessage = [Description]
        FROM [Enum].[ToolkitResponseCode]
        WHERE [Name] = @errorCode;
        RETURN @rc;
    END

    IF @classAccessId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [Enum].[ClassAccess] WHERE [Id] = @classAccessId)
    BEGIN
        SET @errorCode = 'InvalidClassAccess';
        SELECT @rc = [Id], @errorMessage = [Description]
        FROM [Enum].[ToolkitResponseCode]
        WHERE [Name] = @errorCode;
        RETURN @rc;
    END

    IF @paramEnumMappingId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [Enum].[ParamEnumMapping] WHERE [Id] = @paramEnumMappingId)
    BEGIN
        SET @errorCode = 'InvalidParamEnumMapping';
        SELECT @rc = [Id], @errorMessage = [Description]
        FROM [Enum].[ToolkitResponseCode]
        WHERE [Name] = @errorCode;
        RETURN @rc;
    END

    IF @defaultDatabase IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [sys].[databases] WHERE [name] = @defaultDatabase)
    BEGIN
        SET @errorCode = 'InvalidDatabase';
        SELECT @rc = [Id], @errorMessage = [Description]
        FROM [Enum].[ToolkitResponseCode]
        WHERE [Name] = @errorCode;
        RETURN @rc;
    END

    IF @name IS NOT NULL AND EXISTS (
        SELECT 1 FROM [dbo].[Project] WHERE [Name] = @name AND [Id] <> @projectId
    )
    BEGIN
        SET @errorCode = 'DuplicateProject';
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

        UPDATE [dbo].[Project]
        SET 
            [Name] = COALESCE(@name, [Name]),
            [NamespaceName] = COALESCE(@namespaceName, [NamespaceName]),
            [ClassName] = COALESCE(@className, [ClassName]),
            [ClassAccessId] = COALESCE(@classAccessId, [ClassAccessId]),
            [ParamEnumMappingId] = COALESCE(@paramEnumMappingId, [ParamEnumMappingId]),
            [MapResultSetEnums] = COALESCE(@mapResultSetEnums, [MapResultSetEnums]),
            [LanguageOptions] = COALESCE(@languageOptions, [LanguageOptions]),
            [DefaultDatabase] = COALESCE(@defaultDatabase, [DefaultDatabase])
        WHERE [Id] = @projectId;

        IF @tranCount = 0
            COMMIT TRANSACTION;

        SET @rc = @RC_OK;
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