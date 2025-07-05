
CREATE PROCEDURE [Parser].[ParseTSql]	
    @errorMessage NVARCHAR(4000) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @RC_OK INT = 0;

    DECLARE @RC_START_PARENTHESIS_NOT_FOUND INT = 1;
    DECLARE @RC_END_PARENTHESIS_NOT_FOUND INT = 2;
    DECLARE @RC_START_BLOCK_NOT_FOUND INT = 3;
    DECLARE @RC_END_BLOCK_NOT_FOUND INT = 4;
    DECLARE @RC_UNEXPECTED_END_OF_TOKENS INT = 5;
    DECLARE @RC_UNEXPECTED_TOKEN INT = 6;
    DECLARE @RC_INVALID_END_BLOCK INT = 7;
    DECLARE @RC_PARSE_ERROR INT = 20;

    DECLARE @RC_ERR_DB INT = 100;

    DECLARE @TPS_RC_OK INT = 0;
    DECLARE @TPS_RC_NOT_MATCH INT = 1;
    
    SET @errorMessage = NULL;

    DECLARE @rc INT = @RC_OK;

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

    DECLARE @BT_REGULAR_BLOCK TINYINT = 1;
    DECLARE @BT_TRY_BLOCK TINYINT = 2;
    DECLARE @BT_CATCH_BLOCK TINYINT = 3;
    DECLARE @BT_ATOMIC_BLOCK TINYINT = 4;
    DECLARE @BT_CASE_BLOCK TINYINT = 5;

    DECLARE @KW_ADD SMALLINT = 1;
    DECLARE @KW_ALL SMALLINT = 2;
    DECLARE @KW_ALTER SMALLINT = 3;
    DECLARE @KW_AND SMALLINT = 4;
    DECLARE @KW_ANY SMALLINT = 5;
    DECLARE @KW_AS SMALLINT = 6;
    DECLARE @KW_ASC SMALLINT = 7;
    DECLARE @KW_AUTHORIZATION SMALLINT = 8;
    DECLARE @KW_BACKUP SMALLINT = 9;
    DECLARE @KW_BEGIN SMALLINT = 10;
    DECLARE @KW_BETWEEN SMALLINT = 11;
    DECLARE @KW_BREAK SMALLINT = 12;
    DECLARE @KW_BROWSE SMALLINT = 13;
    DECLARE @KW_BULK SMALLINT = 14;
    DECLARE @KW_BY SMALLINT = 15;
    DECLARE @KW_CASCADE SMALLINT = 16;
    DECLARE @KW_CASE SMALLINT = 17;
    DECLARE @KW_CHECK SMALLINT = 18;
    DECLARE @KW_CHECKPOINT SMALLINT = 19;
    DECLARE @KW_CLOSE SMALLINT = 20;
    DECLARE @KW_CLUSTERED SMALLINT = 21;
    DECLARE @KW_COALESCE SMALLINT = 22;
    DECLARE @KW_COLLATE SMALLINT = 23;
    DECLARE @KW_COLUMN SMALLINT = 24;
    DECLARE @KW_COMMIT SMALLINT = 25;
    DECLARE @KW_COMPUTE SMALLINT = 26;
    DECLARE @KW_CONSTRAINT SMALLINT = 27;
    DECLARE @KW_CONTAINS SMALLINT = 28;
    DECLARE @KW_CONTAINSTABLE SMALLINT = 29;
    DECLARE @KW_CONTINUE SMALLINT = 30;
    DECLARE @KW_CONVERT SMALLINT = 31;
    DECLARE @KW_CREATE SMALLINT = 32;
    DECLARE @KW_CROSS SMALLINT = 33;
    DECLARE @KW_CURRENT SMALLINT = 34;
    DECLARE @KW_CURRENT_DATE SMALLINT = 35;
    DECLARE @KW_CURRENT_TIME SMALLINT = 36;
    DECLARE @KW_CURRENT_TIMESTAMP SMALLINT = 37;
    DECLARE @KW_CURRENT_USER SMALLINT = 38;
    DECLARE @KW_CURSOR SMALLINT = 39;
    DECLARE @KW_DATABASE SMALLINT = 40;
    DECLARE @KW_DBCC SMALLINT = 41;
    DECLARE @KW_DEALLOCATE SMALLINT = 42;
    DECLARE @KW_DECLARE SMALLINT = 43;
    DECLARE @KW_DEFAULT SMALLINT = 44;
    DECLARE @KW_DELETE SMALLINT = 45;
    DECLARE @KW_DENY SMALLINT = 46;
    DECLARE @KW_DESC SMALLINT = 47;
    DECLARE @KW_DISK SMALLINT = 48;
    DECLARE @KW_DISTINCT SMALLINT = 49;
    DECLARE @KW_DISTRIBUTED SMALLINT = 50;
    DECLARE @KW_DOUBLE SMALLINT = 51;
    DECLARE @KW_DROP SMALLINT = 52;
    DECLARE @KW_DUMP SMALLINT = 53;
    DECLARE @KW_ELSE SMALLINT = 54;
    DECLARE @KW_END SMALLINT = 55;
    DECLARE @KW_ERRLVL SMALLINT = 56;
    DECLARE @KW_ESCAPE SMALLINT = 57;
    DECLARE @KW_EXCEPT SMALLINT = 58;
    DECLARE @KW_EXEC SMALLINT = 59;
    DECLARE @KW_EXECUTE SMALLINT = 60;
    DECLARE @KW_EXISTS SMALLINT = 61;
    DECLARE @KW_EXIT SMALLINT = 62;
    DECLARE @KW_EXTERNAL SMALLINT = 63;
    DECLARE @KW_FETCH SMALLINT = 64;
    DECLARE @KW_FILE SMALLINT = 65;
    DECLARE @KW_FILLFACTOR SMALLINT = 66;
    DECLARE @KW_FOR SMALLINT = 67;
    DECLARE @KW_FOREIGN SMALLINT = 68;
    DECLARE @KW_FREETEXT SMALLINT = 69;
    DECLARE @KW_FREETEXTTABLE SMALLINT = 70;
    DECLARE @KW_FROM SMALLINT = 71;
    DECLARE @KW_FULL SMALLINT = 72;
    DECLARE @KW_FUNCTION SMALLINT = 73;
    DECLARE @KW_GOTO SMALLINT = 74;
    DECLARE @KW_GRANT SMALLINT = 75;
    DECLARE @KW_GROUP SMALLINT = 76;
    DECLARE @KW_HAVING SMALLINT = 77;
    DECLARE @KW_HOLDLOCK SMALLINT = 78;
    DECLARE @KW_IDENTITY SMALLINT = 79;
    DECLARE @KW_IDENTITY_INSERT SMALLINT = 80;
    DECLARE @KW_IDENTITYCOL SMALLINT = 81;
    DECLARE @KW_IF SMALLINT = 82;
    DECLARE @KW_IN SMALLINT = 83;
    DECLARE @KW_INDEX SMALLINT = 84;
    DECLARE @KW_INNER SMALLINT = 85;
    DECLARE @KW_INSERT SMALLINT = 86;
    DECLARE @KW_INTERSECT SMALLINT = 87;
    DECLARE @KW_INTO SMALLINT = 88;
    DECLARE @KW_IS SMALLINT = 89;
    DECLARE @KW_JOIN SMALLINT = 90;
    DECLARE @KW_KEY SMALLINT = 91;
    DECLARE @KW_KILL SMALLINT = 92;
    DECLARE @KW_LEFT SMALLINT = 93;
    DECLARE @KW_LIKE SMALLINT = 94;
    DECLARE @KW_LINENO SMALLINT = 95;
    DECLARE @KW_LOAD SMALLINT = 96;
    DECLARE @KW_MERGE SMALLINT = 97;
    DECLARE @KW_NATIONAL SMALLINT = 98;
    DECLARE @KW_NOCHECK SMALLINT = 99;
    DECLARE @KW_NONCLUSTERED SMALLINT = 100;
    DECLARE @KW_NOT SMALLINT = 101;
    DECLARE @KW_NULL SMALLINT = 102;
    DECLARE @KW_NULLIF SMALLINT = 103;
    DECLARE @KW_OF SMALLINT = 104;
    DECLARE @KW_OFF SMALLINT = 105;
    DECLARE @KW_OFFSETS SMALLINT = 106;
    DECLARE @KW_ON SMALLINT = 107;
    DECLARE @KW_OPEN SMALLINT = 108;
    DECLARE @KW_OPENDATASOURCE SMALLINT = 109;
    DECLARE @KW_OPENQUERY SMALLINT = 110;
    DECLARE @KW_OPENROWSET SMALLINT = 111;
    DECLARE @KW_OPENXML SMALLINT = 112;
    DECLARE @KW_OPTION SMALLINT = 113;
    DECLARE @KW_OR SMALLINT = 114;
    DECLARE @KW_ORDER SMALLINT = 115;
    DECLARE @KW_OUTER SMALLINT = 116;
    DECLARE @KW_OVER SMALLINT = 117;
    DECLARE @KW_PERCENT SMALLINT = 118;
    DECLARE @KW_PIVOT SMALLINT = 119;
    DECLARE @KW_PLAN SMALLINT = 120;
    DECLARE @KW_PRECISION SMALLINT = 121;
    DECLARE @KW_PRIMARY SMALLINT = 122;
    DECLARE @KW_PRINT SMALLINT = 123;
    DECLARE @KW_PROC SMALLINT = 124;
    DECLARE @KW_PROCEDURE SMALLINT = 125;
    DECLARE @KW_PUBLIC SMALLINT = 126;
    DECLARE @KW_RAISERROR SMALLINT = 127;
    DECLARE @KW_READ SMALLINT = 128;
    DECLARE @KW_READTEXT SMALLINT = 129;
    DECLARE @KW_RECONFIGURE SMALLINT = 130;
    DECLARE @KW_REFERENCES SMALLINT = 131;
    DECLARE @KW_REPLICATION SMALLINT = 132;
    DECLARE @KW_RESTORE SMALLINT = 133;
    DECLARE @KW_RESTRICT SMALLINT = 134;
    DECLARE @KW_RETURN SMALLINT = 135;
    DECLARE @KW_REVERT SMALLINT = 136;
    DECLARE @KW_REVOKE SMALLINT = 137;
    DECLARE @KW_RIGHT SMALLINT = 138;
    DECLARE @KW_ROLLBACK SMALLINT = 139;
    DECLARE @KW_ROWCOUNT SMALLINT = 140;
    DECLARE @KW_ROWGUIDCOL SMALLINT = 141;
    DECLARE @KW_RULE SMALLINT = 142;
    DECLARE @KW_SAVE SMALLINT = 143;
    DECLARE @KW_SCHEMA SMALLINT = 144;
    DECLARE @KW_SECURITYAUDIT SMALLINT = 145;
    DECLARE @KW_SELECT SMALLINT = 146;
    DECLARE @KW_SEMANTICKEYPHRASETABLE SMALLINT = 147;
    DECLARE @KW_SEMANTICSIMILARITYDETAILSTABLE SMALLINT = 148;
    DECLARE @KW_SEMANTICSIMILARITYTABLE SMALLINT = 149;
    DECLARE @KW_SESSION_USER SMALLINT = 150;
    DECLARE @KW_SET SMALLINT = 151;
    DECLARE @KW_SETUSER SMALLINT = 152;
    DECLARE @KW_SHUTDOWN SMALLINT = 153;
    DECLARE @KW_SOME SMALLINT = 154;
    DECLARE @KW_STATISTICS SMALLINT = 155;
    DECLARE @KW_SYSTEM_USER SMALLINT = 156;
    DECLARE @KW_TABLE SMALLINT = 157;
    DECLARE @KW_TABLESAMPLE SMALLINT = 158;
    DECLARE @KW_TEXTSIZE SMALLINT = 159;
    DECLARE @KW_THEN SMALLINT = 160;
    DECLARE @KW_TO SMALLINT = 161;
    DECLARE @KW_TOP SMALLINT = 162;
    DECLARE @KW_TRAN SMALLINT = 163;
    DECLARE @KW_TRANSACTION SMALLINT = 164;
    DECLARE @KW_TRIGGER SMALLINT = 165;
    DECLARE @KW_TRUNCATE SMALLINT = 166;
    DECLARE @KW_TRY_CONVERT SMALLINT = 167;
    DECLARE @KW_TSEQUAL SMALLINT = 168;
    DECLARE @KW_UNION SMALLINT = 169;
    DECLARE @KW_UNIQUE SMALLINT = 170;
    DECLARE @KW_UNPIVOT SMALLINT = 171;
    DECLARE @KW_UPDATE SMALLINT = 172;
    DECLARE @KW_UPDATETEXT SMALLINT = 173;
    DECLARE @KW_USE SMALLINT = 174;
    DECLARE @KW_USER SMALLINT = 175;
    DECLARE @KW_VALUES SMALLINT = 176;
    DECLARE @KW_VARYING SMALLINT = 177;
    DECLARE @KW_VIEW SMALLINT = 178;
    DECLARE @KW_WAITFOR SMALLINT = 179;
    DECLARE @KW_WHEN SMALLINT = 180;
    DECLARE @KW_WHERE SMALLINT = 181;
    DECLARE @KW_WHILE SMALLINT = 182;
    DECLARE @KW_WITH SMALLINT = 183;
    DECLARE @KW_WITHIN SMALLINT = 184;
    DECLARE @KW_WRITETEXT SMALLINT = 185;
    DECLARE @KW_ATOMIC SMALLINT = 186;
    DECLARE @KW_CONVERSATION SMALLINT = 187;
    DECLARE @KW_DIALOG SMALLINT = 188;
    DECLARE @KW_CATCH SMALLINT = 189;
    DECLARE @KW_TRY SMALLINT = 190;
    DECLARE @KW_THROW SMALLINT = 191;
    DECLARE @KW_FILETABLE SMALLINT = 192;
    DECLARE @KW_MORE_THAN_ONE SMALLINT = 32767;

    DECLARE @parLevel SMALLINT = 0;
    DECLARE @blockLevel SMALLINT = 0;
    
    DECLARE @startTokenId INT;
    DECLARE @endTokenId INT;

    DECLARE @typeId TINYINT;
    DECLARE @keywordId SMALLINT;
    DECLARE @subtypeId SMALLINT;
    DECLARE @text NVARCHAR(MAX);
    
    DECLARE @nextTokenId INT;
    DECLARE @nextTypeId TINYINT;
    DECLARE @nextKeywordId SMALLINT;
    DECLARE @nextSubtypeId SMALLINT;
    DECLARE @nextText NVARCHAR(MAX);

    DECLARE @tokenId INT = (SELECT MIN([Id]) FROM #Token);
    DECLARE @lastTokenId INT = (SELECT MAX([Id]) FROM #Token);

    -- First pass: identify parentheses

    WHILE @tokenId IS NOT NULL
    BEGIN
        SELECT @typeId=[TypeId], @keywordId=[KeywordId], @subtypeId=[SubtypeId], @text=[Text]
        FROM #Token WHERE [Id]=@tokenId;

        IF @typeId=@TT_DELIMITER
        BEGIN
            IF @text = N'('
            BEGIN
                SET @parLevel += 1;
                UPDATE #Token 
                SET [Level]=@parLevel
                WHERE [Id]=@tokenId;
            END
            ELSE IF @text = N')'                
            BEGIN
                SELECT @startTokenId=[Id]
                FROM #Token 
                WHERE [Level]=@parLevel AND [Id] < @tokenId AND [EndTokenId] IS NULL;
                IF @startTokenId IS NULL
                BEGIN
                    SELECT @rc=@RC_START_PARENTHESIS_NOT_FOUND, @errorMessage='Start parenthesis not found (TokenId: ' + LOWER(@tokenId) + ')';
                    RETURN @rc;
                END
                UPDATE #Token 
                SET [Level]=@parLevel, [StartTokenId]=@startTokenId
                WHERE [Id]=@tokenId;
                UPDATE #Token 
                SET [EndTokenId]=@tokenId
                WHERE [Id]=@startTokenId;
                SET @parLevel -= 1;
            END
        END
        SELECT @tokenId=MIN([Id]) FROM #Token WHERE [Id]>@tokenId;
    END

    IF @parLevel > 0
    BEGIN
        SELECT @rc=@RC_END_PARENTHESIS_NOT_FOUND, @errorMessage='End parenthesis not found';
        RETURN @rc;
    END

    DECLARE @blockTypeId TINYINT;
    DECLARE @seqStartTokenId INT;
    DECLARE @seqEndTokenId INT;
    DECLARE @startBlockTypeId TINYINT;

    -- Second  pass: identify blocks
    SELECT @tokenId=MIN([Id]) FROM #Token;
    
    WHILE @tokenId IS NOT NULL
    BEGIN
        SELECT @typeId=[TypeId], @keywordId=[KeywordId], @subtypeId=[SubtypeId], @text=[Text]
        FROM #Token WHERE [Id]=@tokenId;

        IF @typeId=@TT_KEYWORD
        BEGIN
            SELECT TOP(1) @nextTokenId=[Id], @nextTypeId=[TypeId], @nextKeywordId=[KeywordId], @nextSubtypeId=[SubtypeId], @nextText=[Text]
            FROM #Token
            WHERE [Id] > @tokenId AND [TypeId] NOT IN (@TT_WHITESPACE, @TT_COMMENT)
            ORDER BY [Id];

            IF @keywordId=@KW_BEGIN
            BEGIN
                IF @nextTokenId IS NULL
                BEGIN                    
                    SELECT @rc=@RC_UNEXPECTED_END_OF_TOKENS, @errorMessage='Unexpected end of tokens (TokenId: ' + LOWER(@tokenId) + ')';
                    RETURN @rc;
                END
                IF @nextTypeId<>@TT_KEYWORD OR @nextKeywordId NOT IN (@KW_CONVERSATION, @KW_DIALOG, @KW_TRAN, @KW_TRANSACTION, @KW_DISTRIBUTED)
                BEGIN
                    -- begin block                    
                    SET @blockLevel += 1;
                    SET @blockTypeId = CASE WHEN @nextTypeId<>@TT_KEYWORD THEN @BT_REGULAR_BLOCK 
                    ELSE CASE @nextKeywordId WHEN @KW_TRY THEN @BT_TRY_BLOCK WHEN @KW_CATCH THEN @BT_CATCH_BLOCK WHEN @KW_ATOMIC THEN @BT_ATOMIC_BLOCK ELSE @BT_REGULAR_BLOCK END END;

                    SET @seqStartTokenId = @tokenId;
                    SET @seqEndTokenId = CASE WHEN @blockTypeId=@BT_REGULAR_BLOCK THEN @tokenId ELSE @nextTokenId END;

                    IF @blockTypeId=@BT_ATOMIC_BLOCK
                    BEGIN
                        SELECT TOP(1) @nextTokenId=[Id], @nextTypeId=[TypeId], @nextKeywordId=[KeywordId], @nextSubtypeId=[SubtypeId], @nextText=[Text]
                        FROM #Token
                        WHERE [Id] > @nextTokenId AND [TypeId] NOT IN (@TT_WHITESPACE, @TT_COMMENT)
                        ORDER BY [Id];
                        IF @nextTokenId IS NULL
                        BEGIN                    
                            SELECT @rc=@RC_UNEXPECTED_END_OF_TOKENS, @errorMessage='Unexpected end of tokens (TokenId: ' + LOWER(@tokenId) + ')';
                            RETURN @rc;
                        END
                        IF @nextTypeId=@TT_KEYWORD AND @nextKeywordId=@KW_WITH
                        BEGIN
                            SELECT TOP(1) @nextTokenId=[Id], @nextTypeId=[TypeId], @nextKeywordId=[KeywordId], @nextSubtypeId=[SubtypeId], @nextText=[Text], @endTokenId=[EndTokenId]
                            FROM #Token
                            WHERE [Id] > @nextTokenId AND [TypeId] NOT IN (@TT_WHITESPACE, @TT_COMMENT)
                            ORDER BY [Id];
                            IF @nextTokenId IS NULL
                            BEGIN                    
                                SELECT @rc=@RC_UNEXPECTED_END_OF_TOKENS, @errorMessage='Unexpected end of tokens (TokenId: ' + LOWER(@tokenId) + ')';
                                RETURN @rc;
                            END
                            IF @nextTypeId<>@TT_DELIMITER OR @nextText<>N'(' OR @endTokenId IS NULL
                            BEGIN
                                SELECT @rc=@RC_UNEXPECTED_TOKEN, @errorMessage='Unexpected token (TokenId: ' + LOWER(@nextTokenId) + ')';
                                RETURN @rc;
                            END
                             SET @seqEndTokenId=@endTokenId;
                        END
                    END

                    UPDATE #Token 
                    SET [Level]=@blockLevel, [BlockTypeId]=@blockTypeId, [SeqStartTokenId]=@tokenId, [SeqEndTokenId]=@seqEndTokenId
                    WHERE [Id]=@tokenId;
                    SET @tokenId=@seqEndTokenId;
                END
            END
            ELSE IF @keywordId=@KW_CASE
            BEGIN
                SET @blockLevel += 1;
                SET @blockTypeId = @BT_CASE_BLOCK;
                SET @seqStartTokenId = @tokenId;
                SET @seqEndTokenId = @tokenId;
                UPDATE #Token 
                SET [Level]=@blockLevel, [BlockTypeId]=@blockTypeId, [SeqStartTokenId]=@tokenId, [SeqEndTokenId]=@seqEndTokenId
                WHERE [Id]=@tokenId;
                SET @tokenId=@seqEndTokenId;
            END
            ELSE IF @keywordId=@KW_END
            BEGIN
                IF @nextTokenId IS NULL OR @nextTypeId<>@TT_KEYWORD OR @nextKeywordId NOT IN (@KW_CONVERSATION)
                BEGIN
                    -- end block                    
                    SELECT @startTokenId=[Id], @startBlockTypeId=[BlockTypeId]
                    FROM #Token 
                    WHERE [TypeId]=@TT_KEYWORD AND [Level]=@blockLevel AND [Id] < @tokenId AND [EndTokenId] IS NULL;
                    
                    IF @startTokenId IS NULL OR @startBlockTypeId IS NULL
                    BEGIN
                        SELECT @rc=@RC_START_BLOCK_NOT_FOUND, @errorMessage='Block start not found (TokenId: ' + LOWER(@tokenId) + ')';
                        RETURN @rc;
                    END
                    SET @blockTypeId=@BT_REGULAR_BLOCK;
                    SET @seqStartTokenId = @tokenId;
                    SET @seqEndTokenId = @tokenId;
                    IF @nextTokenId IS NOT NULL AND @nextTypeId=@TT_KEYWORD AND @nextKeywordId IN (@KW_TRY, @KW_CATCH)
                    BEGIN
                        SET @blockTypeId=CASE WHEN @nextKeywordId=@KW_TRY THEN @BT_TRY_BLOCK ELSE @BT_CATCH_BLOCK END;
                        SET @seqEndTokenId=@nextTokenId;
                    END

                    IF @startBlockTypeId=@BT_ATOMIC_BLOCK AND @blockTypeId=@BT_REGULAR_BLOCK
                    BEGIN
                        SET @blockTypeId=@BT_ATOMIC_BLOCK;
                    END
                    IF @startBlockTypeId=@BT_CASE_BLOCK AND @blockTypeId=@BT_REGULAR_BLOCK
                    BEGIN
                        SET @blockTypeId=@BT_CASE_BLOCK;
                    END
                    IF @startBlockTypeId<>@blockTypeId
                    BEGIN
                        SELECT @rc=@RC_INVALID_END_BLOCK, @errorMessage='Invalid end block type (TokenId: ' + LOWER(@tokenId) + ')';
                        RETURN @rc;                        
                    END

                    UPDATE #Token 
                    SET [Level]=@blockLevel, [StartTokenId]=@startTokenId, [BlockTypeId]=@blockTypeId, [SeqStartTokenId]=@tokenId, [SeqEndTokenId]=@seqEndTokenId
                    WHERE [Id]=@tokenId;

                    UPDATE #Token 
                    SET [EndTokenId]=@tokenId
                    WHERE [Id]=@startTokenId;
                    
                    SET @blockLevel -= 1;                    
                    SET @tokenId=@seqEndTokenId;
                END
            END
        END

        SELECT @tokenId=MIN([Id]) FROM #Token WHERE [Id]>@tokenId;
    END
    
    IF @blockLevel > 0
    BEGIN
        SELECT @rc=@RC_END_BLOCK_NOT_FOUND, @errorMessage='Block end not found';
        RETURN @rc;
    END

    DROP TABLE IF EXISTS #StartKeyword;
    DROP TABLE IF EXISTS #Sequence;    


    CREATE TABLE #StartKeyword
    (
        [Id] SMALLINT NOT NULL PRIMARY KEY,
        [Name] VARCHAR(50) NOT NULL UNIQUE
    );

    CREATE TABLE #Sequence
    (
        [Id] SMALLINT NOT NULL IDENTITY (1, 1) PRIMARY KEY,
        [SequenceId] SMALLINT NOT NULL  UNIQUE
    );    

    INSERT INTO #StartKeyword ([Id], [Name])
    SELECT DISTINCT kw.[Id], kw.[Name]
    FROM [Parser].[TSqlSeqElement] el
    JOIN [Parser].[TSqlSequence] seq ON el.[SequenceId]=seq.[Id]
    JOIN [ParserEnum].[TSqlStatementType] st ON seq.[StatementTypeId]=st.[Id]
    JOIN [ParserEnum].[TSqlKeyword] kw ON kw.[Id]=el.[KeywordId]
    WHERE el.[IsStartElement]=1;

    DECLARE @id SMALLINT;
    DECLARE @sequenceId SMALLINT = NULL;

    -- Third pass: identify statements
    SELECT @tokenId=MIN(t.[Id]) 
    FROM #Token t 
    JOIN #StartKeyword sk ON sk.[Id]=t.[KeywordId]
    WHERE t.[TypeId]=@TT_KEYWORD;

    DECLARE @tpsRc INT;
    DECLARE @parentStatementId INT;
    DECLARE @parentStatementPartId TINYINT;
    DECLARE @tpsLastTokenId INT;
    DECLARE @isFinished BIT;
    DECLARE @statementSeparatorTokenId INT;
    DECLARE @tpsErrorMessage NVARCHAR(4000);

    WHILE @tokenId IS NOT NULL
    BEGIN        
        --PRINT('Token Id: ' + LOWER(@tokenId));
        TRUNCATE TABLE #Sequence;

        INSERT INTO #Sequence ([SequenceId])
        SELECT seq.[Id]
        FROM #Token t
        JOIN [Parser].[TSqlSeqElement] el ON el.[IsStartElement]=1 AND el.[KeywordId]=t.[KeywordId]
        JOIN [Parser].[TSqlSequence] seq ON el.[SequenceId]=seq.[Id]
        JOIN [ParserEnum].[TSqlStatementType] st ON seq.[StatementTypeId]=st.[Id]
        JOIN [ParserEnum].[TSqlKeyword] kw ON kw.[Id]=el.[KeywordId]
        WHERE t.[Id]=@tokenId
        ORDER BY seq.[Precedence], seq.[Id];
        --PRINT('Number of sequences: ' + LOWER(@@ROWCOUNT));

        SELECT TOP(1) @id=[Id], @sequenceId=[SequenceId]
        FROM #Sequence
        ORDER BY [Id];

        WHILE @sequenceId IS NOT NULL
        BEGIN
            --PRINT('Sequence Id: ' + LOWER(@sequenceId) + ' (' + LOWER(@id) + ')');
            EXEC @tpsRc = [Parser].[TryParseSequence] @tokenId, @sequenceId, @parentStatementId, @parentStatementPartId, 
                @tpsLastTokenId OUTPUT, @isFinished OUTPUT, @statementSeparatorTokenId OUTPUT, @tpsErrorMessage OUTPUT;
            IF @tpsRC=@TPS_RC_OK
            BEGIN
                --PRINT(N'Match t: ' + LOWER(@tokenId) + N' - ' + LOWER(@tpsLastTokenId));
                SELECT @tokenId = @tpsLastTokenId;
                BREAK;
            END

            IF @tpsRC<>@TPS_RC_NOT_MATCH
            BEGIN
                SET @errorMessage = N'Unexpected parsing result: ' + LOWER(@tpsRC) + N' - ' + ISNULL(@tpsErrorMessage, '<NULL>')
                PRINT(@errorMessage);
                SET @rc=@RC_PARSE_ERROR;
                RETURN @rc;
            END
            --PRINT('Not match');
            SET @sequenceId=NULL;
            SELECT TOP(1) @id=[Id], @sequenceId=[SequenceId]
            FROM #Sequence
            WHERE [Id] > @id
            ORDER BY [Id];    
            --PRINT('New sequence Id: ' + ISNULL(LOWER(@sequenceId), '<NULL>') + ' (' + ISNULL(LOWER(@id), '<NULL>') + ')');
        END
        
        SELECT @tokenId=MIN(t.[Id]) 
        FROM #Token t 
        JOIN #StartKeyword sk ON sk.[Id]=t.[KeywordId]
        WHERE t.[TypeId]=@TT_KEYWORD AND t.[Id] > @tokenId;
        --PRINT('New token Id: ' + ISNULL(LOWER(@tokenId), '<NULL>'));
    END

    DROP TABLE IF EXISTS #StartKeyword;
    DROP TABLE IF EXISTS #Sequence;    

    RETURN @rc;
END