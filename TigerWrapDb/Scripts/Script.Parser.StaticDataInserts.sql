-- table [ParserEnum].[TSqlSequenceType]
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=1) 
INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) 
VALUES (1, N'Normal');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=2) 
INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) 
VALUES (2, N'AnyStatement');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=3) 
INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) 
VALUES (3, N'BlockStatement');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=4) 
INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) 
VALUES (4, N'SequenceOfStatements');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=5) 
INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) 
VALUES (5, N'TwoPartIdentifier');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=6) 
INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) 
VALUES (6, N'ThreePartIdentifier');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=7) 
INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) 
VALUES (7, N'MoreTokens');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=8) 
INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) 
VALUES (8, N'Label');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=9) 
INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) 
VALUES (9, N'BeginBlock');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=10) 
INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) 
VALUES (10, N'EndBlock');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=11) 
INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) 
VALUES (11, N'SequenceInParentheses');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=12) 
INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) 
VALUES (12, N'FourPartIdentifier');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=13) 
INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) 
VALUES (13, N'ScalarExpression');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=14) 
INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) 
VALUES (14, N'OutputClause');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=15) 
INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) 
VALUES (15, N'CaseExpression');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=16) 
INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) 
VALUES (16, N'VarAssign');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=17) 
INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) 
VALUES (17, N'SpNumber');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=18) 
INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) 
VALUES (18, N'IdentifierDot');


-- table [ParserEnum].[TSqlBlockType]
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlBlockType] WHERE [Id]=1) 
INSERT INTO [ParserEnum].[TSqlBlockType] ([Id], [Name]) 
VALUES (1, N'RegularBlock');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlBlockType] WHERE [Id]=2) 
INSERT INTO [ParserEnum].[TSqlBlockType] ([Id], [Name]) 
VALUES (2, N'TryBlock');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlBlockType] WHERE [Id]=3) 
INSERT INTO [ParserEnum].[TSqlBlockType] ([Id], [Name]) 
VALUES (3, N'CatchBlock');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlBlockType] WHERE [Id]=4) 
INSERT INTO [ParserEnum].[TSqlBlockType] ([Id], [Name]) 
VALUES (4, N'AtomicBlock');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlBlockType] WHERE [Id]=5) 
INSERT INTO [ParserEnum].[TSqlBlockType] ([Id], [Name]) 
VALUES (5, N'CaseBlock');


-- table [ParserEnum].[TSqlStatementPart]
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlStatementPart] WHERE [Id]=1) 
INSERT INTO [ParserEnum].[TSqlStatementPart] ([Id], [Name]) 
VALUES (1, N'Identifier');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlStatementPart] WHERE [Id]=2) 
INSERT INTO [ParserEnum].[TSqlStatementPart] ([Id], [Name]) 
VALUES (2, N'StartOfParameterList');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlStatementPart] WHERE [Id]=3) 
INSERT INTO [ParserEnum].[TSqlStatementPart] ([Id], [Name]) 
VALUES (3, N'Definition');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlStatementPart] WHERE [Id]=4) 
INSERT INTO [ParserEnum].[TSqlStatementPart] ([Id], [Name]) 
VALUES (4, N'ChildStatement');


-- table [ParserEnum].[TokenType]
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenType] WHERE [Id]=0) 
INSERT INTO [ParserEnum].[TokenType] ([Id], [Name]) 
VALUES (0, N'None');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenType] WHERE [Id]=1) 
INSERT INTO [ParserEnum].[TokenType] ([Id], [Name]) 
VALUES (1, N'Whitespace');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenType] WHERE [Id]=2) 
INSERT INTO [ParserEnum].[TokenType] ([Id], [Name]) 
VALUES (2, N'Comment');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenType] WHERE [Id]=3) 
INSERT INTO [ParserEnum].[TokenType] ([Id], [Name]) 
VALUES (3, N'Identifier');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenType] WHERE [Id]=4) 
INSERT INTO [ParserEnum].[TokenType] ([Id], [Name]) 
VALUES (4, N'Keyword');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenType] WHERE [Id]=5) 
INSERT INTO [ParserEnum].[TokenType] ([Id], [Name]) 
VALUES (5, N'Delimiter');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenType] WHERE [Id]=6) 
INSERT INTO [ParserEnum].[TokenType] ([Id], [Name]) 
VALUES (6, N'Separator');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenType] WHERE [Id]=7) 
INSERT INTO [ParserEnum].[TokenType] ([Id], [Name]) 
VALUES (7, N'Operator');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenType] WHERE [Id]=8) 
INSERT INTO [ParserEnum].[TokenType] ([Id], [Name]) 
VALUES (8, N'Literal');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenType] WHERE [Id]=255) 
INSERT INTO [ParserEnum].[TokenType] ([Id], [Name]) 
VALUES (255, N'Unknown');


