# TigerWrap 0.9.2 — General Plan

## Release direction

TigerWrap 0.9.2 is a user-feature release focused on:

- project portability;
- TigerWrapDb lifecycle operations;
- safer installation and upgrades;
- real SQL Server-backed end-to-end testing.

The release is not justified by internal refactoring or test infrastructure alone.

Release theme:

> Install, move, recover, and upgrade TigerWrap projects and TigerWrapDb safely.

## Status

### Implemented

- **`db install`** — menu-visible; CLI preflight (emptiness and compatibility level ≥ 130), plan
  display, confirmation, prepared execution of the packaged full-install artifact with batch-level
  progress, and post-install version/API-level verification.
- **SQL-side install guard** — `TigerWrapDb/Scripts/Script.PreInstallEmptyCheck.sql`, expanded into
  `TigerWrapDb_FullDeploy_v_0.9.2.sql`. The CLI predicate (`DatabaseEmptinessCheck.ConflictQuery`)
  and the SQL guard are textually identical (`InstallGuardArtifactTests`) and classify the same
  database identically (`DbInstallLiveTests`). `BuildInstaller.ps1` fails the build if the packaged
  artifact lacks the guard.
- **Prepared execution with "batch N of M" progress** — `ScriptRunner`, shared by `db install` and
  `db upgrade` (`ExecutionMode = Prepared`, `Mode = SqlCmdEx`, `ContinueOnError = false`,
  `Variables["DatabaseName"]`, `OnExecutionPlanReady`/`OnBatchEnd`).
- **TigerWrapDb 0.9.2 schema version** — guard-only change at API level 2; `Script.Version.sql` and
  `ExpectedDbInfo.CurrentSchemaVersion` are `0.9.2`. Released 0.9.0/0.9.1 artifacts are immutable
  and guarded by `ReleasedArtifactTests`; scripts producing the version under development are
  exempt until released.
