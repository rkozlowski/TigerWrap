
-- ============================================
-- Stored Procedure: [Toolkit].[GetResponseCodes]
-- ============================================
CREATE PROCEDURE [Toolkit].[GetResponseCodes]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Name,
        Description,
        IsSuccess
    FROM [Enum].[ToolkitResponseCode]
    ORDER BY Id;
END