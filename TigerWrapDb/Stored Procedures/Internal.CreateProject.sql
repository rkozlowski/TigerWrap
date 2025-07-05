CREATE PROCEDURE [Internal].[CreateProject]
    @name NVARCHAR(200),
    @namespaceName VARCHAR(100),
    @className VARCHAR(100),
    @classAccessId TINYINT,
    @languageId TINYINT,
    @paramEnumMappingId TINYINT,
    @mapResultSetEnums BIT,
    @languageOptions BIGINT,
    @defaultDatabase NVARCHAR(128) = NULL,
    @enumSchema NVARCHAR(128) = NULL,
    @storedProcSchema NVARCHAR(128) = NULL,
    @projectId SMALLINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @NM_ANY TINYINT = 255; -- Enum.NameMatch: 'Any'

    INSERT INTO [dbo].[Project] 
    ([Name], [NamespaceName], [ClassName], [ClassAccessId], [LanguageId], [ParamEnumMappingId], [MapResultSetEnums], [LanguageOptions], [DefaultDatabase])
    VALUES
    (@name, @namespaceName, @className, @classAccessId, @languageId, @paramEnumMappingId, @mapResultSetEnums, @languageOptions, @defaultDatabase);

    SET @projectId = SCOPE_IDENTITY();

    IF @enumSchema IS NOT NULL
    BEGIN
        INSERT INTO [dbo].[ProjectEnum] 
        ([ProjectId], [Schema], [NameMatchId], [NamePattern], [EscChar], [IsSetOfFlags])
        VALUES
        (@projectId, @enumSchema, @NM_ANY, NULL, NULL, 0);
    END

    IF @storedProcSchema IS NOT NULL
    BEGIN
        INSERT INTO [dbo].[ProjectStoredProc]
        ([ProjectId], [Schema], [NameMatchId], [NamePattern], [EscChar], [LanguageOptionsReset], [LanguageOptionsSet])
        VALUES
        (@projectId, @storedProcSchema, @NM_ANY, NULL, NULL, NULL, NULL);
    END

	RETURN 0;
END