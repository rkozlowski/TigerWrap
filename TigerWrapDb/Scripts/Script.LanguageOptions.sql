-- table [Static].[LanguageOption]
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM [Static].[LanguageOption] WHERE [LanguageId] IS NULL AND [Name]='GenerateStaticClass')
BEGIN
	INSERT INTO [Static].[LanguageOption] ([LanguageId], [Name], [Value], [IsOverridablePerStoredProc])
	VALUES (NULL, 'GenerateStaticClass', 0x0000000000000001, 0);
END;

IF NOT EXISTS (SELECT 1 FROM [Static].[LanguageOption] WHERE [LanguageId] IS NULL AND [Name]='TreatOutputParamsAsInputOutput')
BEGIN
	INSERT INTO [Static].[LanguageOption] ([LanguageId], [Name], [Value], [IsOverridablePerStoredProc])
	VALUES (NULL, 'TreatOutputParamsAsInputOutput', 0x0000000000000002, 1);
END;

IF NOT EXISTS (SELECT 1 FROM [Static].[LanguageOption] WHERE [LanguageId] IS NULL AND [Name]='CaptureReturnValueForResultSetStoredProcedures')
BEGIN
	INSERT INTO [Static].[LanguageOption] ([LanguageId], [Name], [Value], [IsOverridablePerStoredProc])
	VALUES (NULL, 'CaptureReturnValueForResultSetStoredProcedures', 0x0000000000000004, 1);
END;


IF NOT EXISTS (SELECT 1 FROM [Static].[LanguageOption] WHERE [LanguageId] IS NULL AND [Name]='OutputMinimalEnvInfo')
BEGIN
	INSERT INTO [Static].[LanguageOption] ([LanguageId], [Name], [Value], [IsOverridablePerStoredProc])
	VALUES (NULL, 'OutputMinimalEnvInfo', 0x0000000000000008, 0);
END;

IF NOT EXISTS (SELECT 1 FROM [Static].[LanguageOption] WHERE [LanguageId] IS NULL AND [Name]='OutputMinimalToolInfo')
BEGIN
	INSERT INTO [Static].[LanguageOption] ([LanguageId], [Name], [Value], [IsOverridablePerStoredProc])
	VALUES (NULL, 'OutputMinimalToolInfo', 0x0000000000000010, 0);
END;

IF NOT EXISTS (SELECT 1 FROM [Static].[LanguageOption] WHERE [LanguageId]=1 AND [Name]='TargetClassicDotNet')
BEGIN
	INSERT INTO [Static].[LanguageOption] ([LanguageId], [Name], [Value], [IsOverridablePerStoredProc])
	VALUES (1, 'TargetClassicDotNet', 0x0000000000010000, 0);
END;

IF NOT EXISTS (SELECT 1 FROM [Static].[LanguageOption] WHERE [LanguageId]=1 AND [Name]='UseSyncWrappers')
BEGIN
	INSERT INTO [Static].[LanguageOption] ([LanguageId], [Name], [Value], [IsOverridablePerStoredProc])
	VALUES (1, 'UseSyncWrappers', 0x0000000000020000, 1);
END;



-- Completion time: 2025-07-05T15:59:22.4522379+01:00
