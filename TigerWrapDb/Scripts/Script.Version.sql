DECLARE @version VARCHAR(50) = '0.9.0';
DECLARE @apiLevel SMALLINT = 1;
DECLARE @minApiLevel SMALLINT = 1;
DECLARE @description NVARCHAR(500) = N'TigerWrap - new project name'

IF NOT EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [Version]=@version)
BEGIN
	INSERT INTO [dbo].[SchemaVersion] ([Version], [Description], [ApiLevel], [MinApiLevel])
	VALUES (@version, @description, @apiLevel, @minApiLevel);
END
