CREATE PROCEDURE [Toolkit].[CreateProject]
    @name NVARCHAR(200),
    @namespaceName VARCHAR(100),
    @className VARCHAR(100),
    @classAccessId TINYINT,
    @languageId TINYINT,
    @paramEnumMappingId TINYINT,
    @mapResultSetEnums BIT,
    @languageOptions BIGINT,
    @defaultDatabase NVARCHAR(128),    
	@projectId SMALLINT OUTPUT,
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
	
	DECLARE @errorCode VARCHAR(100) = 'InternalError'

	IF NOT EXISTS (SELECT 1 FROM [Enum].[ClassAccess] WHERE [Id]=@classAccessId)
	BEGIN
		SET @errorCode='InvalidClassAccess';
		SELECT @rc=[Id], @errorMessage=[Description]
		FROM [Enum].[ToolkitResponseCode]
		WHERE [Name]=@errorCode;
		RETURN @rc;
	END
	
	IF NOT EXISTS (SELECT 1 FROM [Enum].[Language] WHERE [Id]=@languageId)
	BEGIN
		SET @errorCode='InvalidLanguage';
		SELECT @rc=[Id], @errorMessage=[Description]
		FROM [Enum].[ToolkitResponseCode]
		WHERE [Name]=@errorCode;
		RETURN @rc;
	END

	IF NOT EXISTS (SELECT 1 FROM [sys].[databases] WHERE [name]=@defaultDatabase)
	BEGIN
		SET @errorCode='InvalidDatabase';
		SELECT @rc=[Id], @errorMessage=[Description]
		FROM [Enum].[ToolkitResponseCode]
		WHERE [Name]=@errorCode;
		RETURN @rc;
	END


    BEGIN TRY
        IF @tranCount = 0
            BEGIN TRANSACTION
        ELSE
            SAVE TRANSACTION TrnSp;

        EXEC @rc = [Internal].[CreateProject]
            @name, @namespaceName, @className, @classAccessId, @languageId, @paramEnumMappingId,
            @mapResultSetEnums, @languageOptions, @defaultDatabase, NULL, NULL,
            @projectId OUTPUT;

        IF @tranCount = 0
            COMMIT TRANSACTION;

        --SET @rc = 0;
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