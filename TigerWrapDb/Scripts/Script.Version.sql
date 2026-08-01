DECLARE @version VARCHAR(50) = '0.9.2';
DECLARE @apiLevel SMALLINT = 2;
DECLARE @minApiLevel SMALLINT = 2;
DECLARE @description NVARCHAR(500) = N'TigerWrap - guarded full installation into an empty database';

IF NOT EXISTS (SELECT 1 FROM [dbo].[SchemaVersion] WHERE [Version]=@version)
BEGIN
	INSERT INTO [dbo].[SchemaVersion] ([Version], [Description], [ApiLevel], [MinApiLevel])
	VALUES (@version, @description, @apiLevel, @minApiLevel);
END

