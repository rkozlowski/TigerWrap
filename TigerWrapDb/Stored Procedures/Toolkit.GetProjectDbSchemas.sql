
CREATE PROCEDURE [Toolkit].[GetProjectDbSchemas]
    @projectId SMALLINT
AS
BEGIN
    SET NOCOUNT ON;

	DROP TABLE IF EXISTS #Result;

	CREATE TABLE #Result
	(
		[Name] NVARCHAR(128) NOT NULL PRIMARY KEY
	);
	DECLARE @query NVARCHAR(1000);
	SELECT @query='SELECT [name] FROM ' + QUOTENAME(d.[name]) 
		+ '.[sys].[schemas] WHERE [schema_id]<16384 AND [name] NOT IN (''guest'', ''INFORMATION_SCHEMA'', ''sys'') ORDER BY [name]'
	FROM [dbo].[Project] p
	JOIN [sys].[databases] d ON p.[DefaultDatabase]=d.[name] 
	WHERE p.[Id]=@projectId;

	--PRINT @query;

	INSERT INTO #Result ([Name])
	EXEC(@query);
    
	SELECT [Name]
	FROM #Result
	ORDER BY [Name];

	DROP TABLE IF EXISTS #Result;
END;