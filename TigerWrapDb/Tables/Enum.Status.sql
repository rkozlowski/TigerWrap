CREATE TABLE [Enum].[Status] (
    [Id]   TINYINT      NOT NULL,
    [Name] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Enum_Status] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_Enum_Status_Name] UNIQUE NONCLUSTERED ([Name] ASC)
);

