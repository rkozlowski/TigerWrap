
CREATE FUNCTION [Internal].[ProcessTemplate]
(
	@template NVARCHAR(4000),
	@vars [Internal].[Variable] READONLY	
)
RETURNS 
@result TABLE 
(
	[Id] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[Text] NVARCHAR(4000)
)
AS
BEGIN
	DECLARE @id INT = (SELECT MIN([Id]) FROM @vars);
	WHILE @id IS NOT NULL
	BEGIN
		SELECT @template = REPLACE(@template, N'@{' + [Name] + N'}', ISNULL([Value], N''))
		FROM @vars
		WHERE [Id]=@id;
		SELECT @id=MIN([Id]) FROM @vars
		WHERE [Id]>@id;
	END
	INSERT INTO @result ([Text])
	SELECT d.[Item]
	FROM [dbo].[DelimitedSplitN4K](@template, CHAR(10)) d
	ORDER BY d.[ItemNumber];
	UPDATE @result
	SET [Text]=REPLACE([Text], CHAR(13), '');
	RETURN 
END