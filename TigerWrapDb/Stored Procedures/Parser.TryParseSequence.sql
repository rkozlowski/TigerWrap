

CREATE PROCEDURE [Parser].[TryParseSequence]
    @tokenId INT,
    @sequenceId SMALLINT,
    @parentStatementId INT,
    @parentStatementPartId TINYINT,
    @lastTokenId INT OUTPUT,
    @isFinished BIT OUTPUT,
    @statementSeparatorTokenId INT OUTPUT,
    @errorMessage NVARCHAR(4000) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

    --PRINT(N'[Parser].[TryParseSequence] @tokenId: ' + LOWER(@tokenId) + N'; @sequenceId: ' + LOWER(@sequenceId));
	--PRINT(N'[Parser].[TryParseSequence] @parentStatementId: ' + ISNULL(LOWER(@parentStatementId), '<NULL>') + N'; @parentStatementPartId: ' + ISNULL(LOWER(@parentStatementPartId), '<NULL>'));

    DECLARE @RC_OK INT = 0;
    DECLARE @RC_NOT_MATCH INT = 1;

    DECLARE @RC_ERR_DATA INT = 10;

    DECLARE @RC_ERR_DB INT = 100;
    
    SELECT @lastTokenId=NULL, @isFinished=0, @statementSeparatorTokenId=NULL,  @errorMessage=NULL;

    DECLARE @rc INT = @RC_NOT_MATCH;

    DECLARE @startTokenId INT = @tokenId;

    DECLARE @ET_KEYWORD TINYINT = 1;
    DECLARE @ET_IDENTIFIER TINYINT = 2;
    DECLARE @ET_OPERATOR TINYINT = 3;
    DECLARE @ET_SEPARATOR TINYINT = 4;
    DECLARE @ET_DELIMITER TINYINT = 5;
    DECLARE @ET_STATEMENT TINYINT = 6;
    DECLARE @ET_SEQUENCE_OF_STATEMENTS TINYINT = 7;
    DECLARE @ET_BLOCK TINYINT = 8;
    DECLARE @ET_LITERAL_STRING TINYINT = 9;
    DECLARE @ET_SEQUENCE TINYINT = 10;
    DECLARE @ET_END TINYINT = 11;
    DECLARE @ET_LITERAL_INT TINYINT = 12;
    DECLARE @ET_VARIABLE_NAME TINYINT = 13;
    DECLARE @ET_SPECIAL_SEQUENCE TINYINT = 14;
    DECLARE @ET_LITERAL TINYINT = 15;

    DECLARE @SQT_NORMAL TINYINT = 1;
    DECLARE @SQT_ANY_STATEMENT TINYINT = 2;
    DECLARE @SQT_BLOCK_STATEMENT TINYINT = 3;
    DECLARE @SQT_SEQUENCE_OF_STATEMENTS TINYINT = 4;
    DECLARE @SQT_TWO_PART_IDENTIFIER TINYINT = 5;
    DECLARE @SQT_THREE_PART_IDENTIFIER TINYINT = 6;
    DECLARE @SQT_MORE_TOKENS TINYINT = 7;
    DECLARE @SQT_LABEL TINYINT = 8;
    DECLARE @SQT_BEGIN_BLOCK TINYINT = 9;
    DECLARE @SQT_END_BLOCK TINYINT = 10;
    DECLARE @SQT_SEQUENCE_IN_PARENTHESES TINYINT = 11;
    DECLARE @SQT_FOUR_PART_IDENTIFIER TINYINT = 12;
    DECLARE @SQT_SCALAR_EXPRESSION TINYINT = 13;
    DECLARE @SQT_OUTPUT_CLAUSE TINYINT = 14;
    DECLARE @SQT_CASE_EXPRESSION TINYINT = 15;

    DECLARE @SP_IDENTIFIER TINYINT = 1;
    DECLARE @SP_START_OF_PARAMETER_LIST TINYINT = 2;
    DECLARE @SP_DEFINITION TINYINT = 3;
    DECLARE @SP_CHILD_STATEMENT TINYINT = 4;

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

    DECLARE @TST_SINGLE_LINE_COMMENT TINYINT = 1;
    DECLARE @TST_MULTI_LINE_COMMENT TINYINT = 2;
    DECLARE @TST_REGULAR_IDENTIFIER TINYINT = 3;
    DECLARE @TST_IDENTIFIER_IN_BRACKETS TINYINT = 4;
    DECLARE @TST_IDENTIFIER_IN_DOUBLE_QUOTES TINYINT = 5;
    DECLARE @TST_STRING TINYINT = 6;
    DECLARE @TST_UNICODE_STRING TINYINT = 7;
    DECLARE @TST_INTEGER TINYINT = 8;
    DECLARE @TST_DECIMAL TINYINT = 9;
    DECLARE @TST_MONEY TINYINT = 10;
    DECLARE @TST_REAL TINYINT = 11;
    DECLARE @TST_BINARY TINYINT = 12;
    DECLARE @TST_COMMA TINYINT = 13;
    DECLARE @TST_SEMICOLON TINYINT = 14;
    DECLARE @TST_PERIOD TINYINT = 15;
    DECLARE @TST_VARIABLE_NAME TINYINT = 16;

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

    DECLARE @elementId INT;

    DECLARE @typeId [tinyint];
    --DECLARE @sequenceId [smallint];
    --DECLARE @isStartElement [bit];
    DECLARE @nextElementId [int];
    DECLARE @altElementId [int];
    DECLARE @keywordId [smallint];
    DECLARE @operatorId [tinyint];
    DECLARE @sequenceTypeId [tinyint];
    DECLARE @statementPartId [tinyint];
    DECLARE @tokenTypeId [tinyint];
    DECLARE @tokenSubtypeId [tinyint];
    DECLARE @stringValue [nvarchar](200);
    DECLARE @intValue [bigint];

    DECLARE @tkTypeId TINYINT;
    DECLARE @tkKeywordId SMALLINT;
    DECLARE @tkSubtypeId SMALLINT;
    DECLARE @tkText NVARCHAR(MAX);
    DECLARE @tkLevel SMALLINT;
    DECLARE @tkStartTokenId INT;
    DECLARE @tkEndTokenId INT;
    DECLARE @tkBlockTypeId TINYINT;
    DECLARE @tkSeqStartTokenId INT;
    DECLARE @tkSeqEndTokenId INT;
    DECLARE @tkSeqTypeId TINYINT;
    DECLARE @tkOperatorId TINYINT;
    DECLARE @match BIT = 0;
    DECLARE @done BIT = 0;
    
    SELECT @elementId=MIN(el.[Id])
    FROM [Parser].[TSqlSeqElement] el
    WHERE el.[SequenceId]=@sequenceId;

    --PRINT('Get token details');
    SELECT @tkTypeId=tk.[TypeId], @tkKeywordId=tk.[KeywordId], @tkSubtypeId=tk.[SubtypeId], @tkText=tk.[Text], @tkLevel=tk.[Level], @tkStartTokenId=tk.[StartTokenId],
        @tkEndTokenId=tk.[EndTokenId], @tkBlockTypeId=tk.[BlockTypeId], @tkSeqStartTokenId=tk.[SeqStartTokenId], @tkSeqEndTokenId=tk.[SeqEndTokenId], 
        @tkSeqTypeId=tk.[SeqTypeId], @tkOperatorId=tk.[OperatorId]
    FROM #Token tk
    WHERE tk.[Id]=@tokenId;

    DECLARE @statementId INT = NULL;
    DECLARE @statementTypeId SMALLINT = NULL;
    DECLARE @isNewStatement BIT = 0;
    DECLARE @lastTokenIdBeforeChildStatement INT = NULL;

    SELECT @statementTypeId=st.[Id]
    FROM [Parser].[TSqlSequence] seq 
    JOIN [ParserEnum].[TSqlStatementType] st ON seq.[StatementTypeId]=st.[Id]
    WHERE seq.[Id]=@sequenceId;

    IF @statementTypeId IS NOT NULL
    BEGIN
		--PRINT('INSERT Statement ' + LOWER(@statementTypeId) + ', ' + LOWER(@tokenId));
        INSERT INTO #Statement ([TypeId], [StartTokenId])
        VALUES (@statementTypeId, @tokenId);
        SET @statementId=SCOPE_IDENTITY();
        SET @isNewStatement=1;
    END
    ELSE
    BEGIN
        SELECT @statementId=MAX([Id])
        FROM #Statement;
    END

    IF @statementId IS NULL
    BEGIN
        SELECT @rc=@RC_ERR_DATA, @errorMessage=N'Statement Id not set. Sequence Id: ' + @sequenceId;
        RETURN @rc;
    END

    DECLARE @tpsRc INT;
    DECLARE @tpsParentStatementId INT;
    DECLARE @tpsParentStatementPartId TINYINT;
    DECLARE @tpsLastTokenId INT;
    DECLARE @tpsIsFinished BIT;
    DECLARE @tpsStatementSeparatorTokenId INT;
    DECLARE @tpsErrorMessage NVARCHAR(4000);
    DECLARE @tpsSequenceId SMALLINT;
    DECLARE @elStatementTypeId SMALLINT;
    
    WHILE @elementId IS NOT NULL AND @done=0
    BEGIN
        --PRINT('Get element details');
        SELECT @typeId=el.[TypeId], @nextElementId=el.[NextElementId], @altElementId=el.[AltElementId], @keywordId=el.[KeywordId], @operatorId=el.[OperatorId],
            @sequenceTypeId=el.[SequenceTypeId], @statementPartId=el.[StatementPartId], @tokenTypeId=el.[TokenTypeId], @tokenSubtypeId=el.[TokenSubtypeId],
            @elStatementTypeId=el.[StatementTypeId], @stringValue=el.[StringValue], @intValue=el.[IntValue]
        FROM [Parser].[TSqlSeqElement] el
        WHERE el.[Id]=@elementId;

        

        --PRINT('Check if they match');
        
        SET @match=0;
        --SET @lastTokenId=NULL;

        IF @typeId=@ET_KEYWORD
        BEGIN
            IF @tkTypeId=@tokenTypeId AND @tkKeywordId=@keywordId
            BEGIN
                SET @match=1;
            END
        END ELSE IF @typeId IN (@ET_IDENTIFIER, @ET_VARIABLE_NAME, @ET_SEPARATOR)
        BEGIN
            IF @tkTypeId=@tokenTypeId AND (@tokenSubtypeId IS NULL OR @tokenSubtypeId=@tkSubtypeId)
            BEGIN
                SET @match=1;
            END
        END ELSE IF @typeId=@ET_OPERATOR
        BEGIN
            --PRINT('Operator');
            IF @tkTypeId=ISNULL(@tokenTypeId, @TT_OPERATOR) AND (@operatorId IS NULL OR @tkOperatorId=@operatorId) -- subtype?
            BEGIN
                SET @lastTokenId = @tkEndTokenId;
                SET @match=1;
                --PRINT('Operator match');
            END
        END ELSE IF @typeId IN (@ET_LITERAL, @ET_LITERAL_INT, @ET_LITERAL_STRING)
        BEGIN
            IF @tkTypeId=ISNULL(@tokenTypeId, @TT_LITERAL) AND ((@typeId=@ET_LITERAL_INT AND @tkSubtypeId=@TST_INTEGER) OR (@typeId=@ET_LITERAL_STRING AND @tkSubtypeId IN (@TST_STRING, @TST_UNICODE_STRING)) 
                OR (@typeId=@ET_LITERAL AND (@tokenSubtypeId IS NULL OR @tkSubtypeId=@tokenSubtypeId)))
            BEGIN
                SET @match=1;
            END
        END ELSE IF @typeId IN (@ET_SEQUENCE, @ET_STATEMENT)
        BEGIN
            IF @typeId=@ET_SEQUENCE
            BEGIN
                --PRINT('@ET_SEQUENCE');
                SELECT @tpsSequenceId=[Id]
                FROM [Parser].[TSqlSequence] WHERE [SequenceTypeId]=@sequenceTypeId;
            END
            ELSE
            BEGIN
                --PRINT('@ET_STATEMENT');
                SET @lastTokenIdBeforeChildStatement = @lastTokenId;
                SELECT @tpsSequenceId=[Id]
                FROM [Parser].[TSqlSequence] WHERE [StatementTypeId]=@elStatementTypeId;
            END
            -- recursively call [Parser].[TryParseStatement]
            EXEC @tpsRc = [Parser].[TryParseSequence] @tokenId, @tpsSequenceId, @statementId, @statementPartId, 
                @tpsLastTokenId OUTPUT, @tpsIsFinished OUTPUT, @tpsStatementSeparatorTokenId OUTPUT, @tpsErrorMessage OUTPUT;
            IF @tpsRc=@RC_OK
            BEGIN
                SET @match=1;
                SET @lastTokenId = @tpsLastTokenId;
            END
            ELSE IF @tpsRc<>@RC_NOT_MATCH
            BEGIN
                SET @errorMessage = N'[TryParseSequence] recursive call returned : ' + LOWER(@tpsRc) + N' - ' + ISNULL(@tpsErrorMessage, '<NULL>');
                SET @rc = @RC_ERR_DATA;
                RETURN @rc;
            END

        END ELSE IF @typeId=@ET_SPECIAL_SEQUENCE
        BEGIN
            --PRINT('@ET_SPECIAL_SEQUENCE');
            IF @sequenceTypeId = @SQT_MORE_TOKENS
            BEGIN
                SET @done = 1;
                SET @lastTokenId = @tokenId;
                SET @match = 1;
                SET @isFinished = 0;
                SELECT @statementSeparatorTokenId = MIN([Id])
                FROM #Token
                WHERE [Id] > @tokenId AND [TypeId]=@TT_SEPARATOR AND [SubtypeId]=@TST_SEMICOLON;
            END
            ELSE IF @sequenceTypeId=@SQT_SEQUENCE_IN_PARENTHESES AND @tkTypeId=@TT_DELIMITER AND @tkText=N'('
            BEGIN
                SET @match = 1;
                SET @lastTokenId = @tkEndTokenId;
            END
            ELSE IF @sequenceTypeId=@SQT_CASE_EXPRESSION AND @tkBlockTypeId=@BT_CASE_BLOCK AND @tkKeywordId=@KW_CASE
            BEGIN
                SET @match = 1;
                SET @lastTokenId = @tkEndTokenId;
            END
        END ELSE IF @typeId=@ET_END
        BEGIN
            --PRINT('@ET_END');
            SET @done = 1;
            SET @match = 1;
            SET @isFinished = 1;
        END ELSE
        BEGIN
            PRINT('???');
            SELECT @rc = @RC_ERR_DATA, @errorMessage=N'Unexpected element type: ' + LOWER(@typeId);
            RETURN @rc;
        END
        
        IF @done=1
        BEGIN
            --PRINT('MATCH');
            SET @elementId=NULL;
            SET @rc = @RC_OK;
            IF @parentStatementId IS NOT NULL AND  @parentStatementPartId IS NOT NULL
            BEGIN
				/*
				PRINT ('StatementPart ' + ISNULL(LOWER(@parentStatementId), '<NULL>') 
				+ ', ' + ISNULL(LOWER(@parentStatementPartId), '<NULL>') 
				+ ', ' + ISNULL(LOWER(@startTokenId), '<NULL>') 
				+ ', ' + ISNULL(LOWER(@lastTokenId), '<NULL>'));
				*/
                INSERT INTO #StatementPart ([StatementId], [TypeId], [StartTokenId], [EndTokenId])
                VALUES (@parentStatementId, @parentStatementPartId, @startTokenId, @lastTokenId);
            END
            IF @isNewStatement=1
            BEGIN
				--PRINT('******');
				--PRINT('[ParentStatementId]: ' + ISNULL(LOWER(@typeId), '<NULL>') + ' (' + LOWER(@ET_STATEMENT) + '), ' +  ISNULL(LOWER(@parentStatementId), '<NULL>'));
                UPDATE #Statement
                SET [EndTokenId]=ISNULL(@lastTokenIdBeforeChildStatement, @lastTokenId), [IsFinished]=@isFinished, [StatementSeparatorTokenId]=@statementSeparatorTokenId, 
                --[ParentStatementId]=CASE WHEN @typeId=@ET_STATEMENT THEN @parentStatementId ELSE NULL END
				[ParentStatementId]=@parentStatementId
                WHERE [Id]=@statementId;
				SET @isNewStatement=0; -- ????
				--PRINT ('UPDATE: ' + LOWER(@statementId) + '; Parent: ' + ISNULL(LOWER(CASE WHEN @typeId=@ET_STATEMENT THEN @parentStatementId ELSE NULL END), '<NULL>'));
				--PRINT('!!!!');
            END
        END
        ELSE
        BEGIN
            IF @match=0
            BEGIN
                SET @elementId=@altElementId;
                IF @elementId IS NULL
                BEGIN
                    --PRINT('NOT MATCH');
                    SET @rc = @RC_NOT_MATCH;
                    SET @done=1;
                    -- revert inserts from recursive calls
                    SET @statementId=SCOPE_IDENTITY();
                    SET @isNewStatement=1;
                    IF @isNewStatement=1
                    BEGIN
                        DELETE FROM #StatementPart
                        WHERE [StatementId]>=@statementId;
                        
                        DELETE FROM #Statement
                        WHERE [Id]>=@statementId;
                    END
                    ELSE
                    BEGIN
                        DELETE FROM #StatementPart
                        WHERE [StatementId]>@statementId;
                        
                        DELETE FROM #Statement
                        WHERE [Id]>@statementId;
                    END
                END
            END
            ELSE
            BEGIN
                
                IF @lastTokenId IS NULL OR @lastTokenId<@tokenId
                BEGIN
                    SET @lastTokenId = @tokenId;
                END

                SET @elementId=@nextElementId;
                IF @elementId IS NULL
                BEGIN
                    PRINT('ERROR');
                    SELECT @rc = @RC_ERR_DATA, @errorMessage=N'Next element not set. Sequence Id: ' + LOWER(@sequenceId);
                    RETURN @rc;
                END
                SELECT TOP(1) @tokenId=tk.[Id], @tkTypeId=tk.[TypeId], @tkKeywordId=tk.[KeywordId], @tkSubtypeId=tk.[SubtypeId], @tkText=tk.[Text], @tkLevel=tk.[Level], @tkStartTokenId=tk.[StartTokenId],
                    @tkEndTokenId=tk.[EndTokenId], @tkBlockTypeId=tk.[BlockTypeId], @tkSeqStartTokenId=tk.[SeqStartTokenId], @tkSeqEndTokenId=tk.[SeqEndTokenId],
                    @tkSeqTypeId=tk.[SeqTypeId], @tkOperatorId=tk.[OperatorId]
                FROM #Token tk
                WHERE tk.[Id]>@lastTokenId AND tk.[TypeId] NOT IN (@TT_COMMENT, @TT_WHITESPACE)
                ORDER BY tk.[Id];
            END
        END
        
        
        
        
    END

    RETURN @rc;
END