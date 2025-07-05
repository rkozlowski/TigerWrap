CREATE TABLE [dbo].[ProjectEnum] (
    [Id]           INT            IDENTITY (1, 1) NOT NULL,
    [ProjectId]    SMALLINT       NOT NULL,
    [Schema]       NVARCHAR (128) NOT NULL,
    [NameMatchId]  TINYINT        NOT NULL,
    [NamePattern]  NVARCHAR (200) NULL,
    [EscChar]      NCHAR (1)      NULL,
    [IsSetOfFlags] BIT            CONSTRAINT [DF_ProjectEnum_IsSetOfFlags] DEFAULT ((0)) NOT NULL,
    [NameColumn]   NVARCHAR (128) NULL,
    CONSTRAINT [PK_ProjectEnum] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_ProjectEnum_NameMatch] FOREIGN KEY ([NameMatchId]) REFERENCES [Enum].[NameMatch] ([Id]),
    CONSTRAINT [FK_ProjectEnum_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([Id])
);




GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_ProjectEnum_ProjectId_Schema_NameMatchId_NamePattern]
    ON [dbo].[ProjectEnum]([ProjectId] ASC, [Schema] ASC, [NameMatchId] ASC, [NamePattern] ASC);

