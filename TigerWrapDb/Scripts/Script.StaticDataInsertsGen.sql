SET NOCOUNT ON;


SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [Enum].[Status] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) + N'INSERT INTO [Enum].[Status] ([Id], [Name]) ' 
	  + CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Name], N'''') + N');' + CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [Enum]].[Status]]]
FROM [Enum].[Status]
ORDER BY [Id];


SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [Enum].[Language] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) + N'INSERT INTO [Enum].[Language] ([Id], [Name], [Code], [StatusId]) ' 
	  + CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Name], N'''') + N', N' +  QUOTENAME([Code], N'''') + N', ' + LOWER([StatusId]) + N');' + CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [Enum]].[Language]]]
FROM [Enum].[Language]
ORDER BY [Id];


SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [Enum].[ClassAccess] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) + N'INSERT INTO [Enum].[ClassAccess] ([Id], [Name]) ' 
	  + CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Name], N'''') + N');' + CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [Enum]].[ClassAccess]]]
FROM [Enum].[ClassAccess]
ORDER BY [Id];

SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [Enum].[Casing] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) + N'INSERT INTO [Enum].[Casing] ([Id], [Name]) ' 
	  + CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Name], N'''') + N');' + CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [Enum]].[Casing]]]
FROM [Enum].[Casing]
ORDER BY [Id];

SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [Enum].[ParamEnumMapping] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) + N'INSERT INTO [Enum].[ParamEnumMapping] ([Id], [Name]) ' 
	  + CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Name], N'''') + N');' + CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [Enum]].[ParamEnumMapping]]]
FROM [Enum].[ParamEnumMapping]
ORDER BY [Id];

SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [Enum].[TemplateType] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) + N'INSERT INTO [Enum].[TemplateType] ([Id], [Name]) ' 
	  + CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Name], N'''') + N');' + CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [Enum]].[TemplateType]]]
FROM [Enum].[TemplateType]
ORDER BY [Id];

SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [Enum].[NameType] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) + N'INSERT INTO [Enum].[NameType] ([Id], [Name]) ' 
	  + CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Name], N'''') + N');' + CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [Enum]].[NameType]]]
FROM [Enum].[NameType]
ORDER BY [Id];

SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [Static].[DataTypeMap] WHERE [LanguageId]=' + LOWER([LanguageId]) + N' AND [SqlType]=N' + QUOTENAME([SqlType], N'''') 
	  + N') ' + CHAR(13) + CHAR(10) + N'INSERT INTO [Static].[DataTypeMap] ([LanguageId], [SqlType], [NativeType], [SqlDbType], [DbType], [IsNullable], [SizeNeeded], [PrecisionNeeded], [ScaleNeeded]) ' 
	  + CHAR(13) + CHAR(10) + N'VALUES ('
	  + LOWER([LanguageId]) + N', N' + QUOTENAME([SqlType], N'''') + N', N' + QUOTENAME([NativeType], N'''') + N', N' + QUOTENAME([SqlDbType], N'''') + N', N' + QUOTENAME([DbType], N'''') + N', ' 
	  + LOWER([IsNullable]) + N', ' + LOWER([SizeNeeded]) + N', ' + LOWER([PrecisionNeeded]) + N', ' + LOWER([ScaleNeeded])
	  + N');' + CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(400)) [-- table: [Static]].[DataTypeMap]]]
FROM [Static].[DataTypeMap]
ORDER BY [Id];

SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [Static].[LanguageNameCasing] WHERE [LanguageId]=' + LOWER([LanguageId]) + N' AND [NameTypeId]=' + LOWER([NameTypeId]) 
	  + N') ' + CHAR(13) + CHAR(10) + N'INSERT INTO [Static].[LanguageNameCasing] ([LanguageId], [NameTypeId], [CasingId]) ' 
	  + CHAR(13) + CHAR(10) + N'VALUES ('
	  + LOWER([LanguageId]) + N', ' + LOWER([NameTypeId]) + N', ' + LOWER([CasingId])	  
	  + N');' + CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(250)) [-- table: [Static]].[LanguageNameCasing]]]
FROM [Static].[LanguageNameCasing]
ORDER BY [Id]

SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [Enum].[NameMatch] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) + N'INSERT INTO [Enum].[NameMatch] ([Id], [Name]) ' 
	  + CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Name], N'''') + N');' + CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [Enum]].[NameMatch]]]
FROM [Enum].[NameMatch]
ORDER BY [Id];

SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [Enum].[NameSource] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) + N'INSERT INTO [Enum].[NameSource] ([Id], [Name]) ' 
	  + CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Name], N'''') + N');' + CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [Enum]].[NameSource]]]
FROM [Enum].[NameSource]
ORDER BY [Id];

SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [Enum].[NamePartType] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) 
	+ N'INSERT INTO [Enum].[NamePartType] ([Id], [Name], [NameSourceId], [IsPrefix], [IsSuffix]) ' 
	  + CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Name], N'''') 
	  + N', ' + LOWER([NameSourceId]) + N', ' + LOWER([IsPrefix]) + N', ' + LOWER([IsSuffix])
	  + N');' + CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(250)) [-- table [Enum]].[NamePartType]]]
FROM [Enum].[NamePartType]
ORDER BY [Id];

SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [Enum].[ToolkitResponseCode] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) 
	+ N'INSERT INTO [Enum].[ToolkitResponseCode] ([Id], [Name], [Description], [IsSuccess]) ' 
	  + CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Name], N'''') + N', N' +  QUOTENAME([Description], N'''') 
	  + N', ' +  LOWER([IsSuccess]) + N');' + CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(300)) [-- table [Enum]].[ToolkitResponseCode]]]
FROM [Enum].[ToolkitResponseCode]
ORDER BY [Id];



SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [Enum].[CodePart] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) + N'INSERT INTO [Enum].[CodePart] ([Id], [Code], [Name]) ' 
	  + CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Code], N'''') + N', N' +  QUOTENAME([Name], N'''') + N');' + CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [Enum]].[CodePart]]]
FROM [Enum].[CodePart]
ORDER BY [Id];


SELECT CAST(N'IF NOT EXISTS (SELECT 1 FROM [Enum].[LoggingLevel] WHERE [Id]=' + LOWER([Id]) + N') ' + CHAR(13) + CHAR(10) + N'INSERT INTO [Enum].[LoggingLevel] ([Id], [Code], [Name]) ' 
	  + CHAR(13) + CHAR(10) + N'VALUES (' + LOWER([Id]) + N', N' +  QUOTENAME([Code], N'''') + N', N' + QUOTENAME([Name], N'''') + N');' + CHAR(13) + CHAR(10)  + CHAR(13) + CHAR(10) AS NVARCHAR(200)) [-- table [Enum]].[LoggingLevel]]]
FROM [Enum].[LoggingLevel]
ORDER BY [Id];
