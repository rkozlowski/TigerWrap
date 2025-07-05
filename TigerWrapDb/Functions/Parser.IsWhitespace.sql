
CREATE FUNCTION [Parser].[IsWhitespace]
(
	@c NCHAR(1)
)
RETURNS BIT
AS
BEGIN
	DECLARE @result BIT;

	SELECT @result = CASE WHEN @c IN (' ', CHAR(9), CHAR(10), CHAR(13)) THEN 1 ELSE 0 END

	RETURN @result;

END