CREATE TYPE [Internal].[EnumValue] AS TABLE (
    [Id]     INT            IDENTITY (1, 1) NOT NULL,
    [EnumId] INT            NOT NULL,
    [Name]   NVARCHAR (128) NOT NULL,
    [Value]  BIGINT         NOT NULL,
    UNIQUE NONCLUSTERED ([EnumId] ASC, [Value] ASC),
    UNIQUE NONCLUSTERED ([EnumId] ASC, [Name] ASC),
    PRIMARY KEY CLUSTERED ([Id] ASC));

