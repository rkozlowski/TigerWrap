CREATE TABLE [ParserEnum].[TSqlSequenceType] (
    [Id]   TINYINT      NOT NULL,
    [Name] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_ParserEnum_TSqlSequenceType] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [UX_ParserEnum_TSqlSequenceType_Name]
    ON [ParserEnum].[TSqlSequenceType]([Name] ASC);

