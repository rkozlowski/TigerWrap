CREATE TABLE [Static].[LanguageNameCasing] (
    [Id]         SMALLINT IDENTITY (1, 1) NOT NULL,
    [LanguageId] TINYINT  NOT NULL,
    [NameTypeId] TINYINT  NOT NULL,
    [CasingId]   TINYINT  NOT NULL,
    CONSTRAINT [PK_LanguageNameCasing] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_LanguageNameCasing_Casing] FOREIGN KEY ([CasingId]) REFERENCES [Enum].[Casing] ([Id]),
    CONSTRAINT [FK_LanguageNameCasing_Language] FOREIGN KEY ([LanguageId]) REFERENCES [Enum].[Language] ([Id]),
    CONSTRAINT [FK_LanguageNameCasing_NameType] FOREIGN KEY ([NameTypeId]) REFERENCES [Enum].[NameType] ([Id])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_LanguageNameCasing_LanguageId_NameTypeId]
    ON [Static].[LanguageNameCasing]([LanguageId] ASC, [NameTypeId] ASC);

