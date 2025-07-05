
CREATE PROCEDURE [Toolkit].[GetProjectId]
    @name NVARCHAR(200),
    @projectId SMALLINT OUTPUT,
    @errorMessage NVARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
	
	DECLARE @RC_OK INT = 0;	
	DECLARE @RC_DB_ERROR INT = 1;
	DECLARE @RC_INTERNAL_ERROR INT = 2;

    DECLARE @rc INT = @RC_INTERNAL_ERROR;    

	
	DECLARE @errorCode VARCHAR(100);

    SELECT @projectId = p.[Id]
    FROM [dbo].[Project] p
    WHERE p.[Name] = @name;

    IF @projectId IS NULL
    BEGIN
        SET @errorCode = 'UnknownProject';
        SELECT @rc=[Id], @errorMessage=[Description]
		FROM [Enum].[ToolkitResponseCode]
		WHERE [Name]=@errorCode;
		RETURN @rc;
    END
	SET @rc = @RC_OK;
    
	RETURN @rc;
END