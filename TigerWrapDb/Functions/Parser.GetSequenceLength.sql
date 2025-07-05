

CREATE FUNCTION [Parser].[GetSequenceLength]
(
	@text NVARCHAR(MAX),
    @startPos INT,
    @len INT,
    @charType1 TINYINT,
    @charType2 TINYINT = NULL,
    @charType3 TINYINT = NULL,
    @charType4 TINYINT = NULL
)
RETURNS INT
AS
BEGIN
	DECLARE @seqLen INT = 0
    IF @startPos <= @len
    BEGIN
        DECLARE @c NCHAR(1) = SUBSTRING(@text, @startPos, 1);
        DECLARE @ct TINYINT = (SELECT m.[TypeId] FROM [Parser].[CharTypeMap] m WHERE [Char]=@c);
        WHILE @ct IS NOT NULL AND @ct IN (@charType1, ISNULL(@charType2, 255), ISNULL(@charType3, 255), ISNULL(@charType4, 255))
        BEGIN
            SET @seqLen += 1;
            SET @ct = NULL;
            SET @startPos += 1;
            IF @startPos <= @len
            BEGIN
                SET @c = SUBSTRING(@text, @startPos, 1);
                SET @ct = (SELECT m.[TypeId] FROM [Parser].[CharTypeMap] m WHERE [Char]=@c);
            END            
        END
    END
    
	RETURN @seqLen;
END