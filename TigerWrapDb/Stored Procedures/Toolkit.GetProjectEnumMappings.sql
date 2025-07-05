CREATE PROCEDURE [Toolkit].[GetProjectEnumMappings]
    @projectId SMALLINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Id], [Schema], [NameMatchId], [NamePattern], [EscChar], [IsSetOfFlags], [NameColumn]
	FROM [dbo].[ProjectEnum]
	WHERE [ProjectId]=@projectId
	ORDER BY [Id];

END;