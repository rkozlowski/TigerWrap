CREATE TABLE [ParserEnum].[TSqlKeyword] (
    [Id]   SMALLINT     NOT NULL,
    [Name] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_ParserEnum_TSqlKeyword] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_ParserEnum_TSqlKeyword_Name]
    ON [ParserEnum].[TSqlKeyword]([Name] ASC);

