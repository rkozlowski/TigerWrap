CREATE TABLE [Parser].[CharTypeMap] (
    [Id]     INT       IDENTITY (1, 1) NOT NULL,
    [Char]   NCHAR (1) COLLATE Latin1_General_BIN NOT NULL,
    [TypeId] TINYINT   NOT NULL,
    CONSTRAINT [PK_Parser_CharTypeMap] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Parser_CharTypeMap_CharType] FOREIGN KEY ([TypeId]) REFERENCES [ParserEnum].[CharType] ([Id])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_Parser_CharTypeMap_TypeId_Char]
    ON [Parser].[CharTypeMap]([TypeId] ASC, [Char] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_Parser_CharTypeMap_Char]
    ON [Parser].[CharTypeMap]([Char] ASC);

