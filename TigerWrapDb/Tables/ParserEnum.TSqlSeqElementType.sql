CREATE TABLE [ParserEnum].[TSqlSeqElementType] (
    [Id]   TINYINT      NOT NULL,
    [Name] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_ParserEnum_TSqlSeqElementType] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_ParserEnum_TSqlSeqElementType_Name]
    ON [ParserEnum].[TSqlSeqElementType]([Name] ASC);

