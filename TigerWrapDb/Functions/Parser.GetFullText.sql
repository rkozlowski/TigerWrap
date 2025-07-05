CREATE FUNCTION [Parser].[GetFullText]
(
	@text NVARCHAR(MAX), 
    @subtype TINYINT
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @result NVARCHAR(MAX) = '';

	DECLARE @ST_IDENTIFIER_IN_BRACKETS TINYINT = 4;
    DECLARE @ST_IDENTIFIER_IN_DOUBLE_QUOTES TINYINT = 5;
    DECLARE @ST_STRING TINYINT = 6;
    DECLARE @ST_UNICODE_STRING TINYINT = 7;

    IF @subtype IN (@ST_IDENTIFIER_IN_BRACKETS, @ST_IDENTIFIER_IN_DOUBLE_QUOTES, @ST_STRING, @ST_UNICODE_STRING)
    BEGIN
        IF @subtype=@ST_UNICODE_STRING
        BEGIN
            SET @result=N'N'
        END
        DECLARE @end NCHAR(1);
        DECLARE @esc NCHAR(2);
        IF @subtype = @ST_IDENTIFIER_IN_BRACKETS
        BEGIN
            SET @result += N'['
            SET @end = N']';
        END
        ELSE IF @subtype = @ST_IDENTIFIER_IN_DOUBLE_QUOTES
        BEGIN
            SET @result += N'"'
            SET @end = N'"';
        END
        ELSE
        BEGIN
            SET @result += N''''
            SET @end = N'''';
        END
        SET @esc=@end + @end;
        SET @result += REPLACE(@text, @end, @esc) + @end;
    END
    ELSE
    BEGIN
        SET @result = @text;
    END

	RETURN @result
END