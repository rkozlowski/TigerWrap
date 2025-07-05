CREATE TABLE [Enum].[NameSource] (
    [Id]   TINYINT      NOT NULL,
    [Name] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_NameSource] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_NameSource_Name]
    ON [Enum].[NameSource]([Name] ASC);

