CREATE TABLE [Enum].[ClassAccess] (
    [Id]   TINYINT       NOT NULL,
    [Name] VARCHAR (200) NOT NULL,
    CONSTRAINT [PK_Enum_ClassAccess] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_Enum_ClassAccess_Name]
    ON [Enum].[ClassAccess]([Name] ASC);