-- table [ParserEnum].[TSqlKeyword]
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=1) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (1, N'ADD');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=2) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (2, N'ALL');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=3) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (3, N'ALTER');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=4) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (4, N'AND');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=5) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (5, N'ANY');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=6) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (6, N'AS');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=7) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (7, N'ASC');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=8) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (8, N'AUTHORIZATION');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=9) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (9, N'BACKUP');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=10) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (10, N'BEGIN');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=11) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (11, N'BETWEEN');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=12) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (12, N'BREAK');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=13) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (13, N'BROWSE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=14) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (14, N'BULK');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=15) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (15, N'BY');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=16) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (16, N'CASCADE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=17) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (17, N'CASE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=18) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (18, N'CHECK');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=19) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (19, N'CHECKPOINT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=20) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (20, N'CLOSE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=21) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (21, N'CLUSTERED');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=22) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (22, N'COALESCE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=23) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (23, N'COLLATE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=24) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (24, N'COLUMN');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=25) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (25, N'COMMIT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=26) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (26, N'COMPUTE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=27) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (27, N'CONSTRAINT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=28) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (28, N'CONTAINS');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=29) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (29, N'CONTAINSTABLE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=30) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (30, N'CONTINUE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=31) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (31, N'CONVERT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=32) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (32, N'CREATE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=33) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (33, N'CROSS');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=34) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (34, N'CURRENT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=35) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (35, N'CURRENT_DATE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=36) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (36, N'CURRENT_TIME');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=37) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (37, N'CURRENT_TIMESTAMP');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=38) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (38, N'CURRENT_USER');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=39) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (39, N'CURSOR');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=40) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (40, N'DATABASE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=41) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (41, N'DBCC');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=42) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (42, N'DEALLOCATE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=43) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (43, N'DECLARE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=44) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (44, N'DEFAULT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=45) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (45, N'DELETE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=46) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (46, N'DENY');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=47) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (47, N'DESC');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=48) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (48, N'DISK');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=49) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (49, N'DISTINCT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=50) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (50, N'DISTRIBUTED');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=51) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (51, N'DOUBLE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=52) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (52, N'DROP');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=53) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (53, N'DUMP');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=54) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (54, N'ELSE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=55) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (55, N'END');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=56) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (56, N'ERRLVL');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=57) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (57, N'ESCAPE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=58) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (58, N'EXCEPT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=59) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (59, N'EXEC');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=60) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (60, N'EXECUTE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=61) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (61, N'EXISTS');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=62) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (62, N'EXIT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=63) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (63, N'EXTERNAL');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=64) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (64, N'FETCH');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=65) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (65, N'FILE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=66) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (66, N'FILLFACTOR');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=67) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (67, N'FOR');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=68) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (68, N'FOREIGN');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=69) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (69, N'FREETEXT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=70) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (70, N'FREETEXTTABLE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=71) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (71, N'FROM');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=72) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (72, N'FULL');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=73) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (73, N'FUNCTION');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=74) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (74, N'GOTO');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=75) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (75, N'GRANT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=76) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (76, N'GROUP');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=77) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (77, N'HAVING');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=78) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (78, N'HOLDLOCK');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=79) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (79, N'IDENTITY');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=80) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (80, N'IDENTITY_INSERT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=81) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (81, N'IDENTITYCOL');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=82) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (82, N'IF');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=83) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (83, N'IN');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=84) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (84, N'INDEX');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=85) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (85, N'INNER');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=86) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (86, N'INSERT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=87) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (87, N'INTERSECT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=88) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (88, N'INTO');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=89) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (89, N'IS');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=90) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (90, N'JOIN');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=91) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (91, N'KEY');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=92) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (92, N'KILL');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=93) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (93, N'LEFT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=94) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (94, N'LIKE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=95) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (95, N'LINENO');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=96) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (96, N'LOAD');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=97) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (97, N'MERGE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=98) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (98, N'NATIONAL');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=99) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (99, N'NOCHECK');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=100) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (100, N'NONCLUSTERED');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=101) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (101, N'NOT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=102) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (102, N'NULL');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=103) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (103, N'NULLIF');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=104) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (104, N'OF');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=105) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (105, N'OFF');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=106) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (106, N'OFFSETS');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=107) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (107, N'ON');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=108) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (108, N'OPEN');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=109) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (109, N'OPENDATASOURCE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=110) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (110, N'OPENQUERY');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=111) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (111, N'OPENROWSET');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=112) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (112, N'OPENXML');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=113) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (113, N'OPTION');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=114) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (114, N'OR');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=115) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (115, N'ORDER');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=116) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (116, N'OUTER');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=117) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (117, N'OVER');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=118) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (118, N'PERCENT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=119) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (119, N'PIVOT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=120) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (120, N'PLAN');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=121) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (121, N'PRECISION');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=122) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (122, N'PRIMARY');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=123) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (123, N'PRINT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=124) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (124, N'PROC');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=125) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (125, N'PROCEDURE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=126) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (126, N'PUBLIC');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=127) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (127, N'RAISERROR');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=128) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (128, N'READ');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=129) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (129, N'READTEXT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=130) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (130, N'RECONFIGURE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=131) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (131, N'REFERENCES');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=132) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (132, N'REPLICATION');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=133) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (133, N'RESTORE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=134) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (134, N'RESTRICT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=135) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (135, N'RETURN');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=136) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (136, N'REVERT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=137) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (137, N'REVOKE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=138) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (138, N'RIGHT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=139) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (139, N'ROLLBACK');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=140) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (140, N'ROWCOUNT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=141) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (141, N'ROWGUIDCOL');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=142) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (142, N'RULE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=143) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (143, N'SAVE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=144) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (144, N'SCHEMA');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=145) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (145, N'SECURITYAUDIT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=146) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (146, N'SELECT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=147) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (147, N'SEMANTICKEYPHRASETABLE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=148) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (148, N'SEMANTICSIMILARITYDETAILSTABLE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=149) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (149, N'SEMANTICSIMILARITYTABLE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=150) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (150, N'SESSION_USER');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=151) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (151, N'SET');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=152) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (152, N'SETUSER');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=153) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (153, N'SHUTDOWN');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=154) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (154, N'SOME');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=155) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (155, N'STATISTICS');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=156) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (156, N'SYSTEM_USER');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=157) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (157, N'TABLE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=158) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (158, N'TABLESAMPLE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=159) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (159, N'TEXTSIZE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=160) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (160, N'THEN');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=161) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (161, N'TO');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=162) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (162, N'TOP');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=163) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (163, N'TRAN');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=164) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (164, N'TRANSACTION');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=165) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (165, N'TRIGGER');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=166) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (166, N'TRUNCATE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=167) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (167, N'TRY_CONVERT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=168) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (168, N'TSEQUAL');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=169) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (169, N'UNION');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=170) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (170, N'UNIQUE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=171) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (171, N'UNPIVOT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=172) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (172, N'UPDATE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=173) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (173, N'UPDATETEXT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=174) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (174, N'USE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=175) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (175, N'USER');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=176) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (176, N'VALUES');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=177) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (177, N'VARYING');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=178) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (178, N'VIEW');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=179) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (179, N'WAITFOR');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=180) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (180, N'WHEN');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=181) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (181, N'WHERE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=182) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (182, N'WHILE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=183) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (183, N'WITH');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=184) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (184, N'WITHIN');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=185) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (185, N'WRITETEXT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=186) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (186, N'ATOMIC');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=187) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (187, N'CONVERSATION');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=188) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (188, N'DIALOG');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=189) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (189, N'CATCH');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=190) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (190, N'TRY');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=191) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (191, N'THROW');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=192) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (192, N'FILETABLE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=193) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (193, N'OUTPUT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=194) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (194, N'LOGIN');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=195) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (195, N'AT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=196) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (196, N'DATA_SOURCE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=197) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (197, N'RECOMPILE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=198) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (198, N'RESULT');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=199) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (199, N'SETS');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=200) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (200, N'UNDEFINED');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=201) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (201, N'NONE');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=32767) 
INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) 
VALUES (32767, N'<MORE_THAN_ONE>');


