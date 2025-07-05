
CREATE PROCEDURE [Parser].[TryDescribeFirstResultSetWorkaround]
	@projectId SMALLINT,
	@dbId SMALLINT,
	@langId TINYINT,	
	@spId INT,
	@errorMessage NVARCHAR(2000) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @rc INT;

	DECLARE @RC_OK INT = 0;
    DECLARE @RC_ERR_PARSE INT = 1;

	DECLARE @RC_ERR_PROJECT INT = 21;
	DECLARE @RC_ERR_DB INT = 22;
	DECLARE @RC_ERR_LANG INT = 23;

    DECLARE @C_PASCAL_CASE TINYINT = 1;
	DECLARE @C_CAMEL_CASE TINYINT = 2;
	DECLARE @C_SNAKE_CASE TINYINT = 3;
	DECLARE @C_UNDERSCORE_CAMEL_CASE TINYINT = 4;
	DECLARE @C_UPPER_SNAKE_CASE TINYINT = 5;


    DECLARE @ST_CREATE_PROCEDURE SMALLINT = 1;
    DECLARE @ST_CREATE_TABLE SMALLINT = 2;
    DECLARE @ST_EXEC SMALLINT = 3;
    DECLARE @ST_SELECT SMALLINT = 4;
    DECLARE @ST_INSERT SMALLINT = 5;
    DECLARE @ST_UPDATE SMALLINT = 6;
    DECLARE @ST_DELETE SMALLINT = 7;
    DECLARE @ST_DECLARE SMALLINT = 8;
    DECLARE @ST_SET SMALLINT = 9;

    DECLARE @ST_TRUNCATE_TABLE SMALLINT = 10;
    DECLARE @ST_DROP_TABLE SMALLINT = 11;

    DECLARE @ST_BEGIN_TRANSACTION SMALLINT = 20;
    DECLARE @ST_BEGIN_DISTRIBUTED_TRANSACTION SMALLINT = 21;
    DECLARE @ST_COMMIT SMALLINT = 23;
    DECLARE @ST_ROLLBACK SMALLINT = 24;

    DECLARE @ST_IF SMALLINT = 31;
    DECLARE @ST_WHILE SMALLINT = 32;
    DECLARE @ST_CONTINUE SMALLINT = 33;
    DECLARE @ST_BREAK SMALLINT = 34;
    DECLARE @ST_THROW SMALLINT = 35;
    DECLARE @ST_RAISERROR SMALLINT = 36;
    DECLARE @ST_PRINT SMALLINT = 37;
    DECLARE @ST_RETURN SMALLINT = 38;
	
    DECLARE @SP_IDENTIFIER TINYINT = 1;
    DECLARE @SP_START_OF_PARAMETER_LIST TINYINT = 2;
    DECLARE @SP_DEFINITION TINYINT = 3;
    DECLARE @SP_CHILD_STATEMENT TINYINT = 4;

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
    DECLARE @KW_OUTPUT SMALLINT = 193;
    DECLARE @KW_LOGIN SMALLINT = 194;
    DECLARE @KW_AT SMALLINT = 195;
    DECLARE @KW_DATA_SOURCE SMALLINT = 196;
    DECLARE @KW_RECOMPILE SMALLINT = 197;
    DECLARE @KW_RESULT SMALLINT = 198;
    DECLARE @KW_SETS SMALLINT = 199;
    DECLARE @KW_UNDEFINED SMALLINT = 200;
    DECLARE @KW_NONE SMALLINT = 201;
    DECLARE @KW_MORE_THAN_ONE SMALLINT = 32767;

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
    DECLARE @TST_UNARY_OPERATOR TINYINT = 17;
    DECLARE @TST_BINARY_OPERATOR TINYINT = 18;
    DECLARE @TST_UNARY_OR_BINARY_OPERATOR TINYINT = 19;

	DECLARE @dbName NVARCHAR(128) = DB_NAME(@dbId);
    DECLARE @spSchema NVARCHAR(128);
	DECLARE @spName NVARCHAR(128);

	IF @dbName IS NULL
	BEGIN
		SELECT @rc = @RC_ERR_DB, @errorMessage=N'Database not found';
		RETURN @rc;
	END
	
    SELECT @spSchema = [Schema], @spName=[Name]
	FROM #StoredProc
	WHERE [Id]=@spId;

	DROP TABLE IF EXISTS #Definition;

    CREATE TABLE #Definition
    (
        [Id] INT NOT NULL IDENTITY(1, 1) PRIMARY KEY,
        [Schema] NVARCHAR(128) NOT NULL,
        [Name] NVARCHAR(128) NOT NULL,
        [Definition] NVARCHAR(MAX) NOT NULL,
        UNIQUE ([Schema], [Name])
    );

    DECLARE @query NVARCHAR(MAX);

    SET @query = N'USE ' + QUOTENAME(@dbName) + N';
    '
    SET @query += N'SELECT SCHEMA_NAME(o.[schema_id]) [Schema], OBJECT_NAME(m.[object_id]) [Name], m.[definition] [Definition]
    FROM sys.all_sql_modules m
    JOIN sys.all_objects o ON m.object_id=o.[object_id]
    WHERE m.object_id=OBJECT_ID(' + QUOTENAME(QUOTENAME(@spSchema) + N'.' + QUOTENAME(@spName), '''') + N');
    ';

    INSERT INTO #Definition ([Schema], [Name], [Definition])
    EXEC(@query);

    DECLARE @tsql NVARCHAR(MAX);

    SELECT TOP(1) @tsql=[Definition] FROM #Definition;

    DROP TABLE IF EXISTS #Definition;

    DROP TABLE IF EXISTS #Token, #Statement, #StatementPart;

    CREATE TABLE #Token
    (
        [Id] INT NOT NULL IDENTITY (1, 1) PRIMARY KEY,
        [TypeId] TINYINT NOT NULL,
        [KeywordId] SMALLINT NULL,
        [SubTypeId] SMALLINT NULL,
        [OperatorId] TINYINT NULL,
        [Text] NVARCHAR(MAX) NULL,
        [Level] SMALLINT NULL,
        [StartTokenId] INT NULL,
        [EndTokenId] INT NULL,
        [BlockTypeId] TINYINT NULL,
        [SeqStartTokenId] INT NULL,
        [SeqEndTokenId] INT NULL,
        [SeqTypeId] TINYINT NULL,
    
    );

    CREATE TABLE #Statement
    (
        [Id] INT NOT NULL IDENTITY (1, 1) PRIMARY KEY,
        [TypeId] SMALLINT NOT NULL, -- [Enum].[TSqlStatementType]
        [StartTokenId] INT NOT NULL,
        [EndTokenId] INT NULL,
        [IsFinished] BIT NOT NULL DEFAULT (0),
        [StatementSeparatorTokenId] INT NULL,
        [ParentStatementId] INT NULL
    );


    CREATE TABLE #StatementPart
    (
        [Id] INT NOT NULL IDENTITY (1, 1) PRIMARY KEY,
        [StatementId] INT NOT NULL,
        [TypeId] TINYINT NOT NULL, -- [Enum].[TSqlStatementPart]
        [StartTokenId] INT NOT NULL,
        [EndTokenId] INT NOT NULL
    );

    CREATE TABLE #TempTable
    (
        [Id] INT NOT NULL IDENTITY (1, 1) PRIMARY KEY,
        [Name] NVARCHAR(128) NOT NULL UNIQUE,
        [TvName] NVARCHAR(128) NOT NULL UNIQUE,
        [CreateTokenId] INT NOT NULL,
        [TableTokenId] INT NOT NULL,
        [NameTokenId] INT NOT NULL,
		[EndTokenId] INT NOT NULL,
		[CloseParenTokenId] INT NOT NULL
    );

    DECLARE	@returnValue int,
        @spErrorMessage nvarchar(4000);

    EXEC @returnValue = [Parser].[TokenizeTSql] @tsql = @tsql, @errorMessage = @spErrorMessage OUTPUT;

    IF @returnValue = @RC_OK
    BEGIN
        EXEC @returnValue = [Parser].[ParseTSql] @errorMessage = @errorMessage OUTPUT;
    END
    IF @returnValue <> @RC_OK
    BEGIN
        SELECT @rc = @RC_ERR_PARSE, @errorMessage=N'Failed to parse the stored procedure';
        RETURN @rc;
    END

    DECLARE @tempSpName NVARCHAR(128) = N'__Temp__' + LEFT(@spName, 64) + N'__' + REPLACE(LOWER(NEWID()), '-', '');

    INSERT INTO #TempTable ([Name], [TvName], [CreateTokenId], [TableTokenId], [NameTokenId], [EndTokenId], [CloseParenTokenId])
    SELECT tkn.[Text], N'@' + [Internal].[GetCaseName](@C_CAMEL_CASE, LEFT(tkn.[Text], 65), NULL) + N'___' + REPLACE(LOWER(NEWID()), '-', ''), tkc.[Id], tkt.[Id], tkn.[Id],
		st.[EndTokenId], tkcp.[Id]
    FROM #Statement st    
    JOIN #StatementPart stp ON stp.[StatementId]=st.[Id] AND stp.[TypeId]=@SP_IDENTIFIER AND stp.[StartTokenId]=stp.[EndTokenId]
    JOIN #Token tkn ON tkn.[Id]=stp.[StartTokenId]
    JOIN #Token tkc ON tkc.[Id] >= st.[StartTokenId] AND tkc.[Id] <= st.[EndTokenId] AND tkc.[TypeId]=@TT_KEYWORD AND tkc.[KeywordId]=@KW_CREATE
    JOIN #Token tkt ON tkt.[Id] >= st.[StartTokenId] AND tkt.[Id] <= st.[EndTokenId] AND tkt.[TypeId]=@TT_KEYWORD AND tkt.[KeywordId]=@KW_TABLE AND tkt.[Id] > tkc.[Id]
	JOIN #Token tkcp ON tkcp.[Id] >= st.[StartTokenId] AND tkcp.[Id] <= st.[EndTokenId] AND tkcp.[Text] = ')' AND tkcp.[TypeId]=@TT_DELIMITER AND tkcp.[Id] > tkt.[Id]
	
	LEFT JOIN #Token xtkc ON xtkc.[Id] >= st.[StartTokenId] AND xtkc.[Id] <= st.[EndTokenId] AND xtkc.[TypeId]=@TT_KEYWORD AND xtkc.[KeywordId]=@KW_CREATE AND xtkc.[Id] < tkc.[Id]
    LEFT JOIN #Token xtkt ON xtkt.[Id] >= st.[StartTokenId] AND xtkt.[Id] <= st.[EndTokenId] AND xtkt.[TypeId]=@TT_KEYWORD AND xtkt.[KeywordId]=@KW_TABLE AND xtkt.[Id] < tkt.[Id]
	LEFT JOIN #Token xtkcp ON xtkcp.[Id] >= st.[StartTokenId] AND xtkcp.[Id] <= st.[EndTokenId] AND xtkcp.[Text] = ')' AND xtkcp.[TypeId]=@TT_DELIMITER AND xtkcp.[Id] > tkcp.[Id]

	WHERE st.[TypeId]=@ST_CREATE_TABLE AND tkn.[Text] LIKE N'#[^#]%' AND xtkc.[Id] IS NULL AND xtkt.[Id] IS NULL AND xtkcp.[Id] IS NULL;
    
    -- SELECT * 
	-- FROM #TempTable;

    -- change SP name
    WITH cte AS
    (
        SELECT TOP(1) st.[Id], sp.[StartTokenId], sp.[EndTokenId]
        FROM #Statement st
        JOIN #StatementPart sp ON sp.[StatementId]=st.[Id] AND sp.[TypeId]=@SP_IDENTIFIER
        WHERE st.[TypeId]=@ST_CREATE_PROCEDURE
        ORDER BY st.[Id]
    )
    UPDATE tk
    SET tk.[Text]=CASE WHEN tk.[Id]=cte.[StartTokenId] THEN @tempSpName ELSE N'' END,
        tk.[TypeId]=CASE WHEN tk.[Id]=cte.[StartTokenId] THEN @TT_IDENTIFIER ELSE @TT_WHITESPACE END,
        tk.[SubTypeId]=CASE WHEN tk.[Id]=cte.[StartTokenId] THEN @TST_REGULAR_IDENTIFIER ELSE NULL END
    FROM cte
    JOIN #Token tk ON tk.[Id] BETWEEN cte.[StartTokenId] AND cte.[EndTokenId];



    -- remove comments
    UPDATE #Token
    SET [TypeId]=@TT_WHITESPACE, [Text]=CASE WHEN [SubTypeId]=@TST_SINGLE_LINE_COMMENT THEN N'' ELSE N' ' END, [SubTypeId]=NULL
    WHERE [TypeId]=@TT_COMMENT;

    -- remove DROP TABLE ...
    UPDATE tk
    SET [Text]=CASE WHEN tk.[TypeId]=@TT_KEYWORD AND tk.[KeywordId] IN (@KW_DROP, @KW_TABLE) THEN CASE WHEN tk.[KeywordId]=@KW_DROP THEN N'PRINT' ELSE N'DROP TABLE removed...' END ELSE N' ' END,
        [SubTypeId]=CASE WHEN tk.[TypeId]=@TT_KEYWORD AND tk.[KeywordId]=@KW_TABLE THEN @TST_STRING ELSE NULL END,
        [TypeId]=CASE WHEN tk.[TypeId]=@TT_KEYWORD AND tk.[KeywordId] IN (@KW_DROP, @KW_TABLE) THEN CASE WHEN tk.[KeywordId]=@KW_DROP THEN @TT_KEYWORD ELSE @TT_LITERAL END ELSE @TT_WHITESPACE END,
        [KeywordId]=CASE WHEN tk.[TypeId]=@TT_KEYWORD AND tk.[KeywordId]=@KW_DROP THEN @KW_PRINT ELSE NULL END        
    FROM #Statement st
    JOIN #Token tk ON tk.[Id] BETWEEN st.[StartTokenId] AND st.[EndTokenId]
    WHERE st.TypeId=@ST_DROP_TABLE;

	--SELECT * 
	--FROM #Token;

	--SELECT *
	--FROM #Statement;

    -- remove INSERT... EXEC
    WITH cte AS
    (
        SELECT ROW_NUMBER() OVER (PARTITION BY sti.[Id] ORDER BY tk.[Id]) [RowNum], sti.[Id] [StatementId], tk.[Id] [TokenId]
        FROM #Statement sti
        JOIN #Statement ste ON ste.[ParentStatementId]=sti.[Id] AND ste.[TypeId]=@ST_EXEC
        JOIN #Token tk ON tk.[Id] BETWEEN sti.[StartTokenId] AND ste.[EndTokenId]
        WHERE sti.[TypeId]=@ST_INSERT AND tk.[TypeId]<>@TT_WHITESPACE
    )
    UPDATE tk
    SET tk.[TypeId]=CASE cte.[RowNum] WHEN 1 THEN @TT_KEYWORD  WHEN 2 THEN @TT_LITERAL ELSE @TT_WHITESPACE END,
        tk.[SubTypeId]=CASE cte.[RowNum] WHEN 2 THEN @TST_STRING ELSE NULL END, 
        tk.[Text] = CASE cte.[RowNum] WHEN 1 THEN N'PRINT' WHEN 2 THEN N'INSERT... EXEC removed...' ELSE N'' END,
        tk.[KeywordId]=CASE WHEN cte.[RowNum]=1 THEN @KW_PRINT ELSE NULL END
    FROM cte
    JOIN #Token tk ON tk.[Id]=cte.[TokenId];

    -- remove EXEC
    WITH cte AS
    (
        SELECT ROW_NUMBER() OVER (PARTITION BY ste.[Id] ORDER BY tk.[Id]) [RowNum], ste.[Id] [StatementId], tk.[Id] [TokenId]
        FROM #Statement ste
        JOIN #Token tk ON tk.[Id] BETWEEN ste.[StartTokenId] AND ste.[EndTokenId]
        WHERE ste.[TypeId]=@ST_EXEC AND tk.[TypeId]<>@TT_WHITESPACE
    )
    UPDATE tk
    SET tk.[TypeId]=CASE cte.[RowNum] WHEN 1 THEN @TT_KEYWORD  WHEN 2 THEN @TT_LITERAL ELSE @TT_WHITESPACE END,
        tk.[SubTypeId]=CASE cte.[RowNum] WHEN 2 THEN @TST_STRING ELSE NULL END, 
        tk.[Text] = CASE cte.[RowNum] WHEN 1 THEN N'PRINT' WHEN 2 THEN N'EXEC removed...' ELSE N'' END,
        tk.[KeywordId]=CASE WHEN cte.[RowNum]=1 THEN @KW_PRINT ELSE NULL END
    FROM cte
    JOIN #Token tk ON tk.[Id]=cte.[TokenId];

    -- replace TRUNCATE TABLE #... with DELETE FROM @...
    WITH cte AS
    (
        SELECT ROW_NUMBER() OVER (PARTITION BY st.[Id] ORDER BY tk.[Id]) [RowNum], st.[Id] [StatementId], tk.[Id] [TokenId], tt.[Name] [TableName], tt.[TvName]
        FROM #Statement st
        JOIN #StatementPart stp ON stp.[StatementId]=st.[Id] AND stp.[TypeId]=@SP_IDENTIFIER AND stp.[StartTokenId]=stp.[EndTokenId]
        JOIN #Token ntk ON ntk.[Id]=stp.[StartTokenId]
        JOIN #TempTable tt ON tt.[Name]=ntk.[Text]
        JOIN #Token tk ON tk.[Id] BETWEEN st.[StartTokenId] AND st.[EndTokenId]
        WHERE st.[TypeId]=@ST_TRUNCATE_TABLE AND tk.[TypeId]<>@TT_WHITESPACE
    )
    UPDATE tk
    SET tk.[TypeId]=CASE cte.[RowNum] WHEN 1 THEN @TT_KEYWORD WHEN 2 THEN @TT_KEYWORD WHEN 3 THEN @TT_IDENTIFIER ELSE @TT_WHITESPACE END,
        tk.[SubTypeId]=CASE cte.[RowNum] WHEN 3 THEN @TST_VARIABLE_NAME ELSE NULL END, 
        tk.[Text] = CASE cte.[RowNum] WHEN 1 THEN N'DELETE' WHEN 2 THEN N'FROM' WHEN 3 THEN cte.[TvName] ELSE N'' END,
        tk.[KeywordId]=CASE cte.[RowNum] WHEN 1 THEN @KW_DELETE WHEN 2 THEN @KW_FROM ELSE NULL END
    FROM cte
    JOIN #Token tk ON tk.[Id]=cte.[TokenId];

    -- replace CREATE TABLE #... with DECLARE @... TABLE

    UPDATE tk
    SET tk.[KeywordId]=@KW_DECLARE, tk.[Text]=N'DECLARE'
    FROM #TempTable tt
    JOIN #Token tk ON tt.[CreateTokenId]=tk.[Id];

    UPDATE tk
    SET tk.[TypeId]=@TT_IDENTIFIER, tk.[SubTypeId]=@TST_VARIABLE_NAME, tk.[KeywordId]=NULL, tk.[Text]=tt.[TvName]
    FROM #TempTable tt
    JOIN #Token tk ON tt.[TableTokenId]=tk.[Id];

    UPDATE tk
    SET tk.[TypeId]=@TT_KEYWORD, tk.[SubTypeId]=NULL, tk.[KeywordId]=@KW_TABLE, tk.[Text]=N'TABLE'
    FROM #TempTable tt
    JOIN #Token tk ON tt.[NameTokenId]=tk.[Id];


	-- Remove trailing comma before closing parenthesis in DECLARE @... TABLE
	UPDATE tk
	SET tk.[TypeId]=@TT_COMMENT, tk.[SubTypeId]=@TST_MULTI_LINE_COMMENT, tk.[Text]='/* comma removed */'
	FROM #TempTable tt
	JOIN #Token tk ON tk.[Text] = ',' AND tk.[TypeId]=@TT_SEPARATOR AND tk.[Id] < tt.[CloseParenTokenId] AND tk.[Id] > tt.[NameTokenId]
	LEFT JOIN #Token xtk ON xtk.[TypeId]<>@TT_WHITESPACE AND xtk.[Id] > tk.[Id] AND xtk.[Id] < tt.[CloseParenTokenId]
	WHERE xtk.[Id] IS NULL;

    -- replace #... with @... in all identifiers

    UPDATE tk
    SET tk.[Text]=tt.[TvName], tk.[SubTypeId]=@TST_VARIABLE_NAME
    FROM #TempTable tt
    JOIN #Token tk ON tt.[Name]=tk.[Text]
    WHERE tk.[TypeId]=@TT_IDENTIFIER;


    SELECT @tsql=STRING_AGG([Parser].[GetFullText]([Text], [SubTypeId]), N'') WITHIN GROUP (ORDER BY [Id])
    FROM #Token;

    

    --PRINT N'---------------------------------'
    --SELECT @tsql;
    --PRINT N'---------------------------------'

    SET @query = N'USE ' + QUOTENAME(@dbName) + N';    
    '
    SET @query += N'EXEC(N''' + REPLACE(@tsql, '''', '''''') + N''');
    ';
    SET @query += N'SELECT frs.[is_hidden], frs.[column_ordinal], frs.[name], frs.[is_nullable], frs.[system_type_id], frs.[system_type_name], frs.[max_length], frs.[precision], frs.[scale], 
        frs.[collation_name], frs.[user_type_id], frs.[user_type_database], frs.[user_type_schema], frs.[user_type_name], frs.[assembly_qualified_type_name], frs.[xml_collection_id], 
        frs.[xml_collection_database], frs.[xml_collection_schema], frs.[xml_collection_name], frs.[is_xml_document], frs.[is_case_sensitive], frs.[is_fixed_length_clr_type], 
        frs.[source_server], frs.[source_database], frs.[source_schema], frs.[source_table], frs.[source_column], frs.[is_identity_column], frs.[is_part_of_unique_key], 
        frs.[is_updateable], frs.[is_computed_column], frs.[is_sparse_column_set], frs.[ordinal_in_order_by_list], frs.[order_by_is_descending], frs.[order_by_list_length], 
        frs.[error_number], frs.[error_severity], frs.[error_state], frs.[error_message], frs.[error_type], frs.[error_type_desc]
    FROM sys.dm_exec_describe_first_result_set(''' + @tempSpName + N''', NULL, 1) frs;    
    '

    SET @query += N'DROP PROCEDURE ' + @tempSpName + N';    
    ';

    --SELECT @query;

    TRUNCATE TABLE #SingleStoredProcResultSet;

    INSERT INTO #SingleStoredProcResultSet 
    ([is_hidden], [column_ordinal], [name], [is_nullable], [system_type_id], [system_type_name], [max_length], [precision], [scale], [collation_name], [user_type_id], 
     [user_type_database], [user_type_schema], [user_type_name], [assembly_qualified_type_name], [xml_collection_id], [xml_collection_database], [xml_collection_schema], 
     [xml_collection_name], [is_xml_document], [is_case_sensitive], [is_fixed_length_clr_type], [source_server], [source_database], [source_schema], [source_table], 
     [source_column], [is_identity_column], [is_part_of_unique_key], [is_updateable], [is_computed_column], [is_sparse_column_set], [ordinal_in_order_by_list], 
     [order_by_is_descending], [order_by_list_length], [error_number], [error_severity], [error_state], [error_message], [error_type], [error_type_desc])
    EXEC(@query);

    --PRINT('All OK?')
    --SELECT * FROM #SingleStoredProcResultSet;

    DROP TABLE IF EXISTS #Token, #Statement, #StatementPart;
    RETURN @RC_OK;
END