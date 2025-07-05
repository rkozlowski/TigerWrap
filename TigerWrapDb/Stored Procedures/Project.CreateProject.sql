CREATE PROCEDURE [Project].[CreateProject]
	@name NVARCHAR(200),
	@namespaceName VARCHAR(100),
	@className VARCHAR(100),
	@errorMessage NVARCHAR(2000) OUTPUT,
	@defaultDatabase NVARCHAR(128) = NULL,
	@enumSchema NVARCHAR(128) = NULL,
	@storedProcSchema NVARCHAR(128) = NULL,
	@classAccess VARCHAR(200) = 'public',	
	@language VARCHAR(200) = 'c#',
	@paramEnumMapping VARCHAR(100) = NULL, 
	@mapResultSetEnums BIT = 0,
	@languageOptions VARCHAR(1000) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

    SET LOCK_TIMEOUT 1000; -- wait for up to 1 seconds for a lock to be released.
	SET DEADLOCK_PRIORITY NORMAL;

	
	DECLARE @RC_OK INT = 0;	
	DECLARE @RC_DB_ERROR INT = 1;
	DECLARE @RC_INTERNAL_ERROR INT = 2;
	
    DECLARE @NM_EXACT_MATCH TINYINT = 1;
    DECLARE @NM_PREFIX TINYINT = 2;
    DECLARE @NM_SUFFIX TINYINT = 3;
    DECLARE @NM_LIKE TINYINT = 4;
    DECLARE @NM_ANY TINYINT = 255;

	DECLARE @rc INT;
	DECLARE @errorCode VARCHAR(100) = 'InternalError'
	
	DECLARE @tranCount INT = @@TRANCOUNT;

	DECLARE @classAccessId TINYINT = (SELECT [Id] FROM [Enum].[ClassAccess] WHERE [Name]=@classAccess);
	IF @classAccessId IS NULL
	BEGIN
		SET @errorCode = 'InvalidClassAccess';
		SELECT @rc=[Id], @errorMessage='Invalid class access: ' + ISNULL(@classAccess, '<NULL>')
		FROM [Enum].[ToolkitResponseCode] WHERE [Name]=@errorCode;
		RETURN @rc;
	END

	DECLARE @languageId TINYINT = (SELECT [Id] FROM [Enum].[Language] WHERE [Name]=@language);
	IF @languageId IS NULL
	BEGIN
		SET @errorCode = 'InvalidLanguage';
		SELECT @rc=[Id], @errorMessage='Invalid programming language: ' + ISNULL(@language, '<NULL>')
		FROM [Enum].[ToolkitResponseCode] WHERE [Name]=@errorCode;
		RETURN @rc;
	END

	DECLARE @paramEnumMappingId TINYINT = (SELECT [Id] FROM [Enum].[ParamEnumMapping] WHERE [Name]=ISNULL(@paramEnumMapping, 'ExplicitOnly'));
	IF @paramEnumMappingId IS NULL
	BEGIN
		SET @errorCode = 'InvalidParamEnumMapping';
		SELECT @rc=[Id], @errorMessage='Invalid enum mapping for parameters: ' + ISNULL(@paramEnumMapping, '<NULL>')
		FROM [Enum].[ToolkitResponseCode] WHERE [Name]=@errorCode;
		RETURN @rc;
	END

	DECLARE @languageOptionsVal BIGINT = [Internal].[GetLanguageOptions](@languageId, @languageOptions);
    DECLARE @projectId SMALLINT;

	BEGIN TRY
		IF @tranCount = 0
			BEGIN TRANSACTION
		ELSE
			SAVE TRANSACTION TrnSp; 

		EXEC [Internal].[CreateProject]
            @name, @namespaceName, @className, @classAccessId, @languageId, @paramEnumMappingId,
            @mapResultSetEnums, @languageOptionsVal, @defaultDatabase, @enumSchema, @storedProcSchema,
            @projectId OUTPUT;

		IF @tranCount = 0    
			COMMIT TRANSACTION

		SET @rc = @RC_OK;
	END TRY
	BEGIN CATCH
		SET @rc = @RC_DB_ERROR;
        

		SET @errorMessage = ERROR_MESSAGE();

		DECLARE @xstate INT;
		SELECT @xstate = XACT_STATE();
			
		IF @xstate = -1
			ROLLBACK TRANSACTION;
		IF @xstate = 1 and @tranCount = 0
			ROLLBACK TRANSACTION;
		IF @xstate = 1 and @tranCount > 0
			ROLLBACK TRANSACTION TrnSp;
		
		EXEC [Internal].[LogError];
	END CATCH

	
	RETURN @rc;
END