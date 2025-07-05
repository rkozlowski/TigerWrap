CREATE TABLE [Enum].[NamePartType] (
    [Id]           TINYINT      NOT NULL,
    [Name]         VARCHAR (50) NOT NULL,
    [NameSourceId] TINYINT      NULL,
    [IsPrefix]     BIT          CONSTRAINT [DF_NamePartType_IsPreffix] DEFAULT ((0)) NOT NULL,
    [IsSuffix]     BIT          CONSTRAINT [DF_NamePartType_IsSuffix] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_NamePartType] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_NamePartType_Name]
    ON [Enum].[NamePartType]([Name] ASC);

