using ItTiger.TigerCli.Enums;
using ItTiger.TigerCli.Terminal;
using ItTiger.TigerWrap.Cli.Commands;

namespace ItTiger.TigerWrap.Tests;

// Redirects Console.Out and mutates TigerConsole state; must not run in
// parallel with other tests that write console output.
[Collection("TigerCli app tests")]
public sealed class GenerateCodeCommandTests
{
    [Theory]
    [InlineData(0, "0 B")]
    [InlineData(512, "512 B")]
    [InlineData(1024, "1.00 KiB")]
    [InlineData(1536, "1.50 KiB")]
    [InlineData(1048576, "1.00 MiB")]
    public void FormatByteSize_UsesBinaryUnits(long bytes, string expected)
    {
        Assert.Equal(expected, GenerateCodeCommand.FormatByteSize(bytes));
    }

    [Fact]
    public void CreateWrittenFilesList_UsesExpectedColumnsAndFilenameOnlyRows()
    {
        var rows = new[]
        {
            new GenerateCodeCommand.GeneratedFileSummary("ToolkitDbHelper.Enum.Enums.cs", 123, 4311),
            new GenerateCodeCommand.GeneratedFileSummary("ToolkitDbHelper.Toolkit.ResultTypes.cs", 456, 19179)
        };

        var table = GenerateCodeCommand.CreateWrittenFilesList(rows, new GenerateCodeCommand.Settings());

        Assert.Equal("File name", table.Header.Elements[0].HeaderContent);
        Assert.Equal("Lines", table.Header.Elements[1].HeaderContent);
        Assert.Equal("Size", table.Header.Elements[2].HeaderContent);
        Assert.Equal(CliTextAlignment.Left, table.Title?.Style.HorizontalAlignment);
        Assert.Equal(CliTextAlignment.Right, table.Header.Elements[1].DataStyle?.HorizontalAlignment);
        Assert.Equal(CliTextAlignment.Right, table.Header.Elements[2].DataStyle?.HorizontalAlignment);
        Assert.All(table.Records, record =>
        {
            var fileName = Assert.IsType<string>(record[0]);
            Assert.False(Path.IsPathFullyQualified(fileName));
            Assert.DoesNotContain(Path.DirectorySeparatorChar, fileName);
        });
    }

    [Fact]
    public void CreateWrittenFilesList_RendersSingleFileWithSameListLayout()
    {
        var table = GenerateCodeCommand.CreateWrittenFilesList(
            [new GenerateCodeCommand.GeneratedFileSummary("ToolkitDbHelper.cs", 3, 1536)],
            new GenerateCodeCommand.Settings());

        var output = string.Join(Environment.NewLine, TigerConsole.RenderToLines(table));

        Assert.Contains("Files written:", output);
        Assert.Contains("File name", output);
        Assert.Contains("Lines", output);
        Assert.Contains("Size", output);
        Assert.Contains("ToolkitDbHelper.cs", output);
        Assert.Contains("1.50 KiB", output);
    }

    [Fact]
    public async Task WriteGeneratedFileAsync_PreservesGeneratedContentAndMeasuresFinalFile()
    {
        var directory = CreateTempDirectory();
        var file = Path.Combine(directory, "Generated.cs");
        var content = "line one" + Environment.NewLine + "line two";

        var summary = await GenerateCodeCommand.WriteGeneratedFileAsync(file, content);

        Assert.Equal(content, await File.ReadAllTextAsync(file, TestContext.Current.CancellationToken));
        Assert.Equal("Generated.cs", summary.FileName);
        Assert.Equal(2, summary.Lines);
        Assert.Equal(new FileInfo(file).Length, summary.Bytes);
    }

    [Fact]
    public void RenderWrittenFilesSummary_WithNoFiles_PrintsClearMessageOnly()
    {
        var originalOut = Console.Out;
        var originalColorMode = TigerConsole.ColorMode;
        using var output = new StringWriter();

        try
        {
            TigerConsole.ColorMode = CliColorMode.Never;
            Console.SetOut(output);

            GenerateCodeCommand.RenderWrittenFilesSummary([], new GenerateCodeCommand.Settings());
        }
        finally
        {
            Console.SetOut(originalOut);
            TigerConsole.ColorMode = originalColorMode;
        }

        var text = output.ToString();
        Assert.Contains("No files written.", text);
        Assert.DoesNotContain("File name", text);
    }

    [Fact]
    public void FormatOutputFolder_AddsDirectorySeparatorOnce()
    {
        var directory = CreateTempDirectory();

        var formatted = GenerateCodeCommand.FormatOutputFolder(directory);

        Assert.EndsWith(Path.DirectorySeparatorChar.ToString(), formatted);
        Assert.False(formatted.EndsWith(new string(Path.DirectorySeparatorChar, 2), StringComparison.Ordinal));
    }

    private static string CreateTempDirectory()
    {
        var directory = Path.Combine(Path.GetTempPath(), "TigerWrap.Tests", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(directory);
        return directory;
    }
}