-- table [ParserEnum].[CharType]
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[CharType] WHERE [Id]=0) 
INSERT INTO [ParserEnum].[CharType] ([Id], [Name]) 
VALUES (0, N'Unknown');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[CharType] WHERE [Id]=1) 
INSERT INTO [ParserEnum].[CharType] ([Id], [Name]) 
VALUES (1, N'Letter');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[CharType] WHERE [Id]=2) 
INSERT INTO [ParserEnum].[CharType] ([Id], [Name]) 
VALUES (2, N'UnicodeLetter');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[CharType] WHERE [Id]=3) 
INSERT INTO [ParserEnum].[CharType] ([Id], [Name]) 
VALUES (3, N'Digit');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[CharType] WHERE [Id]=4) 
INSERT INTO [ParserEnum].[CharType] ([Id], [Name]) 
VALUES (4, N'UnicodeDigit');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[CharType] WHERE [Id]=5) 
INSERT INTO [ParserEnum].[CharType] ([Id], [Name]) 
VALUES (5, N'Operator');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[CharType] WHERE [Id]=6) 
INSERT INTO [ParserEnum].[CharType] ([Id], [Name]) 
VALUES (6, N'Separator');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[CharType] WHERE [Id]=7) 
INSERT INTO [ParserEnum].[CharType] ([Id], [Name]) 
VALUES (7, N'Delimiter');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[CharType] WHERE [Id]=8) 
INSERT INTO [ParserEnum].[CharType] ([Id], [Name]) 
VALUES (8, N'Special');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[CharType] WHERE [Id]=9) 
INSERT INTO [ParserEnum].[CharType] ([Id], [Name]) 
VALUES (9, N'Whitespace');


