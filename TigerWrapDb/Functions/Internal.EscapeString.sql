
CREATE FUNCTION [Internal].[EscapeString]
(	
	@languageId TINYINT,	
	@value NVARCHAR(2000)
)
RETURNS NVARCHAR(2000)
AS
BEGIN
	-- only c# is currently supported, so @languageId is not required, but in the future this function would need to escape the string in a proper way for different languages
	DECLARE @result NVARCHAR(2000) = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@value, '\', '\\'), '"', '\"'), CHAR(9), '\t'), CHAR(13), '\r'), CHAR(10), '\n');

	RETURN @result;
END