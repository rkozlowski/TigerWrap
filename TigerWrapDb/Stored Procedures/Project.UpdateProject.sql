CREATE PROCEDURE [Project].[UpdateProject]
	@name NVARCHAR(200),	
	@errorMessage NVARCHAR(2000) OUTPUT,
    @namespaceName VARCHAR(100) = NULL,
	@className VARCHAR(100) = NULL,
	@defaultDatabase NVARCHAR(128) = NULL,
	--@enumSchema NVARCHAR(128) = NULL,
	--@storedProcSchema NVARCHAR(128) = NULL,
	@classAccess VARCHAR(200) = NULL,	
	@paramEnumMapping VARCHAR(100) = NULL, 
	@mapResultSetEnums BIT = NULL,
	@languageOptions VARCHAR(1000) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

    SET LOCK_TIMEOUT 1000; -- wait for up to 1 seconds for a lock to be released.
	SET DEADLOCK_PRIORITY NORMAL;

	DECLARE @RC_OK INT = 0;	
	DECLARE @RC_UNKNOWN_CLASS_ACCESS INT = 1;	
	DECLARE @RC_UNKNOWN_PEM INT = 3;
    DECLARE @RC_UNKNOWN_PROJECT INT = 4;
	DECLARE @RC_DB_ERROR INT = 51;
	DECLARE @RC_UNKNOWN_ERROR INT = 99;

	DECLARE @rc INT = @RC_UNKNOWN_ERROR;
	
	DECLARE @tranCount INT = @@TRANCOUNT;

    DECLARE @projectId SMALLINT;
    DECLARE @languageId TINYINT;
    SELECT @projectId=[Id], @languageId=[LanguageId] FROM [dbo].[Project] WHERE [Name]=@name;

    IF @projectId IS NULL
    BEGIN
        SELECT @rc=@RC_UNKNOWN_PROJECT, @errorMessage='Project not found: ' + ISNULL(@name, '<NULL>');
        RETURN @rc;
    END

	DECLARE @classAccessId TINYINT = NULL;
    
    IF @classAccess IS NOT NULL
    BEGIN
        SELECT @classAccessId=[Id] FROM [Enum].[ClassAccess] WHERE [Name]=@classAccess;
	    IF @classAccessId IS NULL
	    BEGIN
		    SELECT @rc=@RC_UNKNOWN_CLASS_ACCESS, @errorMessage='Unknown class access: ' + ISNULL(@classAccess, '<NULL>');
		    RETURN @rc;
	    END
    END;
    
    DECLARE @paramEnumMappingId TINYINT = NULL;
    IF @paramEnumMapping IS NOT NULL
    BEGIN
	    SELECT @paramEnumMappingId=[Id] FROM [Enum].[ParamEnumMapping] WHERE [Name]=ISNULL(@paramEnumMapping, 'ExplicitOnly');
	    IF @paramEnumMappingId IS NULL
	    BEGIN
		    SELECT @rc=@RC_UNKNOWN_PEM, @errorMessage='Invalid enum mapping for parameters: ' + ISNULL(@paramEnumMapping, '<NULL>');
		    RETURN @rc;
	    END
    END

	DECLARE @languageOptionsVal BIGINT = NULL;
    IF NULLIF(LTRIM(@languageOptions), '') IS NOT NULL
    BEGIN
        SET @languageOptionsVal=[Internal].[GetLanguageOptions](@languageId, @languageOptions);
    END

	BEGIN TRY
		IF @tranCount = 0
			BEGIN TRANSACTION
		ELSE
			SAVE TRANSACTION TrnSp; 

        UPDATE [dbo].[Project]
        SET 
            [NamespaceName] = ISNULL(NULLIF(LTRIM(@namespaceName), ''), [NamespaceName]),
            [ClassName] = ISNULL(NULLIF(LTRIM(@className), ''), [ClassName]),
            [ClassAccessId] = ISNULL(@classAccessId, [ClassAccessId]),            
            [ParamEnumMappingId] = ISNULL(@paramEnumMappingId, [ParamEnumMappingId]),
            [MapResultSetEnums] = ISNULL(@mapResultSetEnums, [MapResultSetEnums]),
            [LanguageOptions] = ISNULL(@languageOptionsVal, [LanguageOptions]),
            [DefaultDatabase] = ISNULL(NULLIF(LTRIM(@defaultDatabase), ''), [DefaultDatabase])
        WHERE [Id]=@projectId;		

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