- **WinGet manifest generation** — `eng/winget/Prepare-TigerWrapWinGet.ps1` and its tests.
- **Current Tiger package baseline** — ItTiger.Core 0.9.4, TigerCli 0.9.4, TigerQuery /
  TigerQuery.Core / TigerQuery.CliCore 0.8.8, with TigerQuery's run-time store selection adopted
  (see [Foundation](#foundation)).
- **`db sqlcmd`** — script-oriented, menu-excluded SQL-file execution through TigerQuery in-process
  against a managed connection; the SQL-execution primitive for the E2E harness (see
  [`db sqlcmd`](#db-sqlcmd-implemented)).

### Remaining

- the managed-connection E2E harness on TigerQuery's E2E lifecycle (P1, settled) — **next slice**:
  replace the hard-coded `SqlServerTestDatabase` fixture;
- connection roles and role-filtered providers;
- chained upgrade (catalogue + resolver) and the capability probe;
- the response-code batch and the TigerWrapDb 0.9.2 schema changes (API level 3);
- project export and import;
- the SQL Server 2017 decision;
- release hardening.

## Foundation

### Package baseline and what the upgrade changed

TigerWrap references ItTiger.Core 0.9.4, ItTiger.TigerCli 0.9.4, and ItTiger.TigerQuery,
.Core, and .CliCore 0.8.8. TigerQuery is consumed as a library; the `tiger-sqlcmd` executable,
dotnet tool, and WinGet package are not TigerWrap runtime or test prerequisites.

Consequences already absorbed into TigerWrap:

- **Store selection moved to run time.** `SqlServerConnectionCommandOptions.Store` no longer exists.
  `TigerWrapApp.Build` creates one `TigerQueryCliOptions` (default file =
  `SqlServerConnectionStoreOptions.AppSpecific("ItTiger.net", "TigerWrap")`), registers
  `TigerQueryCliContribution`, and gives the same instance to the `connection` group, providers, and
  command factories, which read `TigerQueryCliOptions.Store` at run time. Resolution order is
  `--tq-connection-store-file`, then `TIGERQUERY_CONNECTION_STORE_FILE`, then the TigerWrap default
  file; a bad selected source fails the run and never falls back. Tests pin their own store file and
  an empty environment reader through `TestApps.Build`.
- **The `connection` group gained TigerQuery's E2E commands.** `SqlServerConnectionCommands.Configure`
  always mounts `add-e2e-bootstrap` and `clone-e2e` and adds `--e2e`/`--allow-database-create` to
  `add`; there is no opt-out. `connection delete` refuses profiles that own an E2E database.
- **Script failures now fail the run.** SQL errors of severity ≥ 11 delivered through `InfoMessage`
  fail the active batch in both prepared and streaming modes; `:on error exit` stops later batches;
  a run with any failed batch ends `BatchFailed` even under continue-on-error. `ScriptRunner`'s
  message-count check remains defense in depth only.

### TigerQuery capabilities available to 0.9.2 (verified at 0.8.8 source and tests)

| Capability | Library API | Notes |
| --- | --- | --- |
| Same-store profile copy | `SqlServerConnectionStore.Copy(sourceName, SqlServerConnectionCopyOptions)` | Copies the at-rest JSON (every field, `Options`, metadata, external references, DPAPI blob byte-for-byte); never decrypts, never crosses stores, never upserts; overrides only `TargetName`, `InitialCatalogOverride`, `MetadataToSet`, `MetadataToRemove`; validates without opening SQL. Keys under `ittiger.e2e.` cannot be set or removed through it and are copied verbatim. |
| Safe store mutation | `Add`, `AddOrUpdate`, `Copy`, `Delete` | In-process gate plus best-effort cross-process `<file>.lock`; temp-file + flush + atomic replace; `MutationTimeout` (15 s). Reads are unlocked; `Find` → `AddOrUpdate` is not atomic; `Save(IEnumerable)` still re-protects every profile passed in. |
| Store selection | `SqlServerConnectionStorePathResolver`, `TigerQueryCliOptions`, `TigerQueryCliContribution` | Explicit → environment → host default, no fallback; `EnvironmentReader` injectable. Option name fixed as `--tq-connection-store-file`. |
| Metadata | `SetMetadata`, `RemoveMetadata`, `QueryByMetadata` | Opaque, ordinal, case-sensitive; any non-reserved namespace (e.g. `TigerWrap:*`) is allowed. |
| E2E authorization metadata | `SqlServerE2eMetadata` | Reserved prefix `ittiger.e2e.`: `enabled`, `bootstrap`, `allow-database-create`, `session-id`, `database.name`, `database.allow-drop`; values exactly `true`/`false`; written only by TigerQuery-owned operations. |
| Bootstrap resolution | `SqlServerE2eConnectionResolver.Resolve` | Exact name plus `ittiger.e2e.enabled=true` and `bootstrap=true`; optional create permission; never probes SQL. |
| Durable E2E session lifecycle | `ItTiger.TigerQuery.E2e.SqlServerE2eSessionLifecycle(store, bootstrapName)` | `CreateAsync` (create through bootstrap, then same-store copy with ownership metadata; rolls back the database if the record cannot be persisted), `DropAsync` (exact session/database ownership, prefix grammar, `SINGLE_USER WITH ROLLBACK IMMEDIATE`, record removed only after the drop), `CleanupAsync(sessionId)`, `CloneForExistingDatabase` (non-owning). Names are fixed: database `_TQ_E2E_<part>_<32hex>`, connection `E2E-<part>-<32hex>`. No metadata overrides on the created copy. |
| In-process E2E lifecycle | `SqlServerE2eDatabaseLifecycle` | Configurable `DatabasePrefix` (default `_TQ_E2E_`); ownership held in memory; plain `DROP DATABASE` without forcing; orphan detection reports only. |
| Execution controls | `TigerQueryEngineOptions` | `ExecutionMode`, `Mode`, `Variables` (override `:setvar`), `ContinueOnError`, `CommandTimeoutSeconds` (per batch; null = provider default, 0 = unlimited), `OnExecutionPlanReady`/`OnBatchStart`/`OnBatchEnd`/`OnMessage`, `CancellationToken` → `UserCancelled`. |

Only the `e2e create|drop|cleanup` and `exec` commands are executable-only (`tiger-sqlcmd`); every
capability above is reachable from TigerWrap's own code through the NuGet libraries.

### Responsibility split

| Responsibility | Owner |
| --- | --- |
| Profile persistence, copy, credential protection, atomic mutation | TigerQuery (done) |
| Default/explicit store resolution and the `--tq-connection-store-file` option | TigerQuery (done); TigerWrap supplies its default file |
| sqlcmd parsing, prepared plans, batch failure and `:on error` semantics, timeouts | TigerQuery (done) |
| Generic E2E authorization, database creation/ownership/forced drop/cleanup | TigerQuery — TigerWrap composes it (P1) |
| In-process SQL execution for E2E setup and population scripts (`db sqlcmd`) | TigerWrap command over TigerQuery's engine (P2) |
| Bootstrap naming, provisioning instructions, and fail-closed policy for TigerWrap tests | TigerWrap |
| E2E journeys and assertions (install, upgrade chain, export/import) | TigerWrap |
| TigerWrap product commands (`db *`), connection roles, upgrade catalogue, capability probe | TigerWrap |

## Settled decisions

### P1 — TigerWrap E2E composes TigerQuery's generic E2E lifecycle

TigerWrap E2E uses TigerQuery's generic E2E lifecycle. It does not reimplement database ownership,
owning-connection creation, forced teardown, or cleanup semantics.

- A human provisions the permanent bootstrap with `tiger-wrap connection add-e2e-bootstrap --name
  TigerWrap-E2E-Test --database master --allow-database-create …` (TigerWrap may set
  `DefaultE2eBootstrapConnectionName` so `--name` is optional).
- The harness resolves it with `SqlServerE2eConnectionResolver` and uses
  `SqlServerE2eSessionLifecycle` for database creation, the owning same-store copy, owned forced
  drop, and session cleanup.
- Consequences: authorization is TigerQuery's `ittiger.e2e.*` keys (no `TigerWrap:E2E:*` keys);
  databases are named `_TQ_E2E_<part>_<32hex>` and connections `E2E-<part>-<32hex>`; TigerWrap owns
  no create/drop SQL, ownership records, or orphan logic; the `TWE2E_` fixture and its age-based
  sweep are retired when the harness replaces them.

### P2 — `db sqlcmd` stays in 0.9.2; `db create` / `db drop` are deferred

- **`db sqlcmd` remains in 0.9.2.** TigerWrap needs an in-process way to create schema in and
  populate disposable E2E databases, and to run setup scripts, through `tiger-wrap` itself. It is
  the SQL-execution primitive of the E2E harness and is implemented.
- **`db create` and `db drop` are deferred beyond 0.9.2.** TigerQuery's E2E lifecycle already owns
  disposable database creation and teardown, so neither is needed for E2E, and 0.9.2 ships no
  destructive database command. `db install` stays the only user-facing database-lifecycle entry
  point.

### TigerQuery 0.8.8 is Good Enough for 0.9.2

- TigerWrap 0.9.2 builds on TigerQuery 0.8.8 as released. No further upstream TigerQuery work is
  created for 0.9.2 unless TigerWrap implementation meets a concrete blocker.
- The known TigerQuery imperfections (see
  [TigerQuery observations](#tigerquery-observations-provider-side-not-tigerwrap-work)) are
  non-blocking follow-up items, not 0.9.2 prerequisites.
- TigerWrap stays self-sufficient at the CLI level: it uses the TigerQuery libraries in-process and
  never depends on the external `tiger-sqlcmd` executable, dotnet tool, or WinGet package.

## Main user-facing features

### 1. Project export/import

TigerWrap 0.9.2 supports:

- exporting all projects;
- exporting a selected subset using interactive multi-select;
- importing project packages;
- format versioning;
- full backward compatibility;
- mandatory one-step-forward import compatibility;
- explicit loss warnings;
- project-name conflict handling;
- transaction-per-project execution;
- internal storage of canonical project JSON.

Described in detail in [TigerWrap_0.9.2_Project_Import_Export_Design.md](TigerWrap_0.9.2_Project_Import_Export_Design.md).

### 2. TigerWrapDb install (implemented)

A menu-visible workflow installing TigerWrapDb into an already-created empty database:

```text
select existing connection
-> inspect target database (emptiness and compatibility level >= 130)
-> show install plan
-> confirm
-> prepare full-install script (parse before connect)
-> execute with batch-level progress
-> verify TigerWrapDb version and API level
```

TigerWrap does not assume the user may create databases. The packaged full-install script remains
the deployment artifact; `db install` executes it and does not reimplement it. A refused install
currently returns `InvalidDatabase` (17); it moves to a dedicated `DatabaseNotEmpty` code in the
response-code batch. Connection-role filtering is added with connection roles.

### 3. Chained TigerWrapDb upgrades

The existing single-step 0.9.0 → 0.9.1 guided upgrade is generalized.

Required paths for 0.9.2:

```text
0.9.0 -> 0.9.1 -> 0.9.2
0.9.1 -> 0.9.2
```

Expected behavior:

- inspect the current database version;
- resolve the complete supported chain;
- verify all required scripts exist **before** any execution;
- display the complete plan;
- require backup confirmation once, for the whole chain;
- execute each step in order, preparing each script immediately before it runs;
- show chain-level and batch-level progress;
- verify expected version and API level after **each** step;
- stop immediately on failure and report which step failed and what version the database is now at;
- never skip versions unless a direct upgrade script explicitly exists.

The upgrade SQL scripts remain responsible for verifying the expected database identity, starting
version, and transition. They do not detect arbitrary schema drift.

**What is replaced.** `DbCommandSupport` encodes one hard-coded step: `TigerWrapDbStatus` is
documented as "not a version framework", `UpgradeSourceVersion` is a `const string`, and
`TigerWrapApp` bakes the source version into the `db upgrade` help text. Chained upgrade replaces
all three with an upgrade-step catalogue and a chain resolver.

**Linear chain, not a general graph (decided).** The catalogue is `(fromVersion, toVersion,
scriptFileName, expected version/apiLevel/minApiLevel)` so a future direct jump is representable,
but 0.9.2 resolves a strict ascending chain and rejects any catalogue that is not one. The resolver
is pure (no I/O) and returns an ordered step list or a typed failure (`AlreadyCurrent`,
`NoPathFrom`, `NewerThanTool`, `NotTigerWrapDb`, `MissingScript`); multi-step behavior is proven by
unit tests over a synthetic catalogue.

**Catalogue.** CLI-side, because it must work against a database without 0.9.2 objects. Filenames
found on disk are matched against it; an expected script that is missing is a hard failure during
planning. `BuildInstaller.ps1` already packages every `TigerWrapDb_Upgrade_*.sql`.

```text
0.8.5 -> 0.9.0   TigerWrapDb_Upgrade_v_0.8.5_to_0.9.0.sql
0.9.0 -> 0.9.1   TigerWrapDb_Upgrade_v_0.9.0_to_0.9.1.sql   version 0.9.1, apiLevel 2, minApiLevel 2
0.9.1 -> 0.9.2   TigerWrapDb_Upgrade_v_0.9.1_to_0.9.2.sql   version 0.9.2, apiLevel 3, minApiLevel 3
```

**Per-step verification.** After each step the database must report the exact expected triple, not
merely "newer": `Script.PreUpgradeVersionCheck.sql` uses `SET NOEXEC ON`, which can prevent an
upgrade without a batch error.

**Idempotency.** A zero-length chain exits `Ok` with "nothing to upgrade"; re-running a completed
chain is a no-op success; an individual step is not idempotent and refuses to re-run from the wrong
source version. Recovery from a failed step is "restore the backup", and documentation says so.

**Prepared execution is parse-only.** Preparing a step proves the file exists and its sqlcmd
structure parses before that step mutates anything; it cannot prove a later step will succeed, and
the UI must not imply the chain is transactional.

### 4. Capability probe

`db info` and upgrade planning gain `[Toolkit].[GetDbCapabilities]`, added in the 0.9.2 schema. The
probe treats SQL error 2812 (and a missing-column shape) as "pre-0.9.2 database" using the existing
`ProbeAsync` fallback pattern and never throws for absence. `[Toolkit].[GetDbInfo]` and its
four-output contract stay frozen (import/export design Decision D1, Invariant I1).

## Supporting database commands

### Menu-driven commands

```text
db info
db install
db upgrade
```

### Script-oriented commands

Discoverable through command help but excluded from the menu via
`command.CommandMenu(CommandMenuMode.Disabled)`:

```text
db sqlcmd
```

Script-oriented commands prompt only for connection selection; every other required value is
explicit, and in non-interactive mode a missing value is an argument error, never a default.

## Connection roles

TigerWrap owns the `TigerWrap:` metadata namespace and a small, frozen key set. `QueryByMetadata`
compares ordinally and case-sensitively, so these literals are exact.

| Key | Values | Meaning |
| --- | --- | --- |
| `TigerWrap:ConnectionRole` | `Regular`, `Administrative` | Purpose of the connection. Absent means `Regular`. |

- **Absent means `Regular`.** Existing connections have no metadata and must keep working;
  `SqlServerConnectionMetadataFilterOperator.IsNotSet` expresses this directly.
- Roles are independent of TigerQuery's `ittiger.e2e.*` E2E authorization; do not collapse them.
- Metadata is a guard rail, not a security boundary; SQL Server permissions remain authoritative.
- With `db create`/`db drop` deferred (P2), `Administrative` has no consumer in 0.9.2 and the role
  reduces to "refuse administrative-looking targets" for `db install`/`db upgrade`; the key set stays
  as specified so it does not change later.

**Administrative connections target `master` (decided).** TigerWrap keeps
`SqlServerConnectionValidationPolicy.DatabaseRequired` (the policy type is unchanged at 0.8.8) and
introduces no database-less connections.

| Command | Accepted connections |
| --- | --- |
| `db info` | Any |
| `db install`, `db upgrade` | `Regular` only |
| `db sqlcmd` | Any, explicitly selected |
| `db create`, `db drop` (deferred) | `Administrative` only |
| `project *`, `generate-code`, export/import | `Regular` only |

Selection providers are filtered to the accepted set, and an explicitly named connection of the
wrong role is a hard error rather than "connection not found".

## `db sqlcmd` (implemented)

```text
tiger-wrap db sqlcmd <connection> --file <script.sql> [--mode Normal|SqlCmd|SqlCmdEx]
                     [--command-timeout <seconds>] [--tq-connection-store-file <path>]
```

- Menu-excluded; prompts only for the connection. `--file` is required and never prompted.
- The connection is a saved TigerQuery profile from the run's selected store (default file, explicit
  `--tq-connection-store-file`, or `TIGERQUERY_CONNECTION_STORE_FILE`), resolved without
  TigerWrapDb API-level validation because the target is usually not a TigerWrapDb.
- Execution is TigerQuery's engine in-process, prepared mode, through the shared `ScriptRunner`
  (batch N of M progress, parse before connect). Parser mode (`--mode`, default `SqlCmd`), per-batch
  command timeout (`--command-timeout`, omitted = provider default, `0` = unlimited), and the
  continue-on-error default are TigerQuery's own; `:on error exit` in the script stops later batches.
- Any non-`Success` engine result, including a failed batch the run continued past, ends the command
  with `DbError` (1); a connection that cannot be opened is also `DbError`; cancellation is
  `TigerCliCancelled`; a name absent from the selected store fails provider validation
  (`TigerCliValidationError`, 2005) and an unresolvable profile is `CliMissingConnection`; a missing
  `--file` is TigerCli's missing-required-option validation error (2005). Dedicated codes may follow
  in the response-code batch.
- Result sets are not rendered; the command is for setup and population scripts, not querying.
- Script variables (`--var`) are added only when a TigerWrap script needs them.

## Deferred: `db create` / `db drop`

Deferred beyond 0.9.2 (P2). The designs below are kept for the later release.

### `db create`

```text
select administrative connection
-> provide database name
-> validate name
-> confirm
-> create database
-> verify creation
```

- the name is validated (no `]`, null character, or leading/trailing whitespace) and passed as a
  parameter, quoted server-side with `QUOTENAME`;
- no file-path options — the `:setvar DefaultDataPath` values in deployment scripts are SSDT
  artifacts;
- the database inherits `model`'s collation and compatibility level; both are reported, with a
  warning below 130;
- it does not proceed into installation.

### `db drop`

Safeguards, in evaluation order:

1. explicit database name required;
2. refuse `master`, `model`, `msdb`, `tempdb`, and any `database_id <= 4`;
3. refuse the database the administrative connection itself targets;
4. require a stored connection naming that database with disposable intent, **or** `--force`;
5. show server, database, size, and creation date;
6. explicit confirmation; `--confirm` in non-interactive mode;
7. no forced disconnect unless `--force-disconnect` (`SET SINGLE_USER WITH ROLLBACK IMMEDIATE`);
8. fail safely if ownership or intent is unclear.

This is a user command and never drops through TigerQuery's E2E ownership records; E2E teardown is
the harness's job.

## Prepared execution

Prepared execution is the model for all script-based TigerWrap operations (`db install`,
`db upgrade`, `db sqlcmd`). Its guarantees and limits:

- the complete sqlcmd structure is parsed and batch totals are known before the connection opens;
- parser failures happen before any database mutation;
- it does not replace SQL-side guards or transaction logic, and does not validate SQL semantics;
- under `:on error exit` a severity ≥ 11 error fails the batch and the run and stops later batches
  (TigerQuery 0.8.8). `db sqlcmd` live tests prove this through `ScriptRunner` and the `tiger-wrap`
  host, including that later batches do not run and that a failed batch without `:on error exit`
  still fails the command. `db install` and `db upgrade` already treat `ExecutionResult.ResultCode`
  and `FailedBatches` as the failure authority; a failing-deployment-artifact test for them belongs
  to the E2E harness journeys.

## Empty-database protection (implemented)

Both layers exist: the `db install` preflight and the full-install script's own pre-deployment
guard. They share one predicate — non-MS-shipped `sys.objects` of the user object types, user
`sys.types` (which is how table types are caught), user `sys.assemblies`, and the TigerWrap-owned
schema list — plus the compatibility-level ≥ 130 check. The guard sets `QUOTED_IDENTIFIER ON`
itself and fails with `SET NOEXEC ON` before the first `CREATE SCHEMA`.

**Pre-deployment toggle.** `Script.PreDeployment.sql` has two mutually exclusive includes (install
guard vs. upgrade version check). Runtime mode detection was rejected: a full install into a
database already containing TigerWrap objects would detect "upgrade" and skip the emptiness check.
The risk of generating an artifact with the wrong arm is closed by `InstallGuardArtifactTests` and
the `BuildInstaller.ps1` gate, not by construction.

## Upgrade safety philosophy

Upgrade scripts verify expected identity, source version, and path; they do not detect manual
schema drift. `[DbInfo].[GetCurrentVersion]` and `[Toolkit].[GetDbInfo]` read `TOP (1) … ORDER BY
[Id] DESC` from the append-only `[dbo].[SchemaVersion]` (last inserted, not highest); every
version-bearing accessor keeps that shape and `ProjectFormatVersion` is non-decreasing across
ascending `[Id]` (Invariant I7 of the import/export design).

## E2E testing foundation

### Invariants

- **One human-provisioned bootstrap.** `TigerWrap-E2E-Test`, targeting `master`, Windows or SQL
  authentication (SQL passwords only through TigerQuery's current-user DPAPI protection). Its
  existence with the required authorization metadata is the explicit human authorization to run
  destructive TigerWrap E2E activity against that one server. The suite never creates, edits,
  deletes, replaces, or repairs it.
- **No inference, no fallback.** The harness never reads a raw connection string from code or an
  environment variable and never infers a server from `.`, `localhost`, or LocalDB. A missing or
  invalid bootstrap causes an explicit skip or failure, never a fallback.
- **Default store is the normal path.** The harness selects the store the same way the app does:
  `SqlServerConnectionStorePathResolver` with TigerWrap's default file, an optional explicit path,
  and TigerQuery's environment variable. It uses exactly one `SqlServerConnectionStore` instance
  for bootstrap lookup, copy, and cleanup, and CLI journeys run the app with that same file.
- **Temporary connections are copies.** Every E2E database is reached through a same-store copy of
  the bootstrap; TigerWrap never reconstructs a connection string or profile property list.
- **Cleanup never masks failure.** Database and connection creation are tracked independently;
  cleanup attempts each applicable step; the original test exception stays primary and cleanup
  errors are supplementary; a passing body with failed cleanup fails the test; orphans are reported
  prominently.
- **No `tiger-sqlcmd`.** Everything runs in-process through the TigerQuery libraries and TigerWrap's
  own CLI host; setup and population scripts run through `tiger-wrap db sqlcmd`.

### Lifecycle (P1)

1. Resolve the store; resolve `TigerWrap-E2E-Test` with `SqlServerE2eConnectionResolver`
   (`RequireDatabaseCreationPermission = true`); verify it targets `master` and is reachable.
2. `SqlServerE2eSessionLifecycle.CreateAsync(sessionId, { DatabaseNamePart = "TigerWrap" })` —
   creates `_TQ_E2E_TigerWrap_<32hex>` through the bootstrap and persists the owning copy
   `E2E-TigerWrap-<32hex>` in the same store.
3. Prepare the database with `tiger-wrap db sqlcmd <owning connection> --file …` (schema and
   population scripts) or `db install`, then run TigerWrap commands and assertions through that
   connection name.
4. `DropAsync(connectionName, sessionId)` in cleanup; `CleanupAsync(sessionId)` as the run-level
   recovery path. Forced disconnect and ownership checks are TigerQuery's.

### Existing fixture

`SqlServerTestDatabase` (hard-coded `Data Source=.` raw connection strings, a temporary no-op
protected store, `TWE2E_` names, an age-based orphan sweep, unconditional `SINGLE_USER` drops) is
evidence, not the target. Replacing it with the P1 lifecycle is the next slice after `db sqlcmd`;
until then existing live tests, including the `db sqlcmd` tests, keep using it.

### Test journeys

Install, chained upgrade, and import/export journeys share the lifecycle. Negative journeys include
a missing or unauthorized bootstrap, a bootstrap not targeting `master`, a missing explicit-store
bootstrap, failure between database and connection creation, install into non-empty or
low-compatibility databases, unsupported upgrades, and a deliberately failing script under
`:on error exit`.

### SQL Server 2017 coverage

Unresolved and must be decided, not assumed. The SSDT project targets `Sql150DatabaseSchemaProvider`
(SQL Server 2019); the local fixture exercises one instance; import/export is the first significant
JSON consumer, and `JSON_OBJECT`, `JSON_ARRAY`, `JSON_PATH_EXISTS`, and typed `ISJSON` are post-2017.

1. Lower the DSP to `Sql140` and add a 2017 instance to the test matrix.
2. Lower the DSP to `Sql140` and verify 2017 manually once per release, documented as a manual gate.
3. Drop the SQL Server 2017 claim and state 2019 as the floor — a deliberate product decision.

Leaving the DSP at `Sql150` while documenting 2017 support is the only unacceptable outcome, and it
is the current state.

### What belongs in 0.9.2 versus later

| Capability | 0.9.2 | Later |
| --- | --- | --- |
| Human-provisioned bootstrap validation, same-store temporary connection, owned teardown (TigerQuery lifecycle) | Yes | |
| Default TigerWrap store plus optional explicit store | Yes (app and `db sqlcmd` done; harness next) | |
| `db install` / `db info` journeys | Yes | |
| Chained upgrade from packaged 0.9.0 and 0.9.1 artifacts | Yes | |
| Export/import round trip against a real database | Yes | |
| Golden package byte-comparison and the compatibility matrix | Yes | |
| Small populated fixture database (through `tiger-wrap db sqlcmd`) | Yes | Rich parser-stress database |
| `db sqlcmd` | Yes (done) | `--var` if needed |
| `db create` / `db drop` | | Yes (P2) |
| Generated-code compilation and wrapper execution | | Yes |
| Multi-version SQL Server matrix in CI | | Yes, unless 2017 option 1 is chosen |
| Automatic bootstrap provisioning | Never | |

## Work streams and dependencies

```text
db sqlcmd (done) ──> A. E2E harness on TigerQuery's lifecycle ──┐
                                                                ├──> E. Release hardening
B. Roles + upgrade chain + capability probe ──┐                 │
Response-code batch ──> C. TigerWrapDb 0.9.2 schema ──> D. Import/export
```

- The TigerQuery prerequisite is **complete**: 0.8.8 is Good Enough and nothing in 0.9.2 waits on
  another TigerQuery release.
- **A** is unblocked (P1 and P2 settled, `db sqlcmd` in place). **B** and the response-code batch
  need no decision and can start now.
- The response-code batch lands before **C** freezes; **C** precedes **D**.
- **E** depends on A–D and on the SQL Server 2017 decision.

## Implementation order

### Phase 1 — decision-free groundwork (in progress)

- connection roles: `TigerWrap:ConnectionRole` constants, absent-means-`Regular`, role-filtered
  providers, wrong-role hard errors (`ConnectionCompatibilityTests` must still pass unchanged);
- upgrade-step catalogue and pure chain resolver replacing `TigerWrapDbStatus`/`UpgradeSourceVersion`;
  per-step verification and "database is now at version X" failure reporting; `db upgrade` help text
  no longer bakes in a version;
- **done:** `db sqlcmd`, with live tests proving `ResultCode`/`FailedBatches` as the failure
  authority and `:on error exit` through `ScriptRunner` and the `tiger-wrap` host;
- capability-probe plumbing with the 2812 fallback, tested against real 0.9.0/0.9.1 databases.

### Phase 2 — E2E harness on TigerQuery's lifecycle (next)

- bootstrap resolution through `SqlServerE2eConnectionResolver`, store selection, database and
  owning-connection lifecycle through `SqlServerE2eSessionLifecycle`, failure-preserving cleanup,
  provisioning documentation;
- migrate the existing install/upgrade and `db sqlcmd` live tests onto it and retire
  `SqlServerTestDatabase`'s raw connection strings, `TWE2E_` names, and age-based sweep;
- small populated fixture database prepared through `tiger-wrap db sqlcmd`.

### Phase 3 — Response codes and TigerWrapDb 0.9.2 schema

- the full batch of new `[Enum].[ToolkitResponseCode]` rows in one change (including
  `DatabaseNotEmpty`, then move `db install` onto it);
- `[dbo].[Project].[Uid]`; `[dbo].[SchemaVersion].[ProjectFormatVersion]` and
  `[DbInfo].[GetProjectFormatVersion]`; `[Static].[ProjectFormatElement]` for format 1;
  `[Static].[LanguageOption].[IntroducedInProjectFormatVersion]`;
- the `[History]` schema, `Security/History.sql`, `[Enum].[PackageOperationType]`,
  `[History].[ProjectPackage]`;
- `[Toolkit].[GetDbCapabilities]`;
- `ApiLevel`/`MinApiLevel` to 3 in `Script.Version.sql` and `ExpectedDbInfo` together;
- regenerate `ToolkitDbHelper` wrappers;
- author the 0.9.1 → 0.9.2 upgrade script and **regenerate** `TigerWrapDb_FullDeploy_v_0.9.2.sql`
  (still unreleased, so regeneration is allowed); add the 0.9.1 → 0.9.2 catalogue step;
- fix `[View].[Project]` to include the 0.9.1 description-attribute columns.

### Phase 4 — Project export

- `[Toolkit].[ExportProjects]` with canonical shape, ordering, `INCLUDE_NULL_VALUES`, and checksum;
- all-projects and multi-select export; self-validation including read-back; canonical JSON stored
  internally; the format-1 golden package.

### Phase 5 — Project import

- `[Toolkit].[ValidateProjectPackage]`; migration dispatch; structural unknown-path/flag detection;
  compatibility and loss analysis; conflict planning and `[Toolkit].[AnalyseProjectImport]`;
- Rename, AutoRename, Skip, Replace (import-under-temp-name), Fail; transaction per project via
  `[Toolkit].[ImportProject]`; `defaultDatabase` policy; pre-commit logical verification;
  partial-success reporting; synthetic format-2/format-3 fixtures and the compatibility matrix.

### Phase 6 — Chained upgrade completion

- test 0.9.0 → 0.9.2 and 0.9.1 → 0.9.2 end to end with per-step verification and failure reporting.

### Phase 7 — Release hardening

- resolve and act on the SQL Server 2017 decision;
- add `TigerWrapDb_FullDeploy_v_0.9.2.sql` and the 0.9.1 → 0.9.2 upgrade script to
  `ReleasedArtifactTests.ReleasedArtifacts` as part of the release;
- installer and WinGet upgrade scenarios; packaged scripts verified; clean install and upgrade from
  0.9.1; documentation and screenshots; Release build and tests green.

## Risk register

| # | Risk | Impact | Likelihood | Mitigation |
| --- | --- | --- | --- | --- |
| R1 | Extending `[Toolkit].[GetDbInfo]` breaks probing of 0.9.0/0.9.1 databases (error 8144) | Critical | High if undecided | Frozen signature; additive `GetDbCapabilities` with 2812 fallback. |
| R2 | SQL Server 2017 claimed but DSP targets 2019 and nothing tests 2017 | High | High | Resolve before Phase 4 writes significant JSON. |
| R3 | `OPENJSON` unavailable below compatibility level 130 | High | Medium | **Mitigated** for install: preflight and SQL guard both check. |
| R4 | `[Toolkit].[CreateProject]` rejects a non-existent `defaultDatabase` on import | High | Certain if unaddressed | Dedicated import write path with explicit policy (import/export Decision D5). |
| R5 | Export field set drifts from `[dbo].[Project]` | High | Medium | Registry-completeness test; fix `[View].[Project]` in Phase 3. |
| R6 | Bare `FOR JSON` split into 2033-character rows | Medium | High without discipline | Assign to `NVARCHAR(MAX)` then `SELECT`; large-package round-trip test. |
| R7 | Pre-deployment toggle produces a wrong artifact | High | Medium | **Mitigated** by `InstallGuardArtifactTests` and the installer build gate. |
| R8 | TigerWrap reports script failure from message counts instead of the engine result | Medium — divergent failure reporting | Low | **Mitigated:** all script commands use `ResultCode`/`FailedBatches`; live `:on error exit` tests through `db sqlcmd`. |
| R9 | The E2E bootstrap is inferred, auto-created, repaired, or replaced | Critical | Medium without a closed contract | Exact-name + authorization + `master` validation; fail closed; no raw strings or server inference. |
| R10 | `db drop` destroys a real database | Critical | — | **Retired for 0.9.2:** `db drop` is deferred (P2). |
| R11 | New exit codes each require a DB change plus wrapper regeneration | Medium | High | One Phase 3 batch. |
| R12 | Golden packages committed before the format settles | Medium | Medium | Commit format-1 goldens only after Phase 4 self-validation. |
| R13 | Scope creep from "Beyond 0.9.2" | Medium | Medium | That list is normative. |
| R14 | Chained upgrade leaves an intermediate version | Medium | Medium | Per-step verification, explicit "now at version X", documented restore. |
| R15 | `TIGERQUERY_CONNECTION_STORE_FILE` set for another TigerQuery host silently redirects `tiger-wrap` to a different store | Medium — "my connections disappeared" | Low–Medium | Documented in `docs/CLI.md`; `--help-env` lists it; the run fails rather than falls back on a bad value. Revisit only if users are confused. |
| R16 | Harness and app use different store files | High — lookup and cleanup disagree | Medium | Harness resolves through the same resolver and passes the same file to the app host. |
| R17 | `db sqlcmd` runs a script against the wrong connection | High | Low | Menu-excluded; connection explicitly named or selected, never defaulted in non-interactive mode; SQL Server permissions remain authoritative. |
| R18 | E2E cleanup drops a database it does not own | Critical | Low | TigerQuery exact session/database ownership plus prefix grammar (P1). |
| R19 | Generated E2E connection names (≥ 44 characters) exceed TigerQuery's 40-character `connection show/edit/delete` argument limit | Low — manual inspection awkward | Certain | Harness never uses those commands; manual recovery uses `CleanupAsync`; TigerQuery follow-up item. |

## Test matrix

| Area | Level | Requires SQL Server | Phase |
| --- | --- | --- | --- |
| Connection role keys, absent-means-`Regular`, filtering | Unit | No | 1 |
| Role-filtered providers reject wrong-role named connections | App | No | 1 |
| Upgrade chain resolution: 0.9.0, 0.9.1, current, unknown, newer; synthetic multi-step catalogue | Unit | No | 1 |
| Missing catalogue script fails during planning, before mutation | Unit | No | 1 |
| `db sqlcmd`: executes a file against a managed connection; selected store only; batch failure fails the command; `:on error exit` stops later batches; no `tiger-sqlcmd` dependency | App + E2E | Partly | done |
| Capability probe falls back cleanly against 0.9.0 and 0.9.1 databases | E2E | Yes | 1 |
| Missing/unauthorized bootstrap and missing explicit-store bootstrap fail closed | App | No | 2 |
| Default store and explicit store each use only the selected bootstrap and temporary connection | E2E | Yes | 2 |
| Bootstrap unchanged across successful and failed runs | E2E | Yes | 2 |
| Temporary copy works with Windows and SQL authentication | E2E | Yes | 2 |
| Cleanup drops only owned databases; cleanup failure does not mask the body failure | Unit + E2E | Partly | 2 |
| `db install` succeeds into empty; refuses non-empty and compatibility < 130 | E2E | Yes | done → migrate in 2 |
| SQL-side guard refuses non-empty when run directly; CLI and SQL definitions agree | E2E | Yes | done |
| API level 3 rejects 0.9.1 CLI; 0.9.2 CLI rejects API level 2 | E2E | Yes | 3 |
| Export registry completeness vs `[dbo].[Project]` | E2E | Yes | 3 |
| Export determinism (repeat runs, CI/CS/AS collations); self-validation; large-package chunking; round trip | E2E | Yes | 4 |
| Malformed package rejection; compatibility cells (1,1), (1,2), (1,3); undeclared unknown element; `Structural` loss | E2E | Yes | 5 |
| Analysis mutates nothing; each conflict action; Replace preserves the original at each step; no `~twimport_` survivor; partial success; `defaultDatabase` policies | E2E | Yes | 5 |
| Chained 0.9.0 → 0.9.2 and 0.9.1 → 0.9.2; per-step verification failure | E2E | Yes | 6 |
| Installer packages every catalogue script | Build | No | 7 |
| SQL Server 2017 compatibility (per the chosen option) | E2E | 2017 instance | 7 |

## Documentation goals for 0.9.2

- TigerWrap CLI and TigerWrapDb are separate components;
- `db install` targets an existing empty database; database creation is not the default;
- the compatibility-level 130 requirement and how to fix it;
- project export/import as the portability and recovery mechanism; conflict behavior and the
  `defaultDatabase` policy;
- upgrade chains, and that a failed step is recovered by restoring a backup;
- backup requirements;
- connection metadata is a guard rail, not a permission;
- connection-store location and per-run selection (`--tq-connection-store-file`,
  `TIGERQUERY_CONNECTION_STORE_FILE`) — **done** in `docs/CLI.md`;
- snapshot growth and pruning; the package checksum is integrity, not a signature; name-conflict
  detection follows the target collation;
- WinGet installation and update timing;
- menu-driven workflows versus script-oriented commands;
- `db sqlcmd` as a script-oriented command — **done** in `docs/CLI.md`;
- maintainer documentation: provisioning `TigerWrap-E2E-Test` with `connection add-e2e-bootstrap`,
  default-store behavior, explicit-store isolation, and orphan recovery through TigerQuery's session
  cleanup (P1).

Screenshots: main menu; DB info; DB install; DB upgrade plan and progress; project export selection;
import conflict plan; import result.

## Release acceptance criteria

0.9.2 is not released until:

- the repository matches the settled P1 and P2 decisions: E2E uses TigerQuery's lifecycle, `db sqlcmd`
  ships, and no `db create`/`db drop` command exists;
- the E2E suite uses only the human-provisioned `TigerWrap-E2E-Test` bootstrap from the selected
  default or explicit store, refuses every missing/invalid case without fallback, and never creates,
  modifies, or deletes the bootstrap;
- no TigerWrap production code or test uses a raw or inferred SQL Server connection string for E2E
  setup, and no test depends on the `tiger-sqlcmd` executable;
- every E2E database is reached through a same-store TigerQuery copy of the bootstrap;
- explicit-store runs never touch the default store;
- cleanup preserves the original failure, reports orphaned resources, and drops only owned
  databases;
- project export works for all and selected projects, validates itself including read-back, and is
  byte-deterministic;
- project import supports the documented conflict actions, one transaction per project, and Replace
  preserves the original on failure at every step;
- earlier project formats import, and the compatibility matrix passes for (1,1), (1,2), (1,3);
- one-step-forward import is tested with synthetic newer-format fixtures;
- lossy fields and flags are reported per project with severity and resulting default;
- an undeclared unknown element rejects the package;
- import succeeds where the recorded `defaultDatabase` does not exist;
- `db install` refuses occupied and sub-130 databases before mutation, and the full-install script
  independently refuses occupied databases;
- chained upgrades work from 0.9.0 and 0.9.1 with per-step verification, and the 0.9.2 CLI still
  probes and upgrades 0.9.0 and 0.9.1 databases;
- all script workflows use prepared execution, a triggering error under `:on error exit` stops later
  batches and fails the run, and progress shows batch N of M;
- the SQL Server 2017 decision is resolved and the repository matches the documented claim;
- `[View].[Project]` matches `[dbo].[Project]`;
- the released 0.9.2 artifacts are added to `ReleasedArtifactTests`;
- Release build and tests are green, and packaged installer scripts (every catalogue script) are
  verified.

## Beyond 0.9.2

- restore from internal project snapshots;
- automatic pre-delete and pre-import snapshots;
- project history browsing and selective restore;
- project diff;
- richer import merge behavior;
- persisted import plans and exact-replay retry;
- snapshot retention policy and pruning commands;
- export signing or stronger integrity metadata;
- automatic export before database upgrade;
- generated-code compilation and wrapper-execution E2E coverage;
- parser stress database integration;
- multi-version SQL Server CI matrix;
- `db create` / `db drop` (deferred by P2) and a composed `db create + install` operation;
- `db sqlcmd` variables (`--var`), inline queries, and result-set output;
- the TigerQuery follow-up items below, as separate TigerQuery work.

These must not expand the 0.9.2 scope.

## Core design principles

1. Database creation is explicit, not assumed.
2. Normal installation targets an existing empty database.
3. SQL-side guards remain authoritative.
4. Script-oriented commands stay out of the menu.
5. TigerQuery execution, metadata, store, and E2E capabilities are reused, never re-implemented.
6. Bootstrap and probe surfaces are frozen; capability discovery is additive and failure-tolerant.
7. Import/export is a durable compatibility contract.
8. No silent data loss.
9. No partial project mutation.
10. Replace imports first and deletes later.
11. Real SQL Server testing is part of the release gate.
12. The permanent bootstrap is explicit human authorization; automation never provisions it or falls
    back to another server or store.
13. Temporary connections are TigerQuery copies, never rebuilt from connection strings in TigerWrap.
14. Store selection happens once per run and every operation in that run uses it.

## TigerQuery observations (provider-side, not TigerWrap work)

Found while verifying 0.8.8. They are non-blocking follow-up items, not 0.9.2 prerequisites; any fix
is a separate TigerQuery task, opened for 0.9.2 only if TigerWrap implementation meets a concrete
blocker.

- `SqlServerConnectionStore.Delete`'s refusal message for E2E-owning profiles names
  `tiger-sqlcmd e2e drop|cleanup`, which is misleading in other hosts such as `tiger-wrap`.
- The 40-character `name` limit on `connection show/edit/delete` cannot address the lifecycle's own
  generated `E2E-<part>-<32hex>` names.
- `TigerQueryCliContribution` documentation says the `connection` group can be mounted without the
  contribution; in practice `TigerQueryCliOptions.Store` throws until the contribution has run.
- `CopyForE2eSession` accepts no metadata overrides, so consumer metadata on the bootstrap is copied
  onto session connections unchanged.
- A store path naming an existing directory (without a trailing separator) resolves successfully and
  lists as an empty store rather than failing validation.
- `SqlCmdMessage.Type` names severities 11–16 `Warning` although `IsError` is true and they fail the
  batch; TigerWrap's `ScriptRunner` labels them "Error" in its own output.
