using System.Reflection;

namespace ItTiger.TigerWrap.Core;

public static class ProjectInfo
{
    public static string Version =>
        Assembly.GetExecutingAssembly()
                .GetCustomAttribute<AssemblyInformationalVersionAttribute>()?
                .InformationalVersion ?? "unknown";

    public static string AssemblyVersion =>
        Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "unknown";

    public const string Name = "TigerWrap";

    public const string WebsiteUrl = "https://www.ittiger.net/projects/tigerwrap/";
    public const string GitHubUrl = "https://github.com/rkozlowski/TigerWrap/";
    public const string Copyright = "Copyright (c) IT Tiger";
}
