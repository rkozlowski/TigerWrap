
-- =============================================
-- 3️⃣ [Toolkit].[GetLanguages]
-- =============================================
CREATE   PROCEDURE [Toolkit].[GetLanguages]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        [Id],
        [Name],
        [Code]
    FROM [Enum].[Language]
    WHERE [StatusId] = 1
    ORDER BY [Id];
END;