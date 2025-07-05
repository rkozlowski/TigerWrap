CREATE FUNCTION [Internal].[GetTemplate]
(
	@languageId TINYINT,
	@languageOptions BIGINT,
	@typeId TINYINT
)
RETURNS SMALLINT
AS
BEGIN
	DECLARE @result SMALLINT;

	SELECT TOP(1) @result=t.[Id]
	FROM [Static].[Template] t
	WHERE t.[LanguageId]=@languageId AND t.TypeId=@typeId AND ((t.[LanguageOptions] & @languageOptions) = t.[LanguageOptions])
	ORDER BY t.[LanguageOptions] DESC;
		
	RETURN @result;
END