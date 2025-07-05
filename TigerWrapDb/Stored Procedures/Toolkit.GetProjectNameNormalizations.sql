CREATE PROCEDURE [Toolkit].[GetProjectNameNormalizations]
    @projectId SMALLINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Id], [NamePart], [NamePartTypeId]
	FROM [dbo].[ProjectNameNormalization]
	WHERE [ProjectId]=@projectId
	ORDER BY [Id];
END;