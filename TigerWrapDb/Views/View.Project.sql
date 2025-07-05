


CREATE VIEW [View].[Project]
AS
SELECT p.[Id], p.[Name], p.[NamespaceName], p.[ClassName], p.[ClassAccessId], ca.[Name] [ClassAccess], p.[LanguageId], l.[Name] AS [Language], 
    p.[LanguageOptions], [Internal].[GetLanguageOptionsString](p.[LanguageId], p.[LanguageOptions]) [LanguageOptionList], p.[ParamEnumMappingId], 
    m.[Name] [ParamEnumMapping], p.[MapResultSetEnums], p.[DefaultDatabase]
FROM [dbo].[Project] p
INNER JOIN [Enum].[ClassAccess] ca ON p.[ClassAccessId] = ca.[Id]
INNER JOIN [Enum].[Language] l ON p.[LanguageId] = l.Id 
INNER JOIN [Enum].[ParamEnumMapping] m ON p.[ParamEnumMappingId] = m.[Id];