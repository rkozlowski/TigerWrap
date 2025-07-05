CREATE TABLE [Static].[DataTypeMap] (
    [Id]              SMALLINT       IDENTITY (1, 1) NOT NULL,
    [LanguageId]      TINYINT        NOT NULL,
    [SqlType]         NVARCHAR (128) NOT NULL,
    [NativeType]      VARCHAR (200)  NOT NULL,
    [SqlDbType]       VARCHAR (200)  NULL,
    [DbType]          VARCHAR (200)  NULL,
    [IsNullable]      BIT            CONSTRAINT [DF_DataTypeMap_IsNullable] DEFAULT ((1)) NOT NULL,
    [SizeNeeded]      BIT            CONSTRAINT [DF_DataTypeMap_SizeNeeded] DEFAULT ((0)) NOT NULL,
    [PrecisionNeeded] BIT            CONSTRAINT [DF_DataTypeMap_PrecisionNeeded] DEFAULT ((0)) NOT NULL,
    [ScaleNeeded]     BIT            CONSTRAINT [DF_DataTypeMap_ScaleNeeded] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_DataTypeMap] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_DataTypeMap_Language] FOREIGN KEY ([LanguageId]) REFERENCES [Enum].[Language] ([Id])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_DataTypeMap_LanguageId_SqlType]
    ON [Static].[DataTypeMap]([LanguageId] ASC, [SqlType] ASC);

