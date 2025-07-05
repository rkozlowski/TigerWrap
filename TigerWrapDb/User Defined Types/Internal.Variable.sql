CREATE TYPE [Internal].[Variable] AS TABLE (
    [Id]    INT             IDENTITY (1, 1) NOT NULL,
    [Name]  NVARCHAR (128)  NOT NULL,
    [Value] NVARCHAR (4000) NULL,
    UNIQUE NONCLUSTERED ([Name] ASC),
    PRIMARY KEY CLUSTERED ([Id] ASC));

