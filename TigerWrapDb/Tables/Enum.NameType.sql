CREATE TABLE [Enum].[NameType] (
    [Id]   TINYINT       NOT NULL,
    [Name] VARCHAR (200) NOT NULL,
    CONSTRAINT [PK_Enum_NameType] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_Enum_NameType_Name]
    ON [Enum].[NameType]([Name] ASC);

