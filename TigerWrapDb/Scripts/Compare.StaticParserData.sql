/*
================================================================================
 Compare.StaticParserData.sql

 Logical (identity-independent) comparison of TigerWrapDb static/parser data
 between two databases on the same server:

   - [Static].[Template]
   - [Parser].[TSqlSequence]
   - [Parser].[TSqlSeqElement]

 Why: VS SQL Data Compare matches rows by primary key. [Static].[Template].[Id]
 and [Parser].[TSqlSequence].[Id] are IDENTITY columns, and
 [Parser].[TSqlSeqElement].[Id] is allocated from the [Parser].[TSqlSeqEl]
 sequence in ranges (see [Parser].[GetSeqElemIdRange]). Two databases built
 from the same scripts can therefore hold identical logical content under
 different physical Id values, which SQL Data Compare reports as differences.

 This script compares by logical keys instead:

   [Static].[Template]        key: (Language, TemplateType, LanguageOptions)
                              — mirrors unique index
                              UX_Template_LanguageId_TypeId_LanguageOptions.
   [Parser].[TSqlSequence]    key: Name
                              — unique index UX_Parser_TSqlSequence_Name.
   [Parser].[TSqlSeqElement]  key: (SequenceName, Ord), where Ord is the
                              element's position within its sequence ordered
                              by Id. NextElementId / AltElementId are
                              translated to the referenced element's
                              "SequenceName#Ord" label and SequenceId to the
                              sequence Name, so references are compared
                              structurally, not by physical id.

 Assumption for element Ord: within one parser sequence, elements were
 inserted in the same relative Id order in both databases (true for
 script-built data — Script.Parser.Data.sql allocates one contiguous id range
 per sequence and uses fixed offsets). If the assumption does not hold, the
 affected rows surface as 'Different' — never silently ignored.

 Lookup ids ([Enum].*, [ParserEnum].*, [Parser].[Operator]) are inserted with
 explicit ids (no IDENTITY), so they are stable; they are resolved to names
 for readability (an id with no matching lookup row shows as 'id:N').

 Read-only: only SELECTs run against both databases; scratch #temp tables live
 in tempdb and are left in place after the run for ad-hoc inspection
 (#TemplateDiff, #SequenceDiff, #ElementDiff, plus the canonical
 #Left... / #Right... tables).

 Usage: enable SQLCMD mode (SSMS) or run via sqlcmd / TigerQuery SqlCmdEx;
 adjust the two :setvar lines below and execute the whole file.

 Output:
   1. Summary — row counts and verdict per table
   2. [Static].[Template] differences        (empty = logically identical)
   3. [Parser].[TSqlSequence] differences    (empty = logically identical)
   4. [Parser].[TSqlSeqElement] differences  (empty = logically identical)

 Difference result sets are stacked: DiffType is OnlyInLeft / OnlyInRight /
 Different; 'Different' keys show one row per side (Side = Left / Right).
 String values are compared with a binary collation (case/accent-exact), and
 template text additionally by DATALENGTH (catches trailing-whitespace-only
 differences that padded string comparison would hide).
================================================================================
*/

:setvar LeftDatabase  "TigerWrapDb_A"
:setvar RightDatabase "TigerWrapDb_B"

SET NOCOUNT ON;

IF DB_ID(N'$(LeftDatabase)') IS NULL
    THROW 50000, N'Left database [$(LeftDatabase)] does not exist on this server.', 1;
IF DB_ID(N'$(RightDatabase)') IS NULL
    THROW 50000, N'Right database [$(RightDatabase)] does not exist on this server.', 1;

--------------------------------------------------------------------------------
-- 1. [Static].[Template] — canonical form and differences
--------------------------------------------------------------------------------

DROP TABLE IF EXISTS #LeftTemplate;
DROP TABLE IF EXISTS #RightTemplate;
DROP TABLE IF EXISTS #TemplateDiff;

