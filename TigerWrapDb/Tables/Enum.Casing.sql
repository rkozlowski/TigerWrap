CREATE TABLE [Enum].[Casing] (
    [Id]   TINYINT       NOT NULL,
    [Name] VARCHAR (200) NOT NULL,
    CONSTRAINT [PK_Enum_Casing] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_Enum_Casing_Name]
    ON [Enum].[Casing]([Name] ASC);

