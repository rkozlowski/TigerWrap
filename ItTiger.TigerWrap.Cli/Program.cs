namespace ItTiger.TigerWrap.Cli;

class Program
{
    public static async Task<int> Main(string[] args)
    {
        return await TigerWrapApp.Create().RunAsync(args);
    }
}
