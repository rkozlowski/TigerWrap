CREATE FUNCTION [Parser].[IsLetter]
(
	@c NCHAR(1)
)
RETURNS BIT
AS
BEGIN
	DECLARE @result BIT;

	
	SELECT @result = CASE WHEN @c LIKE '[A-Za-z]' THEN 1 ELSE 0 END

	
	RETURN @result;

END