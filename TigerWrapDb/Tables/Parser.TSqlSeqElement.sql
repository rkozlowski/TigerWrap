CREATE TABLE [Parser].[TSqlSeqElement] (
    [Id]              INT            NOT NULL,
    [TypeId]          TINYINT        NOT NULL,
    [SequenceId]      SMALLINT       NOT NULL,
    [IsStartElement]  BIT            CONSTRAINT [DF_Parser_TSqlSeqElement_IsStartElement] DEFAULT ((0)) NOT NULL,
    [NextElementId]   INT            NULL,
    [AltElementId]    INT            NULL,
    [KeywordId]       SMALLINT       NULL,
    [OperatorId]      TINYINT        NULL,
    [SequenceTypeId]  TINYINT        NULL,
    [StatementPartId] TINYINT        NULL,
    [TokenTypeId]     TINYINT        NULL,
    [TokenSubtypeId]  TINYINT        NULL,
    [StatementTypeId] SMALLINT       NULL,
    [StringValue]     NVARCHAR (200) NULL,
    [IntValue]        BIGINT         NULL,
    CONSTRAINT [PK_Parser_TSqlSeqElement] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Parser_TSqlSeqElement_Operator] FOREIGN KEY ([OperatorId]) REFERENCES [Parser].[Operator] ([Id]),
    CONSTRAINT [FK_Parser_TSqlSeqElement_TSqlKeyword] FOREIGN KEY ([KeywordId]) REFERENCES [ParserEnum].[TSqlKeyword] ([Id]),
    CONSTRAINT [FK_Parser_TSqlSeqElement_TSqlSeqElementType] FOREIGN KEY ([TypeId]) REFERENCES [ParserEnum].[TSqlSeqElementType] ([Id]),
    CONSTRAINT [FK_Parser_TSqlSeqElement_TSqlSequence] FOREIGN KEY ([SequenceId]) REFERENCES [Parser].[TSqlSequence] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [IX_Parser_TSqlSeqElement_SequenceId_IsStartElement]
    ON [Parser].[TSqlSeqElement]([SequenceId] ASC, [IsStartElement] ASC);

