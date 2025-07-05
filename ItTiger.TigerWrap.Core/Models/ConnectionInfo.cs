using Microsoft.Data.SqlClient;
using System.Text.Json.Serialization;

namespace ItTiger.TigerWrap.Core.Models;

public class ConnectionInfo
{
    public string Name { get; set; } = string.Empty;
    public string Server { get; set; } = string.Empty;
    public string Database { get; set; } = string.Empty;

    public AuthenticationType Authentication { get; set; }
    public string? Username { get; set; }
    public string? EncryptedPassword { get; set; }
    public PasswordEncryptionType PasswordEncryption { get; set; } = PasswordEncryptionType.NotApplicable;

    public EncryptOption Encrypt { get; set; }
    public bool TrustServerCertificate { get; set; }

    // This property is never serialized; used at runtime
    [JsonIgnore]
    public string? PlainPassword { get; set; }
    
    
    public string BuildConnectionString()
    {
        var builder = new SqlConnectionStringBuilder
        {
            DataSource = Server,
            InitialCatalog = Database ?? "master",
            IntegratedSecurity = Authentication == AuthenticationType.Integrated,
            TrustServerCertificate = TrustServerCertificate
        };

        switch (Encrypt)
        {
            case EncryptOption.Mandatory:
            case EncryptOption.Strict:
                builder.Encrypt = true;
                break;
            case EncryptOption.Optional:
                builder.Encrypt = false;
                break;
        }

        if (Authentication == AuthenticationType.SqlPassword)
        {
            builder.UserID = Username;
            builder.Password = PlainPassword;
        }

        return builder.ConnectionString;
    }
}
