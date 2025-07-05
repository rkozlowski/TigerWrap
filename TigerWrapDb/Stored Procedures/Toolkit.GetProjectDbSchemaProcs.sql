
CREATE PROCEDURE [Toolkit].[GetProjectDbSchemaProcs]
    @projectId SMALLINT,
	@schema NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

	DROP TABLE IF EXISTS #Result;

	CREATE TABLE #Result
	(
		[Name] NVARCHAR(128) NOT NULL PRIMARY KEY
	);
	DECLARE @query NVARCHAR(1000);
	SELECT @query='SELECT p.[name] FROM ' + QUOTENAME(d.[name]) 
		+ '.[sys].[procedures] p WHERE p.[Type]=''P'' AND SCHEMA_NAME(p.schema_id)=' + QUOTENAME(@schema, '''') + ' ORDER BY p.[name]'
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