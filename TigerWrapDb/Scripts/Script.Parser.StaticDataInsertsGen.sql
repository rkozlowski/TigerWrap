SET NOCOUNT ON;
GO

SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSequenceType] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) 
	+ N'INSERT INTO [ParserEnum].[TSqlSequenceType] ([Id], [Name]) ' 
	+ CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Name], N'''') + N');' 
	+ CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [ParserEnum]].[TSqlSequenceType]]]
FROM [ParserEnum].[TSqlSequenceType]
ORDER BY [Id];

SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlBlockType] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) 
	+ N'INSERT INTO [ParserEnum].[TSqlBlockType] ([Id], [Name]) ' 
	+ CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Name], N'''') + N');' 
	+ CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [ParserEnum]].[TSqlBlockType]]]
FROM [ParserEnum].[TSqlBlockType]
ORDER BY [Id];

SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlStatementPart] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) 
	+ N'INSERT INTO [ParserEnum].[TSqlStatementPart] ([Id], [Name]) ' 
	+ CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Name], N'''') + N');' 
	+ CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [ParserEnum]].[TSqlStatementPart]]]
FROM [ParserEnum].[TSqlStatementPart]
ORDER BY [Id];

SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenType] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) 
	+ N'INSERT INTO [ParserEnum].[TokenType] ([Id], [Name]) ' 
	+ CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Name], N'''') + N');' 
	+ CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [ParserEnum]].[TokenType]]]
FROM [ParserEnum].[TokenType]
ORDER BY [Id];

SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlKeyword] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) 
	+ N'INSERT INTO [ParserEnum].[TSqlKeyword] ([Id], [Name]) ' 
	+ CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Name], N'''') + N');' 
	+ CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [ParserEnum]].[TSqlKeyword]]]
FROM [ParserEnum].[TSqlKeyword]
ORDER BY [Id];

SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[CharType] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) 
	+ N'INSERT INTO [ParserEnum].[CharType] ([Id], [Name]) ' 
	+ CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Name], N'''') + N');' 
	+ CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [ParserEnum]].[CharType]]]
FROM [ParserEnum].[CharType]
ORDER BY [Id];

SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TSqlSeqElementType] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) 
	+ N'INSERT INTO [ParserEnum].[TSqlSeqElementType] ([Id], [Name]) ' 
	+ CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Name], N'''') + N');' 
	+ CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [ParserEnum]].[TSqlSeqElementType]]]
FROM [ParserEnum].[TSqlSeqElementType]
ORDER BY [Id];


SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [ParserEnum].[TokenSubtype] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) 
	+ N'INSERT INTO [ParserEnum].[TokenSubtype] ([Id], [TypeId], [Name]) ' 
	+ CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', ' + LOWER([TypeId]) + N', N' +  QUOTENAME([Name], N'''') + N');' 
	+ CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [ParserEnum]].[TokenSubtype]]]
FROM [ParserEnum].[TokenSubtype]
ORDER BY [Id];

SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [Parser].[Operator] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) 
    + N'INSERT INTO [Parser].[Operator] ([Id], [Name], [Operator], [Unary], [Binary]) ' + CHAR(13) + CHAR(10) 
    + N'VALUES (' + LOWER([Id]) + N', ' +  QUOTENAME([Name], N'''') + N', ' +  QUOTENAME([Operator], N'''') 
    + N', ' + LOWER([Unary]) + N', ' + LOWER([Binary]) + N');' 
    + CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [Parser]].[Operator]]]
FROM [Parser].[Operator]
ORDER BY [Id];


GO
