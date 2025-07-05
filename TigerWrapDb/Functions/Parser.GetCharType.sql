
CREATE FUNCTION [Parser].[GetCharType]
(
	@c NCHAR(1)
)
RETURNS TINYINT
AS
BEGIN
	DECLARE @result TINYINT;

    DECLARE @CT_UNKNOWN TINYINT = 0;
    DECLARE @CT_LETTER TINYINT = 1;
    DECLARE @CT_UNICODE_LETTER TINYINT = 2;
    DECLARE @CT_DIGIT TINYINT = 3;
    DECLARE @CT_UNICODE_DIGIT TINYINT = 4;
    DECLARE @CT_OPERATOR TINYINT = 5;
    DECLARE @CT_SEPARATOR TINYINT = 6;
    DECLARE @CT_DELIMITER TINYINT = 7;
    DECLARE @CT_SPECIAL TINYINT = 8;
    DECLARE @CT_WHITESPACE TINYINT = 9;

    IF [Parser].[IsLetter](@c)=1 
    BEGIN
        SET @result = @CT_LETTER;
    END
    ELSE IF [Parser].[IsDigit](@c)=1
    BEGIN
        SET @result = @CT_DIGIT;
    END
    ELSE IF [Parser].[IsWhitespace](@c)=1
    BEGIN
        SET @result = @CT_WHITESPACE;
    END
    ELSE IF [Parser].[IsOperator](@c)=1
    BEGIN
        SET @result = @CT_OPERATOR;
    END
    ELSE IF [Parser].[IsSeparator](@c)=1
    BEGIN
        SET @result = @CT_SEPARATOR;
    END
    ELSE IF [Parser].[IsDelimiter](@c)=1
    BEGIN
        SET @result = @CT_DELIMITER;
    END
    ELSE IF [Parser].[IsSpecial](@c)=1
    BEGIN
        SET @result = @CT_SPECIAL;
    END
    ELSE
    BEGIN
        SET @result = @CT_UNKNOWN;
    END
    
    RETURN @result;
END