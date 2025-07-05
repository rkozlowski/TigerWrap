namespace ItTiger.TigerWrap.Core
{
    public static class ExpectedDbInfo
    {
        public const string DbName = "TigerWrapDb";

        public const byte MinApiLevel = 0;
        public const byte MaxApiLevel = 1; // adjust as you increment it

        public static bool IsApiLevelSupported(byte? apiLevel)
        {
            if (!apiLevel.HasValue) return false;
            return apiLevel.Value >= MinApiLevel && apiLevel.Value <= MaxApiLevel;
        }
    }
}
