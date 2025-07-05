CREATE TABLE [Enum].[TemplateType] (
    [Id]   TINYINT      NOT NULL,
    [Name] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Enum_TemplateType] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_Enum_TemplateType_Name]
    ON [Enum].[TemplateType]([Name] ASC);