SELECT
    [Language]        = COALESCE(l.[Name], CONCAT('id:', t.[LanguageId])) COLLATE Latin1_General_100_BIN2,
    [TemplateType]    = COALESCE(tt.[Name], CONCAT('id:', t.[TypeId])) COLLATE Latin1_General_100_BIN2,
    [LanguageOptions] = t.[LanguageOptions],
    [TemplateLength]  = DATALENGTH(t.[Template]),
    [TemplateText]    = t.[Template] COLLATE Latin1_General_100_BIN2
INTO #LeftTemplate
FROM [$(LeftDatabase)].[Static].[Template] t
LEFT JOIN [$(LeftDatabase)].[Enum].[Language]     l  ON l.[Id]  = t.[LanguageId]
LEFT JOIN [$(LeftDatabase)].[Enum].[TemplateType] tt ON tt.[Id] = t.[TypeId];

SELECT
    [Language]        = COALESCE(l.[Name], CONCAT('id:', t.[LanguageId])) COLLATE Latin1_General_100_BIN2,
    [TemplateType]    = COALESCE(tt.[Name], CONCAT('id:', t.[TypeId])) COLLATE Latin1_General_100_BIN2,
    [LanguageOptions] = t.[LanguageOptions],
    [TemplateLength]  = DATALENGTH(t.[Template]),
    [TemplateText]    = t.[Template] COLLATE Latin1_General_100_BIN2
INTO #RightTemplate
FROM [$(RightDatabase)].[Static].[Template] t
LEFT JOIN [$(RightDatabase)].[Enum].[Language]     l  ON l.[Id]  = t.[LanguageId]
LEFT JOIN [$(RightDatabase)].[Enum].[TemplateType] tt ON tt.[Id] = t.[TypeId];

