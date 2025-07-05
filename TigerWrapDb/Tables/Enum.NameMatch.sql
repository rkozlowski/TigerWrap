CREATE TABLE [Enum].[NameMatch] (
    [Id]   TINYINT      NOT NULL,
    [Name] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_NameMatch] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_NameMatch_Name]
    ON [Enum].[NameMatch]([Name] ASC);

