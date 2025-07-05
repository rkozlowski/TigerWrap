
CREATE FUNCTION [Internal].[GetLanguageOptions]
(
	@languageId TINYINT,
	@options VARCHAR(1000)
)
RETURNS BIGINT
AS
BEGIN
	DECLARE @result BIGINT = NULL;

	SELECT @result=SUM(DISTINCT(lo.[Value]))
	FROM [dbo].[DelimitedSplitN4K](@options, ',') o
	JOIN [Static].[LanguageOption] lo ON ISNULL(lo.[LanguageId], @languageId)=@languageId AND lo.[IsPrimary]=1 AND lo.[Name]=LTRIM(RTRIM(o.[Item]));

	RETURN ISNULL(@result, 0);
END