CREATE TABLE [Enum].[ToolkitResponseCode] (
    [Id]          INT            NOT NULL,
    [Name]        VARCHAR (100)  NOT NULL,
    [Description] NVARCHAR (255) NULL,
    [IsSuccess]   BIT            CONSTRAINT [DF_ToolkitResponseCode_IsSuccess] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ToolkitResponseCode] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_ToolkitResponseCode_Name] UNIQUE NONCLUSTERED ([Name] ASC)
);

