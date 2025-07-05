
CREATE FUNCTION [Internal].[GetNameEx]
(	
	@projectId TINYINT,
	@typeId TINYINT,
	@sourceId TINYINT,
	@name NVARCHAR(128),
	@schema NVARCHAR(128)
)
RETURNS NVARCHAR(200)
AS
BEGIN
	DECLARE @prefix NVARCHAR(128), @suffix NVARCHAR(128);
	SELECT TOP (1) @prefix = nn.[NamePart] 
	FROM [dbo].[ProjectNameNormalization] nn
	JOIN [Enum].[NamePartType] t ON nn.[NamePartTypeId]=t.[Id]
	WHERE t.[NameSourceId]=@sourceId AND nn.[ProjectId]=@projectId AND t.[IsPrefix]=1
	AND LEFT(@name, LEN(nn.[NamePart]))=nn.[NamePart]
	ORDER BY LEN(nn.[NamePart]) DESC;

	IF @prefix IS NOT NULL
	BEGIN
		SET @name = [Internal].[RemoveFromStart](@name, @prefix);
	END

	SELECT TOP (1) @suffix = nn.[NamePart] 
	FROM [dbo].[ProjectNameNormalization] nn
	JOIN [Enum].[NamePartType] t ON nn.[NamePartTypeId]=t.[Id]
	WHERE t.[NameSourceId]=@sourceId AND nn.[ProjectId]=@projectId AND t.[IsSuffix]=1
	AND RIGHT(@name, LEN(nn.[NamePart]))=nn.[NamePart]
	ORDER BY LEN(nn.[NamePart]) DESC;

	IF @suffix IS NOT NULL
	BEGIN
		SET @name = [Internal].[RemoveFromEnd](@name, @suffix);
	END

	DECLARE @result NVARCHAR(200) = [Internal].[GetName](@projectId, @typeId, @name, @schema);
	RETURN @result;
END
