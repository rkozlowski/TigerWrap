CREATE PROCEDURE [Toolkit].[GetProjectStoredProcedureMappings]
    @projectId SMALLINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [Id], [Schema], [NameMatchId], [NamePattern], [EscChar], [LanguageOptionsReset], [LanguageOptionsSet]
	FROM [dbo].[ProjectStoredProc]
	WHERE [ProjectId]=@projectId
	ORDER BY [Id];
END;