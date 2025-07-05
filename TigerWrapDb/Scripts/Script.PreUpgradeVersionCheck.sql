USE [$(DatabaseName)];
GO
PRINT N'Checking database version before upgrade...';
DECLARE @expectedName VARCHAR(50) = 'MsSqlProjectHelperDb';
DECLARE @expectedVersion VARCHAR(50) = '0.8.5';
DECLARE @newVersion VARCHAR(50) = '0.9.0';
SET XACT_ABORT ON;
BEGIN TRY
	EXEC('DECLARE @name VARCHAR(50) = [DbInfo].[GetName](); DECLARE @ver VARCHAR(50) = [DbInfo].[GetCurrentVersion](); ')
END TRY
BEGIN CATCH
	PRINT N'An error occured.'
	PRINT N'Upgrade is not possible.';
	PRINT N'Check if you are executing this script against proper database.';
	PRINT N'Expected database type:    ' + @expectedName;
	PRINT N'Expected database version: ' + @expectedVersion;
	SET NOEXEC ON;
END CATCH
DECLARE @name VARCHAR(50) = [DbInfo].[GetName]();
DECLARE @currentVersion VARCHAR(50) = [DbInfo].[GetCurrentVersion]();

IF @name<>@expectedName
BEGIN	
	PRINT N'Expected database type: ' + @expectedName;
	PRINT N'Actual database type:   ' + ISNULL(@name, '<NULL>');
	PRINT N'Upgrade is not supported.';
	PRINT N'Check if you are executing this script against proper database.';
	SET NOEXEC ON;
END
IF @currentVersion<>@expectedVersion
BEGIN	
	PRINT N'Expected version of the database: ' + @expectedVersion;
	PRINT N'Actual version of the database:   ' + ISNULL(@currentVersion, '<NULL>');
	PRINT N'Upgrade is not supported.';
	PRINT N'Check if you are executing this script against proper database.';
	SET NOEXEC ON;
END
PRINT N'Upgrading database from version ' + @currentVersion + N' to version ' + @newVersion + N'...';
GO
