namespace ItTiger.TigerWrap.Core
{
    public static class ExpectedDbInfo
    {
        public const string DbName = "TigerWrapDb";

        // API level 2: description attribute support (new ProjectEnum/Project columns and
        // stored procedure parameters). The generated wrappers pass the new parameters, so
        // API level 1 databases are no longer usable by this tool version.
        public const byte MinApiLevel = 2;
        public const byte MaxApiLevel = 2; // adjust as you increment it

        public static bool IsApiLevelSupported(byte? apiLevel)
        {
            if (!apiLevel.HasValue) return false;
            return apiLevel.Value >= MinApiLevel && apiLevel.Value <= MaxApiLevel;
        }
    }
}
