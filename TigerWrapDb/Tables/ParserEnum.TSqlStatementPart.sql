CREATE TABLE [ParserEnum].[TSqlStatementPart] (
    [Id]   TINYINT      NOT NULL,
    [Name] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_ParserEnum_TSqlStatementPart] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_ParserEnum_TSqlStatementPart_Name]
    ON [ParserEnum].[TSqlStatementPart]([Name] ASC);

