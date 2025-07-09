using System.IO;
using System.Text.Json;
using System.Security.Cryptography;
using System.Text;
using ItTiger.TigerWrap.Core.Models;

namespace ItTiger.TigerWrap.Core.Services;

public class ConnectionService
{
    private static readonly JsonSerializerOptions JsonOptions = new() { WriteIndented = true };

    private readonly string _configPath;

    public ConnectionService()
    {
        var folder = Environment.OSVersion.Platform == PlatformID.Win32NT
            ? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "ItTiger.net", "TigerWrap")
            : Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".config", "ItTiger.net", "TigerWrap");

        Directory.CreateDirectory(folder);
        _configPath = Path.Combine(folder, "connections.json");
        var logDir = Path.Combine(folder, "logs");
        Directory.CreateDirectory(logDir);
    }

    public List<ConnectionInfo> LoadConnections()
    {
        if (!File.Exists(_configPath))
            return [];

        var json = File.ReadAllText(_configPath);
        var list = JsonSerializer.Deserialize<List<ConnectionInfo>>(json) ?? [];

        // Decrypt passwords
        foreach (var c in list)
        {
            if (c.PasswordEncryption == PasswordEncryptionType.DPAPI && !string.IsNullOrEmpty(c.EncryptedPassword))
            {
                c.PlainPassword = DecryptDPAPI(c.EncryptedPassword);
            }
        }

        return list;
    }

    public void AddOrUpdateConnection(ConnectionInfo info)
    {
        var connections = LoadConnections();
        connections.RemoveAll(c => c.Name == info.Name);

        if (!string.IsNullOrEmpty(info.PlainPassword))
        {
            info.EncryptedPassword = EncryptDPAPI(info.PlainPassword);
            info.PasswordEncryption = PasswordEncryptionType.DPAPI;
        }

        connections.Add(info);
        File.WriteAllText(_configPath, JsonSerializer.Serialize(connections, JsonOptions));
    }

    public bool DeleteConnection(string name)
    {
        var connections = LoadConnections();
        var removed = connections.RemoveAll(c => c.Name == name) > 0;
        if (removed)
        {
            File.WriteAllText(_configPath, JsonSerializer.Serialize(connections, JsonOptions));
        }
        return removed;
    }

    private static string EncryptDPAPI(string plain)
    {
        if (!OperatingSystem.IsWindows())
        {
            throw new PlatformNotSupportedException("DPAPI encryption is only supported on Windows.");
        }

        var bytes = Encoding.UTF8.GetBytes(plain);
        var protectedBytes = ProtectedData.Protect(bytes, null, DataProtectionScope.CurrentUser);
        return Convert.ToBase64String(protectedBytes);
    }

    private static string DecryptDPAPI(string encrypted)
    {
        if (!OperatingSystem.IsWindows())
        {
            throw new PlatformNotSupportedException("DPAPI encryption is only supported on Windows.");
        }

        try
        {
            var protectedBytes = Convert.FromBase64String(encrypted);
            var bytes = ProtectedData.Unprotect(protectedBytes, null, DataProtectionScope.CurrentUser);
            return Encoding.UTF8.GetString(bytes);
        }
        catch
        {
            return string.Empty;
        }
    }
}
