
CREATE FUNCTION [Internal].[RemoveFromStart]
(		
	@text NVARCHAR(500),
	@start NVARCHAR(128)
)
RETURNS NVARCHAR(500)
AS
BEGIN
	
	DECLARE @result NVARCHAR(500) = @text;
	
	DECLARE @tl INT = LEN(@text);
	DECLARE @sl INT = LEN(@start);

	IF (@sl > 0 AND @tl >= @sl AND LEFT(@text, @sl)=@start)
	BEGIN
		SET @result = RIGHT(@text, @tl - @sl);
	END
	

	RETURN @result;
END