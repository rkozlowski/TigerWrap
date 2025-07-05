CREATE TABLE [ParserEnum].[TSqlStatementType] (
    [Id]                          SMALLINT     NOT NULL,
    [Name]                        VARCHAR (50) NOT NULL,
    [StartKeywordId]              SMALLINT     NOT NULL,
    [AlwaysStartWithStartKeyword] BIT          CONSTRAINT [DF_ParserEnum_TSqlStatementType_AlwaysStartWithStartKeyword] DEFAULT ((0)) NOT NULL,
    [IsSingleKeywordStatement]    BIT          CONSTRAINT [DF_ParserEnum_TSqlStatementType_IsSingleKeywordStatement] DEFAULT ((0)) NOT NULL,
    [CannotStopPreviousStatement] BIT          CONSTRAINT [DF_ParserEnum_TSqlStatementType_CannotStopPreviousStatement] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ParserEnum_TSqlStatementType] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_ParserEnum_TSqlStatementType_TSqlKeyword] FOREIGN KEY ([StartKeywordId]) REFERENCES [ParserEnum].[TSqlKeyword] ([Id])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_ParserEnum_TSqlStatementType_Name]
    ON [ParserEnum].[TSqlStatementType]([Name] ASC);

