CREATE TABLE [Enum].[LoggingLevel] (
    [Id]   TINYINT      NOT NULL,
    [Code] CHAR (1)     NOT NULL,
    [Name] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Enum_LoggingLevel] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_Enum_LoggingLevel_Code] UNIQUE NONCLUSTERED ([Code] ASC),
    CONSTRAINT [UQ_Enum_LoggingLevel_Name] UNIQUE NONCLUSTERED ([Name] ASC)
);

