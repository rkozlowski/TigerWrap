CREATE TABLE [dbo].[SchemaVersion] (
    [Id]          SMALLINT       IDENTITY (1, 1) NOT NULL,
    [Version]     VARCHAR (50)   NOT NULL,
    [Description] NVARCHAR (500) NOT NULL,
    [AppliedOn]   DATETIME2 (2)  CONSTRAINT [DF_SchemaVersion_AppliedOn] DEFAULT (sysutcdatetime()) NOT NULL,
    [AppliedBy]   NVARCHAR (128) CONSTRAINT [DF_SchemaVersion_AppliedBy] DEFAULT (original_login()) NOT NULL,
    [ApiLevel]    SMALLINT       CONSTRAINT [DF_SchemaVersion_ApiLevel] DEFAULT ((0)) NOT NULL,
    [MinApiLevel] TINYINT        CONSTRAINT [DF_SchemaVersion_MinApiLevel] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_SchemaVersion] PRIMARY KEY CLUSTERED ([Id] ASC)
);




GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SchemaVersion_Version]
    ON [dbo].[SchemaVersion]([Version] ASC);

