

CREATE FUNCTION [Internal].[GetLanguageOptionsString]
(
	@languageId TINYINT,
	@options BIGINT
)
RETURNS VARCHAR(1000)
AS
BEGIN
	DECLARE @result VARCHAR(1000) = NULL;

    SELECT @result=STRING_AGG(lo.[Name], ',') WITHIN GROUP (ORDER BY lo.[Value])
    FROM [Static].[LanguageOption] lo
    WHERE lo.[IsPrimary]=1 AND ((lo.[Value] & @options)=lo.[Value]);
    
    RETURN @result;
END