namespace ItTiger.TigerWrap.Tests;

public sealed class SmokeTests
{
    [Fact]
    public void CoreMetadata_IsLoadable()
    {
        Assert.Equal("TigerWrap", ItTiger.TigerWrap.Core.ProjectInfo.Name);
        Assert.Equal("TigerWrapDb", ItTiger.TigerWrap.Core.ExpectedDbInfo.DbName);
        Assert.True(ItTiger.TigerWrap.Core.ExpectedDbInfo.IsApiLevelSupported(
            ItTiger.TigerWrap.Core.ExpectedDbInfo.MinApiLevel));
    }

    [Fact]
    public void CliTypes_AreLoadable()
    {
        var cliAssembly = typeof(ItTiger.TigerWrap.Cli.TigerWrapApp).Assembly;

        Assert.Equal("tiger-wrap", cliAssembly.GetName().Name);
        Assert.NotNull(cliAssembly.GetType("ItTiger.TigerWrap.Cli.TigerWrapApp", throwOnError: false));
    }
}
