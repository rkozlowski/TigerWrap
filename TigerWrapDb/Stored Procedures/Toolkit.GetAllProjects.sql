CREATE PROCEDURE [Toolkit].[GetAllProjects]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.[Id],
        p.[Name],
        p.[ClassName],
        p.[NamespaceName],
        l.[Name] AS [LanguageName]
    FROM [dbo].[Project] p
    LEFT JOIN [Enum].[Language] l ON l.[Id] = p.[LanguageId]
    ORDER BY p.[Name];
END