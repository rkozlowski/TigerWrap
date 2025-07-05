using ItTiger.TigerWrap.Core;
using ItTiger.TigerWrap.Core.Services;
using Microsoft.Data.SqlClient;
using System;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;

namespace ItTiger.TigerWrap.Core
{
    public static class ToolkitHelper
    {
        /// <summary>
        /// Resolves a connection by name, creates a ToolkitDbHelper, and validates it.
        /// Returns null and an error message if any step fails.
        /// </summary>
        public static async Task<(ToolkitDbHelper? db, string? error)> TryResolveDbHelperAsync(
            ConnectionService connectionService,
            string connectionName)
        {
            var info = connectionService.LoadConnections().FirstOrDefault(c => c.Name == connectionName);
            if (info == null)
            {
                return (null, $"Connection named '{connectionName}' not found.");
            }

            var db = new ToolkitDbHelper(info.BuildConnectionString());

            try
            {
                await DbInfoValidator.ValidateAsync(db);
                return (db, null);
            }
            catch (Exception ex)
            {
                return (null, $"Failed to validate DB connection: {ex.Message}");
            }
        }

        /// <summary>
        /// Returns the language ID for the given code (case-insensitive), or null if not found.
        /// </summary>
        public static async Task<byte?> GetLanguageIdByCodeAsync(ToolkitDbHelper db, string languageCode)
        {
            if (string.IsNullOrWhiteSpace(languageCode))
                return null;

            var languages = await db.GetLanguagesAsync();
            var match = languages.FirstOrDefault(l =>
                l.Code != null &&
                l.Code.Equals(languageCode, StringComparison.OrdinalIgnoreCase));
            return (byte?)(match?.Id);
        }

        /// <summary>
        /// Returns the language ID for the given name (case-insensitive), or null if not found.
        /// </summary>
        public static async Task<byte?> GetLanguageIdByNameAsync(ToolkitDbHelper db, string languageName)
        {
            if (string.IsNullOrWhiteSpace(languageName))
                return null;

            var languages = await db.GetLanguagesAsync();
            var match = languages.FirstOrDefault(l =>
                l.Name != null &&
                l.Name.Equals(languageName, StringComparison.OrdinalIgnoreCase));
            return (byte?)(match?.Id);
        }

        public static async Task<(string hex, string names)> GetLanguageOptionsSummaryAsync(
            ToolkitDbHelper db,
            ToolkitDbHelper.Language? languageId,
            long? optionsValue,
            string separator = ", "
        )
        {
            if (!optionsValue.HasValue)
            {
                return ("", "");
            }

            var allFlags = await db.GetLanguageOptionsAsync(languageId);
            var value = optionsValue.Value;

            var enabledFlags = allFlags
                .Where(f => (f.Value & value) == f.Value)
                .OrderBy(f => f.Value)
                .Select(f => f.Name)                
                .ToList();

            var hex = $"0x{value:X16}";
            var names = enabledFlags.Count > 0 ? string.Join(separator, enabledFlags) : "";

            return (hex, names);
        }

        public static async Task<long?> ResolveLanguageOptionsAsync(
        ToolkitDbHelper db,
        ToolkitDbHelper.Language? languageId,
        string? options)
        {
            if (string.IsNullOrWhiteSpace(options))
            {
                return null;
            }

            options = options.Trim();

            if (options.StartsWith("0x", StringComparison.OrdinalIgnoreCase))
            {
                // Hexadecimal format
                if (long.TryParse(options.AsSpan(2), NumberStyles.HexNumber, CultureInfo.InvariantCulture, out long hexVal))
                {
                    return hexVal;
                }
                else
                {
                    throw new ArgumentException($"Invalid hexadecimal value: '{options}'");
                }
            }

            // Assume comma-separated list of flag names
            var optionList = options
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .ToList();

            if (optionList.Count == 0)
            {
                return null;
            }

            var allFlags = await db.GetLanguageOptionsAsync(languageId);
            long value = 0;
            foreach (var flag in optionList)
            {
                var match = allFlags.FirstOrDefault(f => string.Equals(f.Name, flag, StringComparison.OrdinalIgnoreCase)) ?? throw new ArgumentException($"Unknown language option: '{flag}'");
                value |= match.Value;
            }

            return value;
        }

        public static string GetEnumValuesDescription<T>() where T : Enum
        {
            return string.Join(" | ", Enum.GetNames(typeof(T)));
        }

        public static async Task<IList<string>> GetSchemasAsync(string connectionString)
        {
            var schemas = new List<string>();

            await using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync();

            using var cmd = connection.CreateCommand();
            cmd.CommandText = "SELECT [name] FROM sys.schemas ORDER BY [name]";

            using var reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                schemas.Add(reader.GetString(0));
            }

            return schemas;
        }

    }



}


