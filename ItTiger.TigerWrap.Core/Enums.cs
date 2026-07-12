using System.ComponentModel;

namespace ItTiger.TigerWrap.Core;

public enum OutputType
{
    [Description("Write all code into a single file")]
    SingleFile,

    [Description("Write each object type to a separate file")]
    SplitPerType,

    [Description("Write each schema to a separate file")]
    SplitPerSchema,

    [Description("Write each schema/type combo to a separate file")]
    SplitPerSchemaAndType
}

public enum OverwriteMode
{
    [Description("Overwrite files without asking (default)")]
    Yes,

    [Description("Skip existing files")]
    No,

    [Description("Prompt for each file if it exists")]
    Ask
}

