
-- =============================================
-- 4️⃣ [Toolkit].[GetProjects]
-- =============================================
CREATE   PROCEDURE [Toolkit].[GetProjects]
    @languageId TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        p.[Id],
        p.[Name],
        p.[ClassName],
        p.[NamespaceName],
        l.[Name] AS [LanguageName],
        l.[Code] AS [LanguageCode]
    FROM [dbo].[Project] p
    LEFT JOIN [Enum].[Language] l ON l.[Id] = p.[LanguageId]
    WHERE (@languageId IS NULL OR p.[LanguageId] = @languageId)
    ORDER BY p.[Name];
END;