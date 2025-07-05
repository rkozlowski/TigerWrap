
CREATE FUNCTION [Parser].[FindEndDelimiter]
(
	@text NVARCHAR(MAX),
    @startPos INT,
    @delimiter NCHAR(1),
    @escaped NCHAR(2)
)
RETURNS INT
AS
BEGIN
	DECLARE @dPos INT = CHARINDEX(@delimiter, @text, @startPos);
    DECLARE @escPos INT = CHARINDEX(@escaped, @text, @startPos);
    WHILE @dPos > 0 AND @escPos > 0 AND @dPos = @escPos
    BEGIN
        SET @startPos = @escPos + 2;
        SET @dPos = CHARINDEX(@delimiter, @text, @startPos);
        SET @escPos = CHARINDEX(@escaped, @text, @startPos);
    END
    
	RETURN @dPos;
END