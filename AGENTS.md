# Repository Guidelines

## Project Structure & Module Organization

TigerWrap is a Visual Studio/.NET solution for a SQL Server code-generation tool. The main solution file is `TigerWrap.sln`.

- `ItTiger.TigerWrap.Core/` contains reusable C# library code for database access, validation, models, and generated toolkit helpers.
- `ItTiger.TigerWrap.Cli/` contains the `tiger-wrap` command-line app, Spectre.Console commands, resources, logging config, and CLI helpers.
- `TigerWrapDb/` is the SSDT SQL Server database project. SQL objects are grouped by type, such as `Tables/`, `Stored Procedures/`, `Functions/`, `Security/`, and deployment scripts.
- `ItTiger.TigerWrap.Installer/` contains installer project files and Inno Setup scripts.
- `docs/` holds user documentation and image assets.

## Build, Test, and Development Commands

- `dotnet build TigerWrap.sln` builds the solution. The SQL database project requires SSDT/Visual Studio SQL tooling.
- `dotnet build ItTiger.TigerWrap.Cli/ItTiger.TigerWrap.Cli.csproj` builds only the CLI.
- `dotnet run --project ItTiger.TigerWrap.Cli -- --help` runs the CLI help locally.
- `dotnet build ItTiger.TigerWrap.Installer -c Release` builds the installer project and runs `BuildInstaller.ps1` in Release.

There is no dedicated test project in the current tree. Use build validation and targeted CLI/database checks when changing behavior.

## Coding Style & Naming Conventions

C# projects use `net10.0`, nullable references, and implicit usings where enabled. Use four-space indentation, file-scoped or block namespaces consistently with nearby files, PascalCase for public types and members, camelCase for locals and parameters, and `Async` suffixes for asynchronous methods. Keep command classes grouped under `Commands/` by feature area.

SQL files follow the existing `Schema.Object.sql` naming pattern, for example `Toolkit.GetProjects.sql` or `dbo.Project.sql`. Place new SQL objects under the matching object-type folder and schema.

## Testing Guidelines

When adding tests, create a separate test project with a clear name such as `ItTiger.TigerWrap.Core.Tests`. Prefer focused unit tests for parsing, naming, and generation rules, and integration tests only when a SQL Server dependency is explicit and documented. Name tests after the behavior under test, for example `GenerateCode_IncludesMappedEnums`.

## Commit & Pull Request Guidelines

The current history uses short, direct commit subjects such as `Update README.md` and `Import of the 0.9 version`. Keep commits concise and action-oriented. Pull requests should include a summary, validation steps, linked issues when available, and screenshots or command output for CLI/user-facing changes. Note database deployment or migration impacts explicitly.

## Security & Configuration Tips

Do not commit real connection strings, credentials, generated local settings, or installer secrets. Treat database deployment scripts as release artifacts: review schema, static data, and version changes together.
