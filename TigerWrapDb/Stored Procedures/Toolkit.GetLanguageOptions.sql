-- =============================================
-- Author:      IT Tiger team
-- Created:     2025-06-29
-- Description: Returns all primary language options for the specified language,
--              including global options (LanguageId IS NULL).
-- Parameters:
--   @languageId - Language ID to filter by
-- =============================================
CREATE PROCEDURE [Toolkit].[GetLanguageOptions]
    @languageId TINYINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        [Id],
        [Name],
        [Value],
        [IsOverridablePerStoredProc]
    FROM [Static].[LanguageOption]
    WHERE 
        [IsPrimary] = 1
        AND ISNULL([LanguageId], @languageId) = @languageId
    ORDER BY [Value];
END