WITH [LeftOnly] AS
    (SELECT * FROM #LeftTemplate EXCEPT SELECT * FROM #RightTemplate),
[RightOnly] AS
    (SELECT * FROM #RightTemplate EXCEPT SELECT * FROM #LeftTemplate),
[Stacked] AS
    (SELECT [Side] = 'Left',  * FROM [LeftOnly]
     UNION ALL
     SELECT [Side] = 'Right', * FROM [RightOnly])
SELECT
    [DiffType] = CASE
                     WHEN COUNT(*) OVER (PARTITION BY [Language], [TemplateType], [LanguageOptions]) > 1
                         THEN 'Different'
                     WHEN [Side] = 'Left' THEN 'OnlyInLeft'
                     ELSE 'OnlyInRight'
                 END,
    *
INTO #TemplateDiff
FROM [Stacked];

--------------------------------------------------------------------------------
-- 2. [Parser].[TSqlSequence] — canonical form and differences
--------------------------------------------------------------------------------

DROP TABLE IF EXISTS #LeftSequence;
DROP TABLE IF EXISTS #RightSequence;
DROP TABLE IF EXISTS #SequenceDiff;

SELECT
    [Name]          = sq.[Name] COLLATE Latin1_General_100_BIN2,
    [SequenceType]  = COALESCE(sqt.[Name], CONCAT('id:', sq.[SequenceTypeId])) COLLATE Latin1_General_100_BIN2,
    [StatementType] = CASE
                          WHEN sq.[StatementTypeId] IS NULL THEN NULL
                          ELSE COALESCE(st.[Name], CONCAT('id:', sq.[StatementTypeId]))
                      END COLLATE Latin1_General_100_BIN2,
    [Precedence]    = sq.[Precedence]
INTO #LeftSequence
FROM [$(LeftDatabase)].[Parser].[TSqlSequence] sq
LEFT JOIN [$(LeftDatabase)].[ParserEnum].[TSqlSequenceType]  sqt ON sqt.[Id] = sq.[SequenceTypeId]
LEFT JOIN [$(LeftDatabase)].[ParserEnum].[TSqlStatementType] st  ON st.[Id]  = sq.[StatementTypeId];

SELECT
    [Name]          = sq.[Name] COLLATE Latin1_General_100_BIN2,
    [SequenceType]  = COALESCE(sqt.[Name], CONCAT('id:', sq.[SequenceTypeId])) COLLATE Latin1_General_100_BIN2,
    [StatementType] = CASE
                          WHEN sq.[StatementTypeId] IS NULL THEN NULL
                          ELSE COALESCE(st.[Name], CONCAT('id:', sq.[StatementTypeId]))
                      END COLLATE Latin1_General_100_BIN2,
    [Precedence]    = sq.[Precedence]
INTO #RightSequence
FROM [$(RightDatabase)].[Parser].[TSqlSequence] sq
LEFT JOIN [$(RightDatabase)].[ParserEnum].[TSqlSequenceType]  sqt ON sqt.[Id] = sq.[SequenceTypeId]
LEFT JOIN [$(RightDatabase)].[ParserEnum].[TSqlStatementType] st  ON st.[Id]  = sq.[StatementTypeId];

WITH [LeftOnly] AS
    (SELECT * FROM #LeftSequence EXCEPT SELECT * FROM #RightSequence),
[RightOnly] AS
    (SELECT * FROM #RightSequence EXCEPT SELECT * FROM #LeftSequence),
[Stacked] AS
    (SELECT [Side] = 'Left',  * FROM [LeftOnly]
     UNION ALL
     SELECT [Side] = 'Right', * FROM [RightOnly])
SELECT
    [DiffType] = CASE
                     WHEN COUNT(*) OVER (PARTITION BY [Name]) > 1 THEN 'Different'
                     WHEN [Side] = 'Left' THEN 'OnlyInLeft'
                     ELSE 'OnlyInRight'
                 END,
    *
INTO #SequenceDiff
FROM [Stacked];

--------------------------------------------------------------------------------
-- 3. [Parser].[TSqlSeqElement] — canonical form and differences
--
-- Step 1 keeps physical ids so element references can be resolved; step 2
-- replaces every physical id with a structural label:
--   element identity        -> (SequenceName, Ord)   [Ord = rank of Id within the sequence]
--   NextElementId/AltElementId -> "SequenceName#Ord" of the referenced element
--------------------------------------------------------------------------------

DROP TABLE IF EXISTS #LeftElemRaw;
DROP TABLE IF EXISTS #RightElemRaw;
DROP TABLE IF EXISTS #LeftElem;
DROP TABLE IF EXISTS #RightElem;
DROP TABLE IF EXISTS #ElementDiff;

SELECT
    e.[Id],
    [SequenceName] = sq.[Name] COLLATE Latin1_General_100_BIN2,
    [Ord]          = ROW_NUMBER() OVER (PARTITION BY e.[SequenceId] ORDER BY e.[Id]),
    e.[TypeId], e.[IsStartElement], e.[NextElementId], e.[AltElementId],
    e.[KeywordId], e.[OperatorId], e.[SequenceTypeId], e.[StatementPartId],
    e.[TokenTypeId], e.[TokenSubtypeId], e.[StatementTypeId],
    e.[StringValue], e.[IntValue]
INTO #LeftElemRaw
FROM [$(LeftDatabase)].[Parser].[TSqlSeqElement] e
JOIN [$(LeftDatabase)].[Parser].[TSqlSequence] sq ON sq.[Id] = e.[SequenceId];

SELECT
    e.[Id],
    [SequenceName] = sq.[Name] COLLATE Latin1_General_100_BIN2,
    [Ord]          = ROW_NUMBER() OVER (PARTITION BY e.[SequenceId] ORDER BY e.[Id]),
    e.[TypeId], e.[IsStartElement], e.[NextElementId], e.[AltElementId],
    e.[KeywordId], e.[OperatorId], e.[SequenceTypeId], e.[StatementPartId],
    e.[TokenTypeId], e.[TokenSubtypeId], e.[StatementTypeId],
    e.[StringValue], e.[IntValue]
INTO #RightElemRaw
FROM [$(RightDatabase)].[Parser].[TSqlSeqElement] e
JOIN [$(RightDatabase)].[Parser].[TSqlSequence] sq ON sq.[Id] = e.[SequenceId];

SELECT
    [SequenceName]   = r.[SequenceName],
    [Ord]            = r.[Ord],
    [IsStartElement] = r.[IsStartElement],
    [ElementType]    = COALESCE(et.[Name], CONCAT('id:', r.[TypeId])) COLLATE Latin1_General_100_BIN2,
    [NextElement]    = CASE
                           WHEN r.[NextElementId] IS NULL THEN NULL
                           WHEN nx.[Id] IS NULL THEN CONCAT('<dangling id:', r.[NextElementId], '>')
                           ELSE CONCAT(nx.[SequenceName], '#', nx.[Ord])
                       END COLLATE Latin1_General_100_BIN2,
    [AltElement]     = CASE
                           WHEN r.[AltElementId] IS NULL THEN NULL
                           WHEN ax.[Id] IS NULL THEN CONCAT('<dangling id:', r.[AltElementId], '>')
                           ELSE CONCAT(ax.[SequenceName], '#', ax.[Ord])
                       END COLLATE Latin1_General_100_BIN2,
    [Keyword]        = CASE
                           WHEN r.[KeywordId] IS NULL THEN NULL
                           ELSE COALESCE(kw.[Name], CONCAT('id:', r.[KeywordId]))
                       END COLLATE Latin1_General_100_BIN2,
    [Operator]       = CASE
                           WHEN r.[OperatorId] IS NULL THEN NULL
                           ELSE COALESCE(op.[Name], CONCAT('id:', r.[OperatorId]))
                       END COLLATE Latin1_General_100_BIN2,
    [SequenceType]   = CASE
                           WHEN r.[SequenceTypeId] IS NULL THEN NULL
                           ELSE COALESCE(sqt.[Name], CONCAT('id:', r.[SequenceTypeId]))
                       END COLLATE Latin1_General_100_BIN2,
    [StatementPart]  = CASE
                           WHEN r.[StatementPartId] IS NULL THEN NULL
                           ELSE COALESCE(sp.[Name], CONCAT('id:', r.[StatementPartId]))
                       END COLLATE Latin1_General_100_BIN2,
    [TokenType]      = CASE
                           WHEN r.[TokenTypeId] IS NULL THEN NULL
                           ELSE COALESCE(tt.[Name], CONCAT('id:', r.[TokenTypeId]))
                       END COLLATE Latin1_General_100_BIN2,
    [TokenSubtype]   = CASE
                           WHEN r.[TokenSubtypeId] IS NULL THEN NULL
                           ELSE COALESCE(tst.[Name], CONCAT('id:', r.[TokenSubtypeId]))
                       END COLLATE Latin1_General_100_BIN2,
    [StatementType]  = CASE
                           WHEN r.[StatementTypeId] IS NULL THEN NULL
                           ELSE COALESCE(st.[Name], CONCAT('id:', r.[StatementTypeId]))
                       END COLLATE Latin1_General_100_BIN2,
    [StringValue]    = r.[StringValue] COLLATE Latin1_General_100_BIN2,
    [IntValue]       = r.[IntValue]
INTO #LeftElem
FROM #LeftElemRaw r
LEFT JOIN #LeftElemRaw nx ON nx.[Id] = r.[NextElementId]
LEFT JOIN #LeftElemRaw ax ON ax.[Id] = r.[AltElementId]
LEFT JOIN [$(LeftDatabase)].[ParserEnum].[TSqlSeqElementType] et  ON et.[Id]  = r.[TypeId]
LEFT JOIN [$(LeftDatabase)].[ParserEnum].[TSqlKeyword]        kw  ON kw.[Id]  = r.[KeywordId]
LEFT JOIN [$(LeftDatabase)].[Parser].[Operator]               op  ON op.[Id]  = r.[OperatorId]
LEFT JOIN [$(LeftDatabase)].[ParserEnum].[TSqlSequenceType]   sqt ON sqt.[Id] = r.[SequenceTypeId]
LEFT JOIN [$(LeftDatabase)].[ParserEnum].[TSqlStatementPart]  sp  ON sp.[Id]  = r.[StatementPartId]
LEFT JOIN [$(LeftDatabase)].[ParserEnum].[TokenType]          tt  ON tt.[Id]  = r.[TokenTypeId]
LEFT JOIN [$(LeftDatabase)].[ParserEnum].[TokenSubtype]       tst ON tst.[Id] = r.[TokenSubtypeId]
LEFT JOIN [$(LeftDatabase)].[ParserEnum].[TSqlStatementType]  st  ON st.[Id]  = r.[StatementTypeId];

SELECT
    [SequenceName]   = r.[SequenceName],
    [Ord]            = r.[Ord],
    [IsStartElement] = r.[IsStartElement],
    [ElementType]    = COALESCE(et.[Name], CONCAT('id:', r.[TypeId])) COLLATE Latin1_General_100_BIN2,
    [NextElement]    = CASE
                           WHEN r.[NextElementId] IS NULL THEN NULL
                           WHEN nx.[Id] IS NULL THEN CONCAT('<dangling id:', r.[NextElementId], '>')
                           ELSE CONCAT(nx.[SequenceName], '#', nx.[Ord])
                       END COLLATE Latin1_General_100_BIN2,
    [AltElement]     = CASE
                           WHEN r.[AltElementId] IS NULL THEN NULL
                           WHEN ax.[Id] IS NULL THEN CONCAT('<dangling id:', r.[AltElementId], '>')
                           ELSE CONCAT(ax.[SequenceName], '#', ax.[Ord])
                       END COLLATE Latin1_General_100_BIN2,
    [Keyword]        = CASE
                           WHEN r.[KeywordId] IS NULL THEN NULL
                           ELSE COALESCE(kw.[Name], CONCAT('id:', r.[KeywordId]))
                       END COLLATE Latin1_General_100_BIN2,
    [Operator]       = CASE
                           WHEN r.[OperatorId] IS NULL THEN NULL
                           ELSE COALESCE(op.[Name], CONCAT('id:', r.[OperatorId]))
                       END COLLATE Latin1_General_100_BIN2,
    [SequenceType]   = CASE
                           WHEN r.[SequenceTypeId] IS NULL THEN NULL
                           ELSE COALESCE(sqt.[Name], CONCAT('id:', r.[SequenceTypeId]))
                       END COLLATE Latin1_General_100_BIN2,
    [StatementPart]  = CASE
                           WHEN r.[StatementPartId] IS NULL THEN NULL
                           ELSE COALESCE(sp.[Name], CONCAT('id:', r.[StatementPartId]))
                       END COLLATE Latin1_General_100_BIN2,
    [TokenType]      = CASE
                           WHEN r.[TokenTypeId] IS NULL THEN NULL
                           ELSE COALESCE(tt.[Name], CONCAT('id:', r.[TokenTypeId]))
                       END COLLATE Latin1_General_100_BIN2,
    [TokenSubtype]   = CASE
                           WHEN r.[TokenSubtypeId] IS NULL THEN NULL
                           ELSE COALESCE(tst.[Name], CONCAT('id:', r.[TokenSubtypeId]))
                       END COLLATE Latin1_General_100_BIN2,
    [StatementType]  = CASE
                           WHEN r.[StatementTypeId] IS NULL THEN NULL
                           ELSE COALESCE(st.[Name], CONCAT('id:', r.[StatementTypeId]))
                       END COLLATE Latin1_General_100_BIN2,
    [StringValue]    = r.[StringValue] COLLATE Latin1_General_100_BIN2,
    [IntValue]       = r.[IntValue]
INTO #RightElem
FROM #RightElemRaw r
LEFT JOIN #RightElemRaw nx ON nx.[Id] = r.[NextElementId]
LEFT JOIN #RightElemRaw ax ON ax.[Id] = r.[AltElementId]
LEFT JOIN [$(RightDatabase)].[ParserEnum].[TSqlSeqElementType] et  ON et.[Id]  = r.[TypeId]
LEFT JOIN [$(RightDatabase)].[ParserEnum].[TSqlKeyword]        kw  ON kw.[Id]  = r.[KeywordId]
LEFT JOIN [$(RightDatabase)].[Parser].[Operator]               op  ON op.[Id]  = r.[OperatorId]
LEFT JOIN [$(RightDatabase)].[ParserEnum].[TSqlSequenceType]   sqt ON sqt.[Id] = r.[SequenceTypeId]
LEFT JOIN [$(RightDatabase)].[ParserEnum].[TSqlStatementPart]  sp  ON sp.[Id]  = r.[StatementPartId]
LEFT JOIN [$(RightDatabase)].[ParserEnum].[TokenType]          tt  ON tt.[Id]  = r.[TokenTypeId]
LEFT JOIN [$(RightDatabase)].[ParserEnum].[TokenSubtype]       tst ON tst.[Id] = r.[TokenSubtypeId]
LEFT JOIN [$(RightDatabase)].[ParserEnum].[TSqlStatementType]  st  ON st.[Id]  = r.[StatementTypeId];

WITH [LeftOnly] AS
    (SELECT * FROM #LeftElem EXCEPT SELECT * FROM #RightElem),
[RightOnly] AS
    (SELECT * FROM #RightElem EXCEPT SELECT * FROM #LeftElem),
[Stacked] AS
    (SELECT [Side] = 'Left',  * FROM [LeftOnly]
     UNION ALL
     SELECT [Side] = 'Right', * FROM [RightOnly])
SELECT
    [DiffType] = CASE
                     WHEN COUNT(*) OVER (PARTITION BY [SequenceName], [Ord]) > 1 THEN 'Different'
                     WHEN [Side] = 'Left' THEN 'OnlyInLeft'
                     ELSE 'OnlyInRight'
                 END,
    *
INTO #ElementDiff
FROM [Stacked];

--------------------------------------------------------------------------------
-- 4. Results
--------------------------------------------------------------------------------

DECLARE @templateDiffCount INT = (SELECT COUNT(*) FROM #TemplateDiff);
DECLARE @sequenceDiffCount INT = (SELECT COUNT(*) FROM #SequenceDiff);
DECLARE @elementDiffCount  INT = (SELECT COUNT(*) FROM #ElementDiff);

-- Result set 1: summary
SELECT
    [TableName] = '[Static].[Template]',
    [LeftDb]    = '$(LeftDatabase)',
    [RightDb]   = '$(RightDatabase)',
    [LeftRows]  = (SELECT COUNT(*) FROM #LeftTemplate),
    [RightRows] = (SELECT COUNT(*) FROM #RightTemplate),
    [DiffRows]  = @templateDiffCount,
    [Verdict]   = CASE WHEN @templateDiffCount = 0 THEN 'LOGICALLY IDENTICAL' ELSE 'DIFFERENT' END
UNION ALL
SELECT
    '[Parser].[TSqlSequence]',
    '$(LeftDatabase)',
    '$(RightDatabase)',
    (SELECT COUNT(*) FROM #LeftSequence),
    (SELECT COUNT(*) FROM #RightSequence),
    @sequenceDiffCount,
    CASE WHEN @sequenceDiffCount = 0 THEN 'LOGICALLY IDENTICAL' ELSE 'DIFFERENT' END
UNION ALL
SELECT
    '[Parser].[TSqlSeqElement]',
    '$(LeftDatabase)',
    '$(RightDatabase)',
    (SELECT COUNT(*) FROM #LeftElem),
    (SELECT COUNT(*) FROM #RightElem),
    @elementDiffCount,
    CASE WHEN @elementDiffCount = 0 THEN 'LOGICALLY IDENTICAL' ELSE 'DIFFERENT' END;

-- Result set 2: [Static].[Template] differences
SELECT *
FROM #TemplateDiff
ORDER BY [Language], [TemplateType], [LanguageOptions], [Side];

-- Result set 3: [Parser].[TSqlSequence] differences
SELECT *
FROM #SequenceDiff
ORDER BY [Name], [Side];

-- Result set 4: [Parser].[TSqlSeqElement] differences
SELECT *
FROM #ElementDiff
ORDER BY [SequenceName], [Ord], [Side];

IF @templateDiffCount = 0 AND @sequenceDiffCount = 0 AND @elementDiffCount = 0
    PRINT 'RESULT: [Static].[Template], [Parser].[TSqlSequence] and [Parser].[TSqlSeqElement] are logically identical between [$(LeftDatabase)] and [$(RightDatabase)].';
ELSE
    PRINT 'RESULT: logical differences found - inspect the difference result sets (also available as #TemplateDiff / #SequenceDiff / #ElementDiff).';
