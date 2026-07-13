# Repository Guidelines

## Project Structure & Module Organization

TigerWrap is a Visual Studio/.NET solution for a SQL Server code-generation tool. The main solution file is `TigerWrap.sln`.

- `ItTiger.TigerWrap.Core/` contains reusable C# library code for database access, validation, models, and generated toolkit helpers.
- `ItTiger.TigerWrap.Cli/` contains the `tiger-wrap` command-line app built on the TigerCli framework (`ItTiger.TigerCli`), with TigerQuery (`ItTiger.TigerQuery.*`) for connections and script execution.
- `ItTiger.TigerWrap.Tests/` contains the xUnit v3 test project, including live SQL Server tests marked `Category=RequiresSqlServer` that skip when no local server is available.
- `TigerWrapDb/` is the SSDT SQL Server database project. SQL objects are grouped by type, such as `Tables/`, `Stored Procedures/`, `Functions/`, `Security/`, and deployment scripts.
- `ItTiger.TigerWrap.Installer/` contains installer project files and Inno Setup scripts.
- `docs/` holds user documentation and image assets.

## Build, Test, and Development Commands

- `dotnet build ItTiger.TigerWrap.Cli/ItTiger.TigerWrap.Cli.csproj` builds the CLI (and Core). The SQL database project does not build with `dotnet build`; use Visual Studio MSBuild against `TigerWrapDb/TigerWrapDb.sqlproj` to validate SQL changes.
- `dotnet test ItTiger.TigerWrap.Tests/ItTiger.TigerWrap.Tests.csproj` runs the tests.
- `dotnet run --project ItTiger.TigerWrap.Cli -- --help` runs the CLI help locally.
- `dotnet build ItTiger.TigerWrap.Installer -c Release` builds the installer project and runs `BuildInstaller.ps1` in Release.

## Coding Style & Naming Conventions

C# projects use `net10.0`, nullable references, and implicit usings where enabled. Use four-space indentation, file-scoped or block namespaces consistently with nearby files, PascalCase for public types and members, camelCase for locals and parameters, and `Async` suffixes for asynchronous methods. Keep command classes grouped under `Commands/` by feature area.

SQL files follow the existing `Schema.Object.sql` naming pattern, for example `Toolkit.GetProjects.sql` or `dbo.Project.sql`. Place new SQL objects under the matching object-type folder and schema.

## Testing Guidelines

Add tests to `ItTiger.TigerWrap.Tests`. Prefer focused unit tests for parsing, naming, and generation rules; app-level command/registration tests use `TigerCliAppTestHost`. Tests that need a SQL Server must carry `[Trait("Category", "RequiresSqlServer")]`, provision disposable databases, and skip themselves when the local server is unavailable. Name tests after the behavior under test, for example `GenerateCode_IncludesMappedEnums`.

## Commit & Pull Request Guidelines

The current history uses short, direct commit subjects such as `Update README.md` and `Import of the 0.9 version`. Keep commits concise and action-oriented. Pull requests should include a summary, validation steps, linked issues when available, and screenshots or command output for CLI/user-facing changes. Note database deployment or migration impacts explicitly.

## Security & Configuration Tips

Do not commit real connection strings, credentials, generated local settings, or installer secrets. Treat database deployment scripts as release artifacts: review schema, static data, and version changes together.
