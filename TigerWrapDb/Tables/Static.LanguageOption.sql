CREATE TABLE [Static].[LanguageOption] (
    [Id]                         SMALLINT     IDENTITY (1, 1) NOT NULL,
    [LanguageId]                 TINYINT      NULL,
    [Name]                       VARCHAR (50) NOT NULL,
    [Value]                      BIGINT       NOT NULL,
    [IsPrimary]                  BIT          CONSTRAINT [DF_LanguageOption_IsPrimary] DEFAULT ((1)) NOT NULL,
    [IsOverridablePerStoredProc] BIT          CONSTRAINT [DF_LanguageOption_IsOverridablePerStoredProc] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_LanguageOption] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_LanguageOption_Language] FOREIGN KEY ([LanguageId]) REFERENCES [Enum].[Language] ([Id])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_LanguageOption_LanguageId_Name]
    ON [Static].[LanguageOption]([LanguageId] ASC, [Name] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_LanguageOption_IsPrimary_Name]
    ON [Static].[LanguageOption]([IsPrimary] ASC, [Name] ASC)
    INCLUDE([LanguageId], [Value]);


GO
CREATE UNIQUE NONCLUSTERED INDEX [FU_LanguageOption_LanguageId_IsPrimary_Value]
    ON [Static].[LanguageOption]([LanguageId] ASC, [IsPrimary] ASC, [Value] ASC) WHERE ([IsPrimary]=(1));

