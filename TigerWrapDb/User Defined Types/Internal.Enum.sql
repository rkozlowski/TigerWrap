CREATE TYPE [Internal].[Enum] AS TABLE (
    [Id]          INT            IDENTITY (1, 1) NOT NULL,
    [Schema]      NVARCHAR (128) NOT NULL,
    [Table]       NVARCHAR (128) NOT NULL,
    [EnumName]    NVARCHAR (256) NOT NULL,
    [NameColumn]  NVARCHAR (128) NOT NULL,
    [ValueColumn] NVARCHAR (128) NOT NULL,
    UNIQUE NONCLUSTERED ([Schema] ASC, [Table] ASC),
    UNIQUE NONCLUSTERED ([EnumName] ASC),
    PRIMARY KEY CLUSTERED ([Id] ASC));

