CREATE TABLE [dbo].[Project] (
    [Id]                 SMALLINT       IDENTITY (1, 1) NOT NULL,
    [Name]               NVARCHAR (200) NOT NULL,
    [NamespaceName]      VARCHAR (100)  NOT NULL,
    [ClassName]          VARCHAR (100)  NOT NULL,
    [ClassAccessId]      TINYINT        NOT NULL,
    [LanguageId]         TINYINT        NOT NULL,
    [LanguageOptions]    BIGINT         CONSTRAINT [DF_Project_LanguageOptions] DEFAULT ((0)) NOT NULL,
    [ParamEnumMappingId] TINYINT        CONSTRAINT [DF_Project_ParamEnumMapping] DEFAULT ((1)) NOT NULL,
    [MapResultSetEnums]  BIT            CONSTRAINT [DF_Project_MapResultSetEnums] DEFAULT ((0)) NOT NULL,
    [DefaultDatabase]    NVARCHAR (128) NULL,
    CONSTRAINT [PK_Project] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Project_ClassAccess] FOREIGN KEY ([ClassAccessId]) REFERENCES [Enum].[ClassAccess] ([Id]),
    CONSTRAINT [FK_Project_Language] FOREIGN KEY ([LanguageId]) REFERENCES [Enum].[Language] ([Id]),
    CONSTRAINT [FK_Project_ParamEnumMapping] FOREIGN KEY ([ParamEnumMappingId]) REFERENCES [Enum].[ParamEnumMapping] ([Id])
);








GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_Project_Name]
    ON [dbo].[Project]([Name] ASC);

