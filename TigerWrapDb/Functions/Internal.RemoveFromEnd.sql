
CREATE FUNCTION [Internal].[RemoveFromEnd]
(		
	@text NVARCHAR(500),
	@end NVARCHAR(128)
)
RETURNS NVARCHAR(500)
AS
BEGIN
	
	DECLARE @result NVARCHAR(500) = @text;
	
	DECLARE @tl INT = LEN(@text);
	DECLARE @el INT = LEN(@end);

	IF (@el > 0 AND @tl >= @el AND RIGHT(@text, @el)=@end)
	BEGIN
		SET @result = LEFT(@text, @tl - @el);
	END
	

	RETURN @result;
END