-- table [ParserEnum].[TSqlSeqElementType]
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSeqElementType] WHERE [Id]=1) 
INSERT INTO [ParserEnum].[TSqlSeqElementType] ([Id], [Name]) 
VALUES (1, N'Keyword');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSeqElementType] WHERE [Id]=2) 
INSERT INTO [ParserEnum].[TSqlSeqElementType] ([Id], [Name]) 
VALUES (2, N'Identifier');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSeqElementType] WHERE [Id]=3) 
INSERT INTO [ParserEnum].[TSqlSeqElementType] ([Id], [Name]) 
VALUES (3, N'Operator');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSeqElementType] WHERE [Id]=4) 
INSERT INTO [ParserEnum].[TSqlSeqElementType] ([Id], [Name]) 
VALUES (4, N'Separator');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSeqElementType] WHERE [Id]=5) 
INSERT INTO [ParserEnum].[TSqlSeqElementType] ([Id], [Name]) 
VALUES (5, N'Delimiter');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSeqElementType] WHERE [Id]=6) 
INSERT INTO [ParserEnum].[TSqlSeqElementType] ([Id], [Name]) 
VALUES (6, N'Statement');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSeqElementType] WHERE [Id]=7) 
INSERT INTO [ParserEnum].[TSqlSeqElementType] ([Id], [Name]) 
VALUES (7, N'SequenceOfStatements');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSeqElementType] WHERE [Id]=8) 
INSERT INTO [ParserEnum].[TSqlSeqElementType] ([Id], [Name]) 
VALUES (8, N'Block');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSeqElementType] WHERE [Id]=9) 
INSERT INTO [ParserEnum].[TSqlSeqElementType] ([Id], [Name]) 
VALUES (9, N'LiteralString');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSeqElementType] WHERE [Id]=10) 
INSERT INTO [ParserEnum].[TSqlSeqElementType] ([Id], [Name]) 
VALUES (10, N'Sequence');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSeqElementType] WHERE [Id]=11) 
INSERT INTO [ParserEnum].[TSqlSeqElementType] ([Id], [Name]) 
VALUES (11, N'End');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSeqElementType] WHERE [Id]=12) 
INSERT INTO [ParserEnum].[TSqlSeqElementType] ([Id], [Name]) 
VALUES (12, N'LiteralInt');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSeqElementType] WHERE [Id]=13) 
INSERT INTO [ParserEnum].[TSqlSeqElementType] ([Id], [Name]) 
VALUES (13, N'VariableName');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSeqElementType] WHERE [Id]=14) 
INSERT INTO [ParserEnum].[TSqlSeqElementType] ([Id], [Name]) 
VALUES (14, N'SpecialSequence');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSeqElementType] WHERE [Id]=15) 
INSERT INTO [ParserEnum].[TSqlSeqElementType] ([Id], [Name]) 
VALUES (15, N'Literal');


