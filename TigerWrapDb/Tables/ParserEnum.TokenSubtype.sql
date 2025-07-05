CREATE TABLE [ParserEnum].[TokenSubtype] (
    [Id]     TINYINT      NOT NULL,
    [TypeId] TINYINT      NOT NULL,
    [Name]   VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_ParserEnum_TokenSubtype] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_ParserEnum_TokenSubtype_TokenType] FOREIGN KEY ([TypeId]) REFERENCES [ParserEnum].[TokenType] ([Id])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_ParserEnum_TokenSubtype_Name]
    ON [ParserEnum].[TokenSubtype]([Name] ASC);

