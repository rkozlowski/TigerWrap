SET NOCOUNT ON;
GO

SELECT 
CAST(N'IF NOT EXISTS (SELECT 1 FROM [Static].[LanguageOption] WHERE [LanguageId]' + ISNULL(CAST('=' + LOWER([LanguageId]) AS VARCHAR(20)), ' IS NULL') 
+ ' AND [Name]=' + QUOTENAME([Name], '''') + ')
BEGIN
	INSERT INTO [Static].[LanguageOption] ([LanguageId], [Name], [Value], [IsOverridablePerStoredProc])
	VALUES (' + ISNULL(LOWER([LanguageId]), 'NULL') + ', ' + QUOTENAME([Name], '''') + ', ' + CONVERT(VARCHAR(20), CAST([Value] AS BINARY(8)), 1) 
	+ ', ' + LOWER([IsOverridablePerStoredProc]) + ');
END;

' AS NVARCHAR(350)) [-- table [Static]].[LanguageOption]]]
FROM [Static].[LanguageOption]
ORDER BY ISNULL([LanguageId], 0), [Value];
