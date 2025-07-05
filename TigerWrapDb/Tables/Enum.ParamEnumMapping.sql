CREATE TABLE [Enum].[ParamEnumMapping] (
    [Id]   TINYINT       NOT NULL,
    [Name] VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_Enum_ParamEnumMapping] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_Enum_ParamEnumMapping_Name]
    ON [Enum].[ParamEnumMapping]([Name] ASC);

