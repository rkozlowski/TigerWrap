CREATE TABLE [Parser].[TSqlSequence] (
    [Id]              SMALLINT     IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (50) NOT NULL,
    [SequenceTypeId]  TINYINT      CONSTRAINT [DF_Parser_TSqlSequence_SequenceTypeId] DEFAULT ((1)) NOT NULL,
    [StatementTypeId] SMALLINT     NULL,
    [Precedence]      SMALLINT     CONSTRAINT [DF_Parser_TSqlSequence_Priority] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_Parser_TSqlSequence] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Parser_TSqlSequence_TSqlSequenceType] FOREIGN KEY ([SequenceTypeId]) REFERENCES [ParserEnum].[TSqlSequenceType] ([Id]),
    CONSTRAINT [FK_Parser_TSqlSequence_TsqlStatementType] FOREIGN KEY ([StatementTypeId]) REFERENCES [ParserEnum].[TSqlStatementType] ([Id])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_Parser_TSqlSequence_Name]
    ON [Parser].[TSqlSequence]([Name] ASC);

