using System.ComponentModel;

namespace ItTiger.TigerWrap.Core;

public enum AuthenticationType
{
    [Description("Use Windows Integrated Security")]
    Integrated,

    [Description("Use SQL Username and Password")]
    SqlPassword,

    [Description("Use Entra ID (future)")]
    Entra
}

public enum EncryptOption
{
    [Description("No encryption (default)")]
    Optional,

    [Description("Encryption required")]
    Mandatory,

    [Description("Strict encryption with certificate validation")]
    Strict
}
public enum PasswordEncryptionType
{
    NotApplicable, // e.g. Integrated auth
    DPAPI,         // Local machine/user
    Vault          // Cloud key vault in future
}

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

