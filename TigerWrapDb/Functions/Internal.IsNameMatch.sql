
CREATE FUNCTION [Internal].[IsNameMatch]
(
	@name NVARCHAR(128),
    @matchType TINYINT,
    @pattern NVARCHAR(200),
    @escChar NCHAR(1)
)
RETURNS BIT
AS
BEGIN
	
	DECLARE @result BIT = 0;

    DECLARE @NM_EXACT_MATCH TINYINT = 1;
    DECLARE @NM_PREFIX TINYINT = 2;
    DECLARE @NM_SUFFIX TINYINT = 3;
    DECLARE @NM_LIKE TINYINT = 4;
    DECLARE @NM_ANY TINYINT = 255;

    DECLARE @patternLen INT = LEN(@pattern);

    IF @matchType=@NM_EXACT_MATCH AND NULLIF(LTRIM(@pattern), N'') IS NOT NULL
    BEGIN
        SET @result = CASE WHEN @name=@pattern THEN 1 ELSE 0 END;
    END
    ELSE IF @matchType=@NM_PREFIX AND NULLIF(LTRIM(@pattern), N'') IS NOT NULL
    BEGIN
        SET @result = CASE WHEN LEFT(@name, @patternLen)=@pattern THEN 1 ELSE 0 END;
    END
    ELSE IF @matchType=@NM_SUFFIX AND NULLIF(LTRIM(@pattern), N'') IS NOT NULL
    BEGIN
        SET @result = CASE WHEN RIGHT(@name, @patternLen)=@pattern THEN 1 ELSE 0 END;
    END
    ELSE IF @matchType=@NM_LIKE AND NULLIF(LTRIM(@pattern), N'') IS NOT NULL
    BEGIN
        IF @escChar IS NOT NULL
        BEGIN
            SET @result = CASE WHEN @name LIKE @pattern ESCAPE @escChar THEN 1 ELSE 0 END;
        END
        ELSE
        BEGIN
            SET @result = CASE WHEN @name LIKE @pattern THEN 1 ELSE 0 END;
        END
    END
    ELSE IF @matchType=@NM_ANY
    BEGIN
        SET @result = 1;
    END
	
	RETURN @result;

END