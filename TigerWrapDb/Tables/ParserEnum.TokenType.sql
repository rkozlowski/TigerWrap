CREATE TABLE [ParserEnum].[TokenType] (
    [Id]   TINYINT      NOT NULL,
    [Name] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_ParserEnum_TokenType] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_ParserEnum_TokenType_Name]
    ON [ParserEnum].[TokenType]([Name] ASC);

