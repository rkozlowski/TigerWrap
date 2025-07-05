CREATE TABLE [Parser].[Operator] (
    [Id]       TINYINT       NOT NULL,
    [Name]     VARCHAR (50)  NOT NULL,
    [Operator] NVARCHAR (10) NOT NULL,
    [Unary]    BIT           CONSTRAINT [DF_Operator_Unary] DEFAULT ((0)) NOT NULL,
    [Binary]   BIT           CONSTRAINT [DF_Operator_Binary] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Parser_Operator] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_Parser_Operator_Name]
    ON [Parser].[Operator]([Name] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_Parser_Operator_Operator]
    ON [Parser].[Operator]([Operator] ASC);

