using System.Text.Json;
using ItTiger.TigerQuery.Core;
using ItTiger.TigerWrap.Core;

namespace ItTiger.TigerWrap.Tests;

public sealed class ConnectionCompatibilityTests
{
    [Fact]
    public void DefaultStoreOptions_UseTigerWrapAppSpecificPath()
    {
        var options = ToolkitHelper.CreateDefaultConnectionStoreOptions();

        Assert.EndsWith(
            Path.Combine("ItTiger.net", "TigerWrap", "connections.json"),
            options.FilePath);
    }

    [Fact]
    public void CreateConnectionStore_CanEnsureStoreAndLogDirectories()
    {
        var directory = CreateTempDirectory();
        var filePath = Path.Combine(directory, "nested", "connections.json");

        _ = ToolkitHelper.CreateConnectionStore(
            new SqlServerConnectionStoreOptions { FilePath = filePath },
            new NoOpConnectionPasswordProtector(),
            ensureDirectories: true);

        Assert.True(Directory.Exists(Path.GetDirectoryName(filePath)));
        Assert.True(Directory.Exists(Path.Combine(Path.GetDirectoryName(filePath)!, "logs")));
    }

    [Fact]
    public void ExistingTigerWrapConnectionJson_LoadsThroughTigerQueryStore()
    {
        var filePath = CreateTempConnectionFile("""
        [
          {
            "Name": "local",
            "Server": ".",
            "Database": "TigerWrapDb",
            "Authentication": 1,
            "Username": "sa",
            "EncryptedPassword": "dpapi-ciphertext",
            "PasswordEncryption": 1,
            "Encrypt": 2,
            "TrustServerCertificate": true
          }
        ]
        """);
        var store = CreateStore(filePath);

        var connection = Assert.Single(store.Load());

        Assert.Equal("local", connection.Name);
        Assert.Equal(".", connection.Server);
        Assert.Equal("TigerWrapDb", connection.Database);
        Assert.Equal(AuthenticationType.SqlPassword, connection.Authentication);
        Assert.Equal("sa", connection.Username);
        Assert.Equal("dpapi-ciphertext", connection.EncryptedPassword);
        Assert.Equal(PasswordEncryptionType.DPAPI, connection.PasswordEncryption);
        Assert.Equal(EncryptOption.Strict, connection.Encrypt);
        Assert.True(connection.TrustServerCertificate);
    }

    [Fact]
    public void AddOrUpdateConnection_WritesTigerWrapCompatibleJsonShape()
    {
        var filePath = Path.Combine(CreateTempDirectory(), "connections.json");
        var store = CreateStore(filePath);

        store.AddOrUpdate(new SqlServerConnectionProfile
        {
            Name = "local",
            Server = ".",
            Database = "TigerWrapDb",
            Authentication = AuthenticationType.SqlPassword,
            Username = "sa",
            EncryptedPassword = "dpapi-ciphertext",
            PasswordEncryption = PasswordEncryptionType.DPAPI,
            Encrypt = EncryptOption.Mandatory,
            TrustServerCertificate = true
        });

        using var document = JsonDocument.Parse(File.ReadAllText(filePath));
        var root = document.RootElement[0];

        Assert.Equal("local", root.GetProperty("Name").GetString());
        Assert.Equal(".", root.GetProperty("Server").GetString());
        Assert.Equal("TigerWrapDb", root.GetProperty("Database").GetString());
        Assert.Equal(1, root.GetProperty("Authentication").GetInt32());
        Assert.Equal("sa", root.GetProperty("Username").GetString());
        Assert.Equal("dpapi-ciphertext", root.GetProperty("EncryptedPassword").GetString());
        Assert.Equal(1, root.GetProperty("PasswordEncryption").GetInt32());
        Assert.Equal(1, root.GetProperty("Encrypt").GetInt32());
        Assert.True(root.GetProperty("TrustServerCertificate").GetBoolean());
        Assert.False(root.TryGetProperty("PlainPassword", out _));
    }

    [Fact]
    public void ResolveConnection_UsesTigerQueryResolver()
    {
        var filePath = CreateTempConnectionFile("""
        [
          {
            "Name": "local",
            "Server": ".",
            "Database": "TigerWrapDb",
            "Authentication": 0,
            "Username": null,
            "EncryptedPassword": null,
            "PasswordEncryption": 0,
            "Encrypt": 0,
            "TrustServerCertificate": false
          }
        ]
        """);
        var store = CreateStore(filePath);

        var resolution = SqlServerConnectionResolver.Resolve(store, "local");

        Assert.True(resolution.IsSuccess);
        Assert.Contains("Data Source=.", resolution.ConnectionString);
        Assert.Contains("Initial Catalog=TigerWrapDb", resolution.ConnectionString);
        Assert.Contains("Integrated Security=True", resolution.ConnectionString);
    }

    private static SqlServerConnectionStore CreateStore(string filePath)
    {
        return ToolkitHelper.CreateConnectionStore(
            new SqlServerConnectionStoreOptions { FilePath = filePath },
            new NoOpConnectionPasswordProtector());
    }

    private static string CreateTempConnectionFile(string contents)
    {
        var filePath = Path.Combine(CreateTempDirectory(), "connections.json");
        File.WriteAllText(filePath, contents);
        return filePath;
    }

    private static string CreateTempDirectory()
    {
        var directory = Path.Combine(Path.GetTempPath(), "TigerWrap.Tests", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(directory);
        return directory;
    }
}