-- table [ParserEnum].[TokenSubtype]
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=1) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (1, 2, N'SingleLineComment');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=2) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (2, 2, N'MultiLineComment');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=3) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (3, 3, N'RegularIdentifier');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=4) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (4, 3, N'IdentifierInBrackets');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=5) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (5, 3, N'IdentifierInDoubleQuotes');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=6) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (6, 8, N'String');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=7) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (7, 8, N'UnicodeString');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=8) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (8, 8, N'Integer');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=9) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (9, 8, N'Decimal');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=10) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (10, 8, N'Money');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=11) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (11, 8, N'Real');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=12) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (12, 8, N'Binary');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=13) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (13, 6, N'Comma');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=14) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (14, 6, N'Semicolon');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=15) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (15, 6, N'Period');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=16) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (16, 4, N'VariableName');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=17) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (17, 7, N'UnaryOperator');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=18) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (18, 7, N'BinaryOperator');

IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=19) 
INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) 
VALUES (19, 7, N'UnaryOrBinaryOperator');


-- table [Parser].[Operator]
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=1) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (1, 'BT_NOT', '~', 1, 0);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=2) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (2, 'MUL', '*', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=3) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (3, 'DIV', '/', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=4) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (4, 'MOD', '%', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=5) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (5, 'ADD', '+', 1, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=6) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (6, 'SUB', '-', 1, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=7) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (7, 'BT_AND', '&', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=8) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (8, 'BT_XOR', '^', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=9) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (9, 'BT_OR', '|', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=10) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (10, 'EQ', '=', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=11) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (11, 'GT', '>', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=12) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (12, 'LT', '<', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=13) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (13, 'GE', '>=', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=14) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (14, 'LE', '<=', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=15) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (15, 'NE', '<>', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=16) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (16, 'NE2', '!=', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=17) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (17, 'NGT', '!>', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=18) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (18, 'NLT', '!<', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=19) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (19, 'ADD_ASSIGN', '+=', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=20) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (20, 'SUB_ASSIGN', '-=', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=21) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (21, 'MUL_ASSIGN', '*=', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=22) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (22, 'DIV_ASSIGN', '/=', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=23) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (23, 'MOD_ASSIGN', '%=', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=24) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (24, 'BT_AND_ASSIGN', '&=', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=25) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (25, 'BT_XOR_ASSIGN', '^=', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=26) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (26, 'BT_OR_ASSIGN', '|=', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=27) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (27, 'SCOPE', '::', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=28) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (28, 'NOT', 'NOT', 0, 0);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=29) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (29, 'AND', 'AND', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=30) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (30, 'ALL', 'ALL', 0, 0);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=31) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (31, 'ANY', 'ANY', 0, 0);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=32) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (32, 'BETWEEN', 'BETWEEN', 0, 0);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=33) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (33, 'IN', 'IN', 0, 0);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=34) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (34, 'LIKE', 'LIKE', 0, 0);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=35) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (35, 'OR', 'OR', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=36) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (36, 'SOME', 'SOME', 0, 0);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=37) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (37, 'EXISTS', 'EXISTS', 0, 0);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=38) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (38, 'BT_SHL', '<<', 0, 1);

IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=39) 
INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) 
VALUES (39, 'BT_SHR', '>>', 0, 1);



-- Completion time: 2025-07-05T16:03:47.0047302+01:00
