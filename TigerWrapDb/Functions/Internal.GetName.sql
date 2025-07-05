CREATE FUNCTION [Internal].[GetName]
(	
	@projectId TINYINT,
	@typeId TINYINT,
	@name NVARCHAR(128),
	@schema NVARCHAR(128)
)
RETURNS NVARCHAR(200)
AS
BEGIN
	DECLARE @result NVARCHAR(200) = '';
	DECLARE @casingId TINYINT;
	
	SELECT @casingId=lnc.[CasingId]
	FROM [dbo].[Project] p
	JOIN [Static].[LanguageNameCasing] lnc ON lnc.[LanguageId]=p.[LanguageId] AND lnc.[NameTypeId]=@typeId
	WHERE p.[Id]=@projectId;

	SELECT @result=[Internal].[GetCaseName](@casingId, @name, NULL);
	
	RETURN ISNULL(NULLIF(@result, ''), [Internal].[GetCaseName](@casingId, 'x', NULL));
END