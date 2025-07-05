CREATE TABLE [Enum].[Language] (
    [Id]       TINYINT       NOT NULL,
    [Name]     VARCHAR (200) NOT NULL,
    [Code]     VARCHAR (50)  NOT NULL,
    [StatusId] TINYINT       CONSTRAINT [DF_Language_StatusId] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_Enum_Language] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Language_Status] FOREIGN KEY ([StatusId]) REFERENCES [Enum].[Status] ([Id])
);




GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_Enum_Language_Name]
    ON [Enum].[Language]([Name] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_Enum_Language_Code]
    ON [Enum].[Language]([Code] ASC);

