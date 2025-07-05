CREATE TABLE [dbo].[ProjectStoredProc] (
    [Id]                   INT            IDENTITY (1, 1) NOT NULL,
    [ProjectId]            SMALLINT       NOT NULL,
    [Schema]               NVARCHAR (128) NOT NULL,
    [NameMatchId]          TINYINT        NOT NULL,
    [NamePattern]          NVARCHAR (200) NULL,
    [EscChar]              NCHAR (1)      NULL,
    [LanguageOptionsReset] BIGINT         NULL,
    [LanguageOptionsSet]   BIGINT         NULL,
    CONSTRAINT [PK_ProjectStoredProc] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_ProjectStoredProc_NameMatch] FOREIGN KEY ([NameMatchId]) REFERENCES [Enum].[NameMatch] ([Id]),
    CONSTRAINT [FK_ProjectStoredProc_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([Id])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_ProjectStoredProc_ProjectId_Schema_NameMatchId_NamePattern]
    ON [dbo].[ProjectStoredProc]([ProjectId] ASC, [Schema] ASC, [NameMatchId] ASC, [NamePattern] ASC);

