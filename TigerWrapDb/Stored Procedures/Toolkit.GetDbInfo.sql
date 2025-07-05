
-- =============================================
-- 2️⃣ [Toolkit].[GetDbInfo]
-- =============================================
CREATE   PROCEDURE [Toolkit].[GetDbInfo]
    @dbName NVARCHAR(128) OUTPUT,
    @version NVARCHAR(50) OUTPUT,
    @apiLevel TINYINT OUTPUT,
    @minApiLevel TINYINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (1)
        @dbName = [DbInfo].[GetName](),
        @version = [Version],
        @apiLevel = [ApiLevel],
        @minApiLevel = [MinApiLevel]
    FROM [dbo].[SchemaVersion]
    ORDER BY [Id] DESC; -- Consistent with [DbInfo].[GetCurrentVersion]

END;