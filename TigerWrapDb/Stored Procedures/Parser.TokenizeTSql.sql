CREATE PROCEDURE [Parser].[TokenizeTSql]
	@tsql NVARCHAR(MAX),
    @errorMessage NVARCHAR(4000) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @RC_OK INT = 0;
    DECLARE @RC_ERR_UNEXPECTED_CHARACTER INT = 1;
    DECLARE @RC_ERR_END_DELIMITER_NOT_FOUND INT = 2;
    DECLARE @RC_ERR_COMMENT_END_NOT_FOUND INT = 3;
    DECLARE @RC_ERR_TOKEN_NOT_RECOGNIZED INT = 4;
    DECLARE @RC_ERR_DB INT = 100;
    
    SET @errorMessage = NULL;

    DECLARE @rc INT = @RC_OK;

    DECLARE @len INT = LEN(@tsql);
    DECLARE @i INT = 1;

    DECLARE @TT_NONE TINYINT = 0;
    DECLARE @TT_WHITESPACE TINYINT = 1;
    DECLARE @TT_COMMENT TINYINT = 2;
    DECLARE @TT_IDENTIFIER TINYINT = 3;
    DECLARE @TT_KEYWORD TINYINT = 4;
    DECLARE @TT_DELIMITER TINYINT = 5;
    DECLARE @TT_SEPARATOR TINYINT = 6;
    DECLARE @TT_OPERATOR TINYINT = 7;
    DECLARE @TT_LITERAL TINYINT = 8;
    DECLARE @TT_UNKNOWN TINYINT = 255;

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

    DECLARE @ST_SINGLE_LINE_COMMENT TINYINT = 1;
    DECLARE @ST_MULTI_LINE_COMMENT TINYINT = 2;
    DECLARE @ST_REGULAR_IDENTIFIER TINYINT = 3;
    DECLARE @ST_IDENTIFIER_IN_BRACKETS TINYINT = 4;
    DECLARE @ST_IDENTIFIER_IN_DOUBLE_QUOTES TINYINT = 5;
    DECLARE @ST_STRING TINYINT = 6;
    DECLARE @ST_UNICODE_STRING TINYINT = 7;
    DECLARE @ST_INTEGER TINYINT = 8;
    DECLARE @ST_DECIMAL TINYINT = 9;
    DECLARE @ST_MONEY TINYINT = 10;
    DECLARE @ST_REAL TINYINT = 11;
    DECLARE @ST_BINARY TINYINT = 12;
    DECLARE @ST_COMMA TINYINT = 13;
    DECLARE @ST_SEMICOLON TINYINT = 14;
    DECLARE @ST_PERIOD TINYINT = 15;
    DECLARE @ST_VARIABLE_NAME TINYINT = 16;
    DECLARE @ST_UNARY_OPERATOR TINYINT = 17;
    DECLARE @ST_BINARY_OPERATOR TINYINT = 18;
    DECLARE @ST_UNARY_OR_BINARY_OPERATOR TINYINT = 19;

    --DECLARE @lastToken TINYINT = @TT_NONE;
    DECLARE @token TINYINT = @TT_NONE;
    DECLARE @tokenText NVARCHAR(MAX) = '';
    DECLARE @tokenLen INT = 0;
    DECLARE @c NCHAR(1);
    DECLARE @nc NCHAR(1);
    DECLARE @subType TINYINT;
    DECLARE @keyword SMALLINT;
    DECLARE @ct TINYINT;
    DECLARE @nct TINYINT;
    
    DECLARE @j INT;
    DECLARE @k INT;
    DECLARE @endDelim NCHAR(1);
    DECLARE @escDelim NCHAR(2);
    DECLARE @seqLen INT;
    DECLARE @temp NVARCHAR(1000);
    DECLARE @level INT;
    DECLARE @operatorId TINYINT;

    WHILE @i <= @len
    BEGIN
        SET @c = SUBSTRING(@tsql, @i, 1);
        SET @ct = [Parser].[GetCharType](@c);

        IF @token = @TT_NONE
        BEGIN
            SET @subType = NULL;
            SET @keyword = NULL;
            SET @operatorId = NULL;
            
            IF @ct = @CT_WHITESPACE
            BEGIN
                SET @token = @TT_WHITESPACE;
                SET @seqLen = [Parser].[GetSequenceLength](@tsql, @i, @len, @CT_WHITESPACE, NULL, NULL, NULL);
                SET @tokenText = SUBSTRING(@tsql, @i, @seqLen);
                SET @i += @seqLen;                
            END
            ELSE IF @ct = @CT_DELIMITER
            BEGIN
                IF @c IN (N'(', N')')
                BEGIN
                    SET @token = @TT_DELIMITER;
                    SET @tokenText=@c;
                    SET @i += 1;
                END
                ELSE IF @c = N''''
                BEGIN
                    SET @i += 1;
                    SET @endDelim = N'''';
                    SET @escDelim = N'''''';
                    SET @j = [Parser].[FindEndDelimiter](@tsql, @i, @endDelim, @escDelim);
                    IF @j = 0
                    BEGIN
                        SELECT @rc = @RC_ERR_END_DELIMITER_NOT_FOUND, @errorMessage = N'End delimiter "' + @endDelim + '" not found. Start position: ' + LOWER(@i);  
                        RETURN @rc;
                    END
                    SET @token = @TT_LITERAL;
                    SET @subType = @ST_STRING;
                    SET @tokenText=REPLACE(SUBSTRING(@tsql, @i, @j - @i), @escDelim, @endDelim);
                    SET @i = @j + 1;
                END
                ELSE IF @c = N'['
                BEGIN
                    SET @i += 1;
                    SET @endDelim = N']';
                    SET @escDelim = N']]';
                    SET @j = [Parser].[FindEndDelimiter](@tsql, @i, @endDelim, @escDelim);
                    IF @j = 0
                    BEGIN
                        SELECT @rc = @RC_ERR_END_DELIMITER_NOT_FOUND, @errorMessage = N'End delimiter "' + @endDelim + '" not found. Start position: ' + LOWER(@i);  
                        RETURN @rc;
                    END
                    SET @token = @TT_IDENTIFIER;
                    SET @subType = @ST_IDENTIFIER_IN_BRACKETS;
                    SET @tokenText=REPLACE(SUBSTRING(@tsql, @i, @j - @i), @escDelim, @endDelim);
                    SET @i = @j + 1;
                END
                ELSE IF @c = N'"'
                BEGIN
                    SET @i += 1;
                    SET @endDelim = N'"';
                    SET @escDelim = N'""';
                    SET @j = [Parser].[FindEndDelimiter](@tsql, @i, @endDelim, @escDelim);
                    IF @j = 0
                    BEGIN
                        SELECT @rc = @RC_ERR_END_DELIMITER_NOT_FOUND, @errorMessage = N'End delimiter "' + @endDelim + '" not found. Start position: ' + LOWER(@i);  
                        RETURN @rc;
                    END
                    SET @token = @TT_IDENTIFIER;
                    SET @subType = @ST_IDENTIFIER_IN_DOUBLE_QUOTES;
                    SET @tokenText=REPLACE(SUBSTRING(@tsql, @i, @j - @i), @escDelim, @endDelim);
                    SET @i = @j + 1;
                END
            END
            ELSE IF @ct = @CT_SEPARATOR
            BEGIN
                SET @token = @TT_SEPARATOR;
                SET @tokenText = @c;
                SET @subType = CASE @c WHEN ',' THEN @ST_COMMA WHEN ';' THEN @ST_SEMICOLON WHEN '.' THEN @ST_PERIOD END;
                SET @i += 1;
                IF @subType = @ST_PERIOD AND @i <= @len
                BEGIN                    
                    -- check for numeric value
                    SET @seqLen = [Parser].[GetSequenceLength](@tsql, @i, @len, @CT_DIGIT, NULL, NULL, NULL);
                    if @seqLen > 0
                    BEGIN
                        SET @token = @TT_LITERAL;
                        SET @subType = @ST_DECIMAL;
                        SET @tokenText += SUBSTRING(@tsql, @i, @seqLen);
                        SET @i += @seqLen;
                        IF @i < @len AND LOWER(SUBSTRING(@tsql, @i, 1))='e'
                        BEGIN
                            SET @tokenText += SUBSTRING(@tsql, @i, 1);
                            SET @i += 1;
                            SET @subType = @ST_REAL;
                            IF @i < @len AND SUBSTRING(@tsql, @i, 1) IN ('+', '-')
                            BEGIN
                                SET @tokenText += SUBSTRING(@tsql, @i, 1);
                                SET @i += 1;
                            END
                            SET @seqLen = [Parser].[GetSequenceLength](@tsql, @i, @len, @CT_DIGIT, NULL, NULL, NULL);
                            IF @seqLen > 0
                            BEGIN
                                SET @tokenText += SUBSTRING(@tsql, @i, @seqLen);
                                SET @i += @seqLen;
                            END
                        END
                    END
                    SET @nc = SUBSTRING(@tsql, @i, 1);
                    SET @nct = [Parser].[GetCharType](@nc);
                    IF @nct = @CT_DIGIT
                    BEGIN
                        SET @token = @TT_LITERAL;
                        SET @subType = @ST_DECIMAL;
                        SET @tokenText += @nc;
                        SET @i += 1;
                        
                    END
                END
            END
            ELSE IF @ct = @CT_OPERATOR
            BEGIN
                SET @token = @TT_OPERATOR;
                SET @tokenText = @c;
                SET @i += 1;
                SET @nc = SUBSTRING(@tsql, @i, 1);
                SET @nct = [Parser].[GetCharType](@nc);
                IF @nct = @CT_OPERATOR
                BEGIN
                    SET @temp = @tokenText + @nc;
                    IF EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Operator]=@temp)
                    BEGIN
                        SET @tokenText = @temp;
                        SET @i += 1;
                    END
                    ELSE IF @temp='--'
                    BEGIN
                        -- single line comment
                        SET @token = @TT_COMMENT;
                        SET @subType = @ST_SINGLE_LINE_COMMENT;
                        SET @tokenText = @temp;
                        SET @i += 1;
                        SET @j = CHARINDEX(NCHAR(13), @tsql, @i);
                        SET @k = CHARINDEX(NCHAR(10), @tsql, @i);
                        IF @j = 0 OR (@k > 0 AND @k < @j)
                        BEGIN
                            SET @j = @k;
                        END
                        IF @j = 0
                        BEGIN
                            SET @j = @len + 1;
                        END
                        SET @tokenText += SUBSTRING(@tsql, @i, @j - @i);
                        SET @i = @j;
                    END
                    ELSE IF @temp='/*'
                    BEGIN                        
                        -- multi line comment
                        SET @token = @TT_COMMENT;
                        SET @subType = @ST_MULTI_LINE_COMMENT;
                        SET @tokenText = @temp;
                        SET @i += 1;
                        SET @j = CHARINDEX('*/', @tsql, @i);
                        SET @k = CHARINDEX('/*', @tsql, @i);
                        SET @level = 1;
                        WHILE @level > 0
                        BEGIN
                            if @j = 0
                            BEGIN                                
                                SELECT @rc = @RC_ERR_COMMENT_END_NOT_FOUND, @errorMessage = N'Multi line comment end not found. Start position: ' + LOWER(@i);
                                RETURN @rc;
                            END                            
                            IF @k > 0 AND @k < @j
                            BEGIN
                                SET @level += 1;
                                SET @j = @k;
                            END
                            ELSE
                            BEGIN
                                SET @level -= 1;
                            END
                            SET @tokenText += SUBSTRING(@tsql, @i, @j - @i + 2);
                            SET @i = @j + 2;
                            SET @j = CHARINDEX('*/', @tsql, @i);
                            SET @k = CHARINDEX('/*', @tsql, @i);
                        END
                    END  
                END
                IF @token = @TT_OPERATOR
                BEGIN
                    
                    DECLARE @unary BIT = 0;
                    DECLARE @binary BIT = 0;
                    SELECT @operatorId=[Id], @unary=[Unary], @binary=[Binary]
                    FROM [Parser].[Operator] 
                    WHERE [Operator]=@tokenText;
                    IF @unary=1 AND @binary=0
                    BEGIN
                        SET @subType=@ST_UNARY_OPERATOR;
                    END
                    ELSE IF @unary=0 AND @binary=1
                    BEGIN
                        SET @subType=@ST_BINARY_OPERATOR;
                    END
                    ELSE IF @unary=1 AND @binary=1
                    BEGIN
                        SET @subType=@ST_UNARY_OR_BINARY_OPERATOR;
                    END
                    
                END
            END
            ELSE IF @ct = @CT_DIGIT
            BEGIN
                SET @token = @TT_LITERAL;
                SET @subType = @ST_INTEGER;
                SET @seqLen = [Parser].[GetSequenceLength](@tsql, @i, @len, @CT_DIGIT, NULL, NULL, NULL);
                SET @tokenText = SUBSTRING(@tsql, @i, @seqLen);
                SET @i += @seqLen;
                IF (@i <= @len)
                BEGIN
                    SET @nc = SUBSTRING(@tsql, @i, 1);
                    SET @nct = [Parser].[GetCharType](@nc);
                    IF @nc = '.'
                    BEGIN
                        SET @subType = @ST_DECIMAL;
                        SET @tokenText += @nc;
                        SET @i += 1;
                        SET @seqLen = [Parser].[GetSequenceLength](@tsql, @i, @len, @CT_DIGIT, NULL, NULL, NULL);
                        SET @tokenText += SUBSTRING(@tsql, @i, @seqLen);
                        SET @i += @seqLen;
                        IF (@i <= @len)
                        BEGIN
                            SET @nc = SUBSTRING(@tsql, @i, 1);
                            SET @nct = [Parser].[GetCharType](@nc);
                        END
                        ELSE
                        BEGIN
                            SET @nc = ' ';
                        END
                    END                    
                    IF LOWER(@nc) = 'e'
                    BEGIN
                        SET @subType = @ST_REAL;
                        SET @tokenText += @nc;
                        SET @i += 1;
                        IF (@i <= @len)
                        BEGIN
                            SET @nc = SUBSTRING(@tsql, @i, 1);
                            SET @nct = [Parser].[GetCharType](@nc);
                        END
                        ELSE
                        BEGIN
                            SET @nc = ' ';
                        END
                        IF @nc IN ('+', '-')
                        BEGIN
                            SET @tokenText += @nc;
                            SET @i += 1;
                        END
                        SET @seqLen = [Parser].[GetSequenceLength](@tsql, @i, @len, @CT_DIGIT, NULL, NULL, NULL);
                        SET @tokenText += SUBSTRING(@tsql, @i, @seqLen);
                        SET @i += @seqLen;
                    END
                END
            END
            ELSE IF @ct IN (@CT_SPECIAL, @CT_LETTER)
            BEGIN
                IF @i < @len
                BEGIN
                    SET @nc = SUBSTRING(@tsql, @i + 1, 1);
                    SET @nct = [Parser].[GetCharType](@nc);
                END
                ELSE
                BEGIN
                    SET @nc = ' ';
                    SET @nct = 0;
                END
                IF @c = N'N' AND @nc = N''''
                BEGIN                    
                    SET @i += 2;
                    SET @endDelim = N'''';
                    SET @escDelim = N'''''';
                    SET @j = [Parser].[FindEndDelimiter](@tsql, @i, @endDelim, @escDelim);
                    IF @j = 0
                    BEGIN
                        SELECT @rc = @RC_ERR_END_DELIMITER_NOT_FOUND, @errorMessage = N'End delimiter "' + @endDelim + '" not found. Start position: ' + LOWER(@i);  
                        RETURN @rc;
                    END
                    SET @token = @TT_LITERAL;
                    SET @subType = @ST_UNICODE_STRING;
                    SET @tokenText=REPLACE(SUBSTRING(@tsql, @i, @j - @i), @escDelim, @endDelim);
                    SET @i = @j + 1;
                END
                ELSE IF (@c=N'$' AND (@nct=@CT_DIGIT OR @nc=N'.'))
                BEGIN                    
                    SET @token = @TT_LITERAL;
                    SET @subType = @ST_MONEY;
                    SET @tokenText = @c;
                    SET @i += 1;
                    IF @nct=@CT_DIGIT
                    BEGIN
                        SET @seqLen = [Parser].[GetSequenceLength](@tsql, @i, @len, @CT_DIGIT, NULL, NULL, NULL); 
                        SET @tokenText += SUBSTRING(@tsql, @i, @seqLen);
                        SET @i += @seqLen;
                        IF @i <= @len
                        BEGIN
                            SET @nc = SUBSTRING(@tsql, @i, 1);
                            SET @nct = [Parser].[GetCharType](@nc);
                        END
                        ELSE
                        BEGIN
                            SET @nc = ' ';
                            SET @nct = 0;
                        END
                    END
                    IF @nc=N'.'
                    BEGIN
                        SET @tokenText += @nc;
                        SET @i += 1;
                        SET @seqLen = [Parser].[GetSequenceLength](@tsql, @i, @len, @CT_DIGIT, NULL, NULL, NULL); 
                        SET @tokenText += SUBSTRING(@tsql, @i, @seqLen);
                        SET @i += @seqLen;
                    END                    
                END
                ELSE
                BEGIN                    
                    SET @token = @TT_IDENTIFIER;
                
                    SET @seqLen = [Parser].[GetSequenceLength](@tsql, @i, @len, @CT_LETTER, @CT_DIGIT, @CT_SPECIAL, NULL);                    
                    SET @tokenText = SUBSTRING(@tsql, @i, @seqLen);
                    SET @i += @seqLen;

                    -- set subtype, check keyword etc                    
                    SELECT @keyword=kw.[Id]
                    FROM [ParserEnum].[TSqlKeyword] kw
                    WHERE kw.[Name]=UPPER(@tokenText);                    
                    IF @keyword IS NOT NULL
                    BEGIN
                        SET @token = @TT_KEYWORD;
                    END
                    ELSE
                    BEGIN
                        SET @subType = CASE WHEN @tokenText LIKE N'@%' THEN @ST_VARIABLE_NAME ELSE @ST_REGULAR_IDENTIFIER END;                        
                    END
                END
            END

            IF @token <>@TT_NONE
            BEGIN
                INSERT INTO #Token ([TypeId], [SubtypeId], [KeywordId], [OperatorId], [Text])
                VALUES (@token, @subType, @keyword, @operatorId, @tokenText);
                SET @token=@TT_NONE;
            END
            ELSE
            BEGIN
                SELECT @rc = @RC_ERR_TOKEN_NOT_RECOGNIZED, 
                    @errorMessage = N'Token not recognized. Start position: ' + LOWER(@i) +  N'; Text: ' + NCHAR(13) + NCHAR(10) + SUBSTRING(@tsql, @i, 50); 
                RETURN @rc;
            END

        END
    END


    -- intentionally adding additional empty token at the end
    -- to make sure parser wouldn't run out of tokens while matching end element
    INSERT INTO #Token ([TypeId], [SubtypeId], [KeywordId], [Text]) 
    VALUES (@TT_WHITESPACE, NULL, NULL, N'');

    RETURN @rc;
END