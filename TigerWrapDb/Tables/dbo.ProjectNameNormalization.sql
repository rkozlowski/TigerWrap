CREATE TABLE [dbo].[ProjectNameNormalization] (
    [Id]             INT            IDENTITY (1, 1) NOT NULL,
    [ProjectId]      SMALLINT       NOT NULL,
    [NamePart]       NVARCHAR (128) NOT NULL,
    [NamePartTypeId] TINYINT        NOT NULL,
    CONSTRAINT [PK_ProjectNameNormalization] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_ProjectNameNormalization_NamePartType] FOREIGN KEY ([NamePartTypeId]) REFERENCES [Enum].[NamePartType] ([Id]),
    CONSTRAINT [FK_ProjectNameNormalization_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([Id])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_ProjectNameNormalization_ProjectId_NamePartTypeId_NamePart]
    ON [dbo].[ProjectNameNormalization]([ProjectId] ASC, [NamePartTypeId] ASC, [NamePart] ASC);

