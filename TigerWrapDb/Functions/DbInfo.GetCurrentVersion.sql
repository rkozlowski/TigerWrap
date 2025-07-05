
CREATE FUNCTION [DbInfo].[GetCurrentVersion]
(	
)
RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE @ver VARCHAR(50);

	SELECT TOP(1) @ver=[Version] FROM [dbo].[SchemaVersion] ORDER BY [Id] DESC;

	RETURN @ver;
END