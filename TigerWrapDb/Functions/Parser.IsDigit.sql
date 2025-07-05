CREATE FUNCTION [Parser].[IsDigit]
(
	@c NCHAR(1)
)
RETURNS BIT
AS
BEGIN
	DECLARE @result BIT;

	
	SELECT @result = CASE WHEN @c LIKE '[0-9]' THEN 1 ELSE 0 END

	
	RETURN @result;

END