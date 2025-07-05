namespace ItTiger.TigerWrap.Core
{
    public static class DbInfoValidator
    {
        public static async Task ValidateAsync(ToolkitDbHelper db)
        {
            var (_, dbName, _, apiLevel, minApiLevel) = await db.GetDbInfoAsync();

            if (!string.Equals(dbName, ExpectedDbInfo.DbName, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException($"Connected database is '{dbName}', expected '{ExpectedDbInfo.DbName}'.");

            if (!ExpectedDbInfo.IsApiLevelSupported(apiLevel))
                throw new InvalidOperationException($"Database API level '{apiLevel}' is not supported by this version of the tool. Expected: {ExpectedDbInfo.MinApiLevel}-{ExpectedDbInfo.MaxApiLevel}.");

            // Optionally: check minApiLevel too if relevant.
        }
    }
}
