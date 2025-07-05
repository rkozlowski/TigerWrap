CREATE TABLE [ParserEnum].[TSqlBlockType] (
    [Id]   TINYINT      NOT NULL,
    [Name] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_ParserEnum_TSqlBlockType] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_ParserEnum_TSqlBlockType_Name]
    ON [ParserEnum].[TSqlBlockType]([Name] ASC);

