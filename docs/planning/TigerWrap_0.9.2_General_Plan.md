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

## Current foundation

TigerWrap is on the current Tiger* packages:

- ItTiger.Core 0.8.1
- TigerCli 0.8.1
- TigerQuery / TigerQuery.Core / TigerQuery.CliCore 0.8.2

TigerCli 0.8.1 adds no TigerWrap-specific feature but keeps TigerWrap on the current foundation.

TigerQuery 0.8.2 adds two capabilities this release builds on. Both were verified against the shipped assemblies rather than assumed:

**Prepared execution.**

```csharp
TigerQueryEngineOptions.ExecutionMode = TigerQueryExecutionMode.Prepared;
TigerQueryEngineOptions.OnExecutionPlanReady = plan => { /* plan.LogicalBatchCount, plan.TotalExecutionCount */ };
```

`ExecutionPlanReady` fires once, **after the whole sqlcmd structure is parsed and before the SQL connection is opened**. `BatchStart`/`BatchEnd` already carry `BatchNumber`, `TotalLogicalBatchCount`, `OverallExecutionNumber`, and `TotalExecutionCount`. This is what turns today's "47 batches completed" into "batch 47 of 140", and — more importantly — moves parser failures to *before* any database mutation.

**Namespaced connection metadata.**

```csharp
SqlServerConnectionProfile.Metadata            // IDictionary<string,string>, opaque, app-owned
SqlServerConnectionProfile.SetMetadata(key, value)
SqlServerConnectionProfile.RemoveMetadata(key)
SqlServerConnectionStore.QueryByMetadata(IEnumerable<SqlServerConnectionMetadataFilter>)
SqlServerConnectionMetadataFilterOperator.Equals | IsSet | IsNotSet
```

Keys and values are compared **ordinally and case-sensitively** and are never trimmed or normalized by the library. TigerWrap must therefore fix exact literal spellings and never round-trip them through case conversion.

### Two capability gaps that the plan must design around

1. **Connection metadata cannot be set from the CLI in 0.8.2.** `tiger-wrap connection add --help` exposes `--server`, `--database`, `--opt`, and the security options — there is no `--metadata`. `SqlServerConnectionSettings` (the settings class behind the shared `connection add`/`edit` commands) has no metadata member. A `SqlServerConnectionMetadataOptions` type exists in `TigerQuery.CliCore` but is not wired into the shipped commands. Metadata is therefore **programmatic-only** in 0.9.2: tests set it via `SetMetadata`, and any user-facing metadata authoring must be a TigerWrap-owned command or a later TigerQuery release. This directly affects the E2E plan, which previously assumed `db create`-style flows could mint tagged connections through the standard connection commands.
2. **`SqlServerConnectionValidationPolicy` has only `DatabaseOptional` and `DatabaseRequired`, and TigerWrap sets `DatabaseRequired` group-wide** in `TigerWrapApp.cs`. There is no way to permit a database-less connection for administrative use without permitting it for every connection. See [Decision: administrative connections target `master`](#administrative-connections-target-master).

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

### 2. TigerWrapDb install

A menu-visible workflow installing TigerWrapDb into an already-created empty database.

```text
db install
```

Default assumptions:

- the database already exists;
- it was created by the user, a DBA, a managed service, or another authorized process;
- the user has a normal TigerQuery connection targeting it;
- TigerWrap does not assume the user may create databases;
- TigerWrap does not assume company policy allows application tools to create databases.

Flow:

```text
select existing connection
-> inspect target database
-> verify it appears empty and is capable
-> show install plan
-> confirm
-> prepare full-install script (prepared execution; parse before connect)
-> execute with batch-level progress
-> verify TigerWrapDb version and API level
```

The packaged full-install SQL script remains the deployment artifact. `db install` executes it; it does not reimplement it.

**Capability check, not only emptiness.** The full-install script does not set `COMPATIBILITY_LEVEL`, so an installed TigerWrapDb inherits whatever the target database has. `OPENJSON` — which the entire import/export feature depends on — requires database compatibility level 130 or higher. A database restored or created from an old `model` can be perfectly empty and still unable to run the 0.9.2 feature set. `db install` preflight and the SQL-side guard must both check `sys.databases.compatibility_level >= 130` and refuse with an actionable message naming the required `ALTER DATABASE … SET COMPATIBILITY_LEVEL = 130` statement.

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
- prepare all scripts (parse-only) before executing the first one;
- display the complete plan;
- require backup confirmation once, for the whole chain;
- execute each step in order;
- show chain-level and batch-level progress;
- verify expected version and API level after **each** step;
- stop immediately on failure and report which step failed and what version the database is now at;
- never skip versions unless a direct upgrade script explicitly exists.

The upgrade SQL scripts remain responsible for verifying:

- the expected TigerWrap database identity;
- the expected starting version;
- the expected upgrade transition.

They do not detect arbitrary schema drift. The recorded version is treated as the trusted representation of the installed schema.

#### What has to be replaced to make this work

`DbCommandSupport` currently encodes a single hard-coded step and says so in its own comment: `TigerWrapDbStatus` is documented as "deliberately limited to the single upgrade step this release supports (0.9.0 -> 0.9.1); not a version framework", `UpgradeSourceVersion` is a `const string`, and `TigerWrapApp` bakes the source version into the command's help text at registration time. Chained upgrade replaces all three with an upgrade-step catalogue and a chain resolver.

#### Linear chain, not a general graph

**Decision:** the executor resolves an **intentionally linear version chain**, not a general graph.

Rationale: with a linear chain, "resolve the path" is a sorted walk with an obvious correctness argument, and the failure modes are "no step from here" and "gap in the chain". A general graph brings shortest-path selection, ambiguity between a direct and a stepwise route, cycle detection, and a policy for preferring one route over another — all of which are decisions no user has asked for, over a version history that has never branched. The catalogue is expressed as `(fromVersion, toVersion, scriptFileName)` pairs so that a future direct-jump step is representable, but 0.9.2 resolves them as a strict ascending chain and rejects any catalogue that is not one.

#### Upgrade-step catalogue

The catalogue is CLI-side, derived from the packaged script filenames plus a small authoritative table, because it must work against a database that does not yet contain 0.9.2 objects — it cannot live in the database being upgraded.

```text
0.8.5 -> 0.9.0   TigerWrapDb_Upgrade_v_0.8.5_to_0.9.0.sql
0.9.0 -> 0.9.1   TigerWrapDb_Upgrade_v_0.9.0_to_0.9.1.sql
0.9.1 -> 0.9.2   TigerWrapDb_Upgrade_v_0.9.1_to_0.9.2.sql
```

`BuildInstaller.ps1` already copies **all** `TigerWrapDb_Upgrade_*.sql` into `{app}\sql` and only the current `FullDeploy` — so the packaging is already chain-friendly and needs no change. Script discovery must not, however, infer the catalogue purely from filenames found on disk: a stray or hand-edited file would silently join the chain. Filenames are matched against the authoritative catalogue, and an expected script that is missing is a hard failure *during planning*.

#### Per-step verification

After each step the database must report the exact expected `(version, apiLevel, minApiLevel)` triple for that step — not merely "newer than before". The existing `VerifyUpgradeAsync` already does this for one step against `ExpectedDbInfo`; the chained version needs the expected triple **per step**, which means the catalogue carries it:

```text
0.9.0 -> 0.9.1   version 0.9.1, apiLevel 2, minApiLevel 2
0.9.1 -> 0.9.2   version 0.9.2, apiLevel 3, minApiLevel 3
```

A step whose post-conditions do not match stops the chain immediately and reports the database's actual state, because the SQL script's own `SET NOEXEC ON` guards can prevent an upgrade without producing a batch error — which is exactly the failure mode `VerifyUpgradeAsync`'s message already warns about.

#### Idempotency expectations

- A chain of length zero (database already at target) exits `Ok` with "nothing to upgrade", as it does today.
- Re-running a completed chain is a no-op success.
- An **individual step is not idempotent**, and the scripts do not pretend to be: `Script.PreUpgradeVersionCheck.sql` sets `NOEXEC ON` when the current version is not the exact expected source. Re-running a partially failed step therefore refuses rather than corrupting. This is the desired behavior and must be documented as such — the recovery path for a failed step is "restore the backup", not "run it again".

## Supporting database commands

### Menu-driven commands

Normal user workflows, visible in the menu:

```text
db info
db install
db upgrade
```

### Script-oriented commands

Discoverable through command help but excluded from the menu via `command.CommandMenu(CommandMenuMode.Disabled)`, the mechanism `languages-list` and `generate-code` already use:

```text
db create
db drop
db sqlcmd
```

They are primarily for automation, testing, and explicit administrative workflows. They prompt only for connection selection. Every other required value is supplied explicitly; in non-interactive mode a missing value is an argument error, never a default.

## Connection roles

TigerQuery namespaced metadata distinguishes connection purpose. TigerWrap owns one namespace and a small, documented, frozen key set. Because `QueryByMetadata` compares **ordinally and case-sensitively**, these literals are exact.

| Key | Values | Meaning |
| --- | --- | --- |
| `TigerWrap:ConnectionRole` | `Regular`, `Administrative` | Purpose of the connection. Absent means `Regular`. |
| `TigerWrap:Disposable` | `true` | The target database is expendable and may be dropped by `db drop`. |
| `TigerWrap:OwnerTag` | free text | Who or what owns the disposable resource, e.g. an E2E run ID. |
| `TigerWrap:CreatedAtUtc` | ISO-8601 `Z` | When the disposable resource was created, for orphan sweeping. |

Design notes:

- **Absent means `Regular`.** Every connection that exists today has no metadata, and none of them may stop working. Role filtering must therefore treat "missing key" as `Regular`, which `SqlServerConnectionMetadataFilterOperator.IsNotSet` expresses directly.
- **`E2E` is not a role.** The earlier draft listed `Regular` / `Administrative` / `E2E` as three roles, but `E2E` answers a different question: *administrative* versus *regular* is about what the connection may do, while *disposable* is about whether its target may be destroyed. An E2E run needs both an administrative connection (to create and drop) and a regular connection (to install into and use), and both are tagged disposable. Collapsing these into one enum forces a false choice. `Disposable` is therefore an independent flag, and `E2E` disappears as a role.
- Metadata is **not** a security boundary. It is a guard rail that prevents mistakes, not privilege. A user who edits `connections.json` can set anything. Documentation must say so; permissions remain the server's job.
- TigerWrap does not create a separate connection store. Everything goes through `SqlServerConnectionStore`.

### Administrative connections target `master`

**Decision:** an administrative connection is one whose `Database` is `master` (or another database the operator chooses) plus `TigerWrap:ConnectionRole=Administrative`. TigerWrap does **not** introduce database-less connections.

Reason: the only alternative is switching `SqlServerConnectionCommands.Configure`'s `ValidationPolicy` from `DatabaseRequired` to `DatabaseOptional`, which is group-wide. That would let a user save a regular connection with no database and push the failure from connection-creation time to command-execution time for every other command. `DbUpgradeCommand` already has to check `builder.InitialCatalog` for emptiness precisely because that class of failure is unpleasant. Targeting `master` costs nothing and preserves the invariant.

### Connection filtering per command

| Command | Accepted connections |
| --- | --- |
| `db info` | Any. It is a diagnostic and must be able to probe anything. |
| `db install`, `db upgrade` | `Regular` only. Refuses `Administrative` with an explanatory error, because installing into `master` is the accident these roles exist to prevent. |
| `db create`, `db drop` | `Administrative` only. |
| `db sqlcmd` | Any, explicitly selected. |
| `project *`, `generate-code`, export/import | `Regular` only. |

Selection providers are filtered to the accepted set, and an explicitly named connection of the wrong role is a hard error rather than a silently filtered-out "connection not found" — the distinction matters when scripting.

## `db create`

Purpose:

- create a database explicitly;
- support E2E setup;
- support users who are authorized to create databases.

Not part of the default TigerWrapDb install path.

```text
select administrative connection
-> provide database name
-> validate name
-> confirm
-> create database
-> verify creation
-> optionally tag a new regular connection as disposable
```

Rules:

- the database name is validated against SQL Server identifier rules and rejected if it contains `]`, a null character, or leading/trailing whitespace; it is quoted with `QUOTENAME` on the server side and never concatenated raw;
- `CREATE DATABASE` is issued without file-path options — the earlier `:setvar DefaultDataPath "C:\MsSQL\Data\"` values in the deployment scripts are SSDT artifacts and must not be reused here, since they encode one developer's machine layout;
- the created database inherits `model`'s collation and compatibility level; `db create` reports both, and warns when compatibility level is below 130;
- the command does **not** proceed into TigerWrapDb installation. A composed `create + install` operation may be designed later; conflating them now would smuggle database creation back into the default install path.

## `db drop`

Purpose:

- controlled database cleanup;
- especially E2E test cleanup.

Safeguards, in the order they are evaluated:

1. explicit database name required — never inferred from the connection's `InitialCatalog`;
2. refuse `master`, `model`, `msdb`, `tempdb`, and any database with `database_id <= 4`;
3. refuse the database the administrative connection itself is connected to;
4. require either `TigerWrap:Disposable=true` on a stored connection naming that database, **or** an explicit `--force` flag; without one of these the command fails with an ownership-unclear error;
5. clear target display: server, database, size, and creation date;
6. explicit confirmation; in non-interactive mode, an explicit `--confirm` flag;
7. do not force-disconnect users. `SET SINGLE_USER WITH ROLLBACK IMMEDIATE` is available only behind `--force-disconnect`, and is off by default even though the current test helper uses it unconditionally;
8. fail safely if ownership or intent is unclear.

The first implementation favors safety over convenience. Note that safeguard 4 is a guard rail, not a permission check (see the metadata note above).

## `db sqlcmd`

Purpose:

- execute TigerWrap test/setup SQL files;
- support E2E database population;
- reuse TigerQuery execution;
- expose only the subset TigerWrap needs.

This intentionally overlaps with `tiger-sqlcmd` but has a narrower purpose.

```text
db sqlcmd --connection <name> --mode SqlCmdEx --file PopulateTestDb.sql
```

Characteristics:

- command-line/script oriented;
- excluded from the menu;
- connection may be promptable; file and mode are explicit;
- deterministic exit codes;
- TigerQuery-based execution with prepared mode;
- progress reporting through TigerCli.

Additional options (variables, timeout) are added only when needed and only where TigerQuery already supports them cleanly.

## Prepared execution

TigerQuery prepared execution becomes the preferred model for script-based TigerWrap operations.

Consumers:

- `db install`
- `db upgrade`
- `db sqlcmd`
- script-driven parts of `db create` and `db drop`

Benefits:

- the complete SQLCMD structure is parsed before execution;
- parser failures are detected **before** the connection is opened and therefore before any database mutation;
- logical batch counts are available up front via `ExecutionPlanReady.LogicalBatchCount`;
- scheduled execution totals are available via `TotalExecutionCount`;
- TigerCli can display meaningful progress;
- failure reporting can identify the exact stage and batch.

For a chained upgrade, progress is shown at both chain and batch level:

```text
Preparing upgrade chain
Step 1 of 2: 0.9.0 -> 0.9.1
Batch 47 of 140
Step 2 of 2: 0.9.1 -> 0.9.2
Batch 18 of 93
```

Constraints that prepared execution does **not** remove:

- it does not replace SQL-side guards or transaction logic;
- it parses the script but does not validate SQL semantics — a script that parses can still fail on its first batch;
- **preparing the whole chain before executing any of it is parse-only preparation.** It cannot prove step 2 will succeed, because step 2's preconditions do not exist until step 1 commits. The plan's value is that a missing script, an unreadable file, or a malformed sqlcmd structure anywhere in the chain is discovered before the first mutation — not that the chain is transactional. Documentation and the on-screen plan must not imply otherwise.
- the deployment scripts contain `:on error exit`. Whether TigerQuery honors that directive, and how it interacts with `ContinueOnError = false`, must be confirmed empirically before install and upgrade rely on either. It is currently an untested assumption in a code path whose failure mode is a half-installed database.

## Empty-database protection

The current full-install script assumes an empty database and does not verify it. Its pre-deployment section is inert: `:r .\Script.PreUpgradeVersionCheck.sql` is commented out for full-deploy generation. A full deploy today therefore has **no guard at all**.

0.9.2 adds protection in two places:

1. `db install` preflight (early, readable feedback);
2. the full-install SQL script itself (the final barrier when the script is run directly, when the CLI check is bypassed, or when the database changes between preflight and execution).

### The SQL-side guard is authoritative

The CLI preflight and the SQL guard are not redundant — they close different windows. Between preflight and execution another session can create objects, and users run the packaged script by hand with SSMS. The SQL guard must therefore:

- run **before any TigerWrap object is created**, in the pre-deployment section;
- fail by setting `NOEXEC ON` and printing an actionable message, matching the existing `Script.PreUpgradeVersionCheck.sql` pattern;
- report useful details: object counts and a sample of offending object names.

### Definition of "empty enough"

The CLI and the SQL script use the **same logical definition**, and a test asserts they agree on the same database.

Reject when the database contains any of:

- user tables, views, stored procedures, functions, sequences, synonyms;
- user-defined types or assemblies;
- any TigerWrap-owned schema (`DbInfo`, `Enum`, `Flag`, `Internal`, `Parser`, `ParserEnum`, `Project`, `Static`, `Toolkit`, `View`, `History`).

Do not reject for:

- users, roles, permissions;
- database settings;
- platform-created metadata and system objects;
- the built-in schemas (`dbo`, `guest`, `sys`, `INFORMATION_SCHEMA`, and the fixed database-role schemas).

Also reject when `compatibility_level < 130`, with a message naming the required `ALTER DATABASE` statement.

The canonical predicate is a query over `sys.objects` filtered to `is_ms_shipped = 0`, plus `sys.types WHERE is_user_defined = 1`, plus `sys.assemblies WHERE is_user_defined = 1`, plus `sys.schemas` against the TigerWrap-owned list. It is written once and duplicated deliberately in the two places that need it, with a test proving equivalence — a shared implementation is impossible, since one side is a T-SQL script executed with no TigerWrap objects present.

### The pre-deployment toggle problem

`Scripts/Script.PreDeployment.sql` carries a manual comment toggle: the upgrade-version-check `:r` is commented out for full-deploy generation and uncommented for upgrade generation. Adding a second, mutually exclusive guard doubles the number of ways a release artifact can be generated wrong — and generating the full deploy with the upgrade guard active, or vice versa, produces a script that either refuses every valid target or protects nothing.

**Recommendation:** replace the comment toggle with a single mode-detecting guard that branches at runtime on whether `[DbInfo].[GetName]` exists:

- object absent → this is a full install → assert emptiness and capability;
- object present → this is an upgrade → assert identity and exact source version.

The expected source version stays a per-artifact `:setvar` so the generated upgrade script is still specific to its transition. This removes the manual step entirely and makes both artifacts correct by construction. It is a change to SSDT source and to how release artifacts are generated, so it must be scheduled deliberately and validated by regenerating both artifacts and running them against real databases.

## Upgrade safety philosophy

Upgrade scripts continue to use faithful identity and version checks. They verify:

- expected database identity;
- expected source version;
- expected upgrade path.

They do not attempt to prove that no one has manually modified the schema. TigerWrap assumes the declared version represents the intended schema. Schema-drift detection is a separate problem and is not required for 0.9.2.

One invariant follows from how the version is read: `[DbInfo].[GetCurrentVersion]` and `[Toolkit].[GetDbInfo]` both use `TOP (1) … ORDER BY [Id] DESC` on the append-only `[dbo].[SchemaVersion]` — that is *last inserted*, not *highest version*. Every version-bearing accessor must keep that identical shape, and `ProjectFormatVersion` must be non-decreasing across ascending `[Id]`. This is recorded as Invariant I7 in the import/export design.

## E2E testing foundation

0.9.2 establishes real SQL Server-backed automated testing.

The primitives already exist as private helpers in `ItTiger.TigerWrap.Tests/DbCommandsLiveTests.cs`: `SkipUnlessSqlServerAvailableAsync`, `CreateDatabaseAsync`, `DropDatabaseAsync`, `DeployAsync` via `TigerQueryEngine`, and a temp `SqlServerConnectionStore` built with `NoOpConnectionPasswordProtector`. 0.9.2's job is to **promote them into a reusable harness** and give them a CLI-visible counterpart, not to invent them.

### Harness design

A `SqlServerE2EFixture` (xUnit collection fixture) providing:

- **Availability gate** — one probe of `master`; every test in the collection skips together when the server is absent. Preserves the existing `Assert.Skip` behavior and the `Category=RequiresSqlServer` trait required by `AGENTS.md`.
- **Unique database naming** — `TWE2E_{yyyyMMddHHmmss}_{8-hex}`. The fixed `TWE2E_` prefix is what makes orphan sweeping and `db drop`'s safety check possible; a bare GUID name would be indistinguishable from a user database.
- **Run identity** — one `RunId` per fixture instance, written to `TigerWrap:OwnerTag` on every connection the run creates.
- **Connection minting** — creates temp-store profiles with metadata applied programmatically via `SetMetadata` (the CLI cannot do this; see the capability gap above). Administrative connections target `master`; regular connections target the disposable database. Both carry `TigerWrap:Disposable=true`, `TigerWrap:OwnerTag`, `TigerWrap:CreatedAtUtc`.
- **Deterministic teardown** — see below.
- **Orphan sweep** — at collection teardown, drop databases whose name matches `TWE2E_` and whose `create_date` is older than 6 hours. This bounds the damage of a killed test run without ever touching a database that is not unambiguously ours.

### Cleanup must not hide the original failure

The rule: **cleanup exceptions never propagate over a test failure.**

```text
run the test body
-> on completion (success or failure), attempt cleanup in a finally block
-> if cleanup throws and the test body succeeded  -> fail the test with the cleanup error
-> if cleanup throws and the test body failed     -> report the original failure; attach the
                                                     cleanup error as supplementary output only
```

Concretely: capture the body's exception, wrap cleanup in its own try/catch, and rethrow the captured exception. Never let a `finally` block throw. A leaked database is a nuisance the orphan sweeper handles; a lost stack trace costs a debugging session.

### Test journeys

Install:

```text
create administrative E2E connection (programmatic metadata)
-> db create unique test database
-> create regular disposable connection targeting it
-> db install
-> db info
-> db sqlcmd --mode SqlCmdEx --file PopulateTestDb.sql
-> configure or import projects
-> generate wrappers
-> verify output
-> db drop
-> remove temporary connections
```

Chained upgrade:

```text
db create
-> deploy TigerWrapDb 0.9.0 (packaged FullDeploy artifact)
-> db upgrade
-> verify 0.9.2 version and API level
-> db drop
```

Import/export:

```text
export projects
-> install fresh TigerWrapDb
-> import package
-> export again
-> compare $.projects arrays byte-for-byte
-> db drop
```

Negative journeys are equally required: install into a non-empty database, install into a compatibility-level-120 database, upgrade from an unsupported version, drop refused without disposable metadata, drop refused for a system database.

### SQL Server 2017 coverage

This is the weakest link in the plan and must be resolved by decision, not aspiration. Today:

- the SSDT project targets `Sql150DatabaseSchemaProvider` (SQL Server 2019), so nothing prevents a 2019-only construct from entering the source;
- the local test fixture uses a single instance at `.`, so 2017 is not exercised at all;
- the import/export feature is the first significant JSON consumer, and JSON is precisely where the 2017/2019/2022 differences bite (`JSON_OBJECT`, `JSON_ARRAY`, `JSON_PATH_EXISTS`, and typed `ISJSON` are all post-2017).

Options, in order of preference:

1. **Lower the DSP to `Sql140` and add a 2017 instance to the test matrix.** Makes the claim true and machine-checked.
2. **Lower the DSP to `Sql140` and verify 2017 manually once per release**, documenting it as a manual gate. Cheaper, weaker, still honest.
3. **Drop the SQL Server 2017 claim** and state 2019 as the floor. Least work, but it is a user-visible support reduction and must be a deliberate product decision, not a side effect.

Doing none of these — leaving the DSP at `Sql150` while documenting 2017 support — is the only unacceptable outcome, and it is the current state.

### What belongs in 0.9.2 versus later

| Capability | 0.9.2 | Later |
| --- | --- | --- |
| Availability gate, unique naming, ownership metadata, teardown, orphan sweep | Yes | |
| `db create` / `db drop` / `db install` / `db info` journeys | Yes | |
| Chained upgrade from packaged 0.9.0 and 0.9.1 artifacts | Yes | |
| Export/import round trip against a real database | Yes | |
| Golden package byte-comparison and the compatibility matrix | Yes | |
| Populated application test database via `db sqlcmd` | Yes (a small fixture database is enough) | Rich parser-stress database |
| Generated-code **compilation** | | Yes — needs a compiler harness and a stable expected-output baseline |
| Generated-wrapper **execution** against a live database | | Yes — depends on compilation |
| Multi-version SQL Server matrix in CI | | Yes, unless option 1 above is chosen |
| One-command E2E environment provisioning | | Yes |

Compilation and execution coverage are deferred deliberately: each needs infrastructure of its own, and neither reduces risk for anything else in 0.9.2. Attempting them here would displace the work that does.

## Work streams and dependencies

Five streams. Arrows are hard dependencies.

```text
A. DB lifecycle spine   ──┬──> C. TigerWrapDb 0.9.2 schema ──> D. Import/export
   (roles, prepared         │
    execution, install,     └──> E. Release hardening
    chain resolver,
    E2E harness)

B. Response-code batch  ─────> C, D   (one DB change; must land before C freezes)
```

- **A** depends on nothing in 0.9.2 and unblocks everything. It is the first slice.
- **B** is small but must be batched: every new exit code is a `[Enum].[ToolkitResponseCode]` row plus a wrapper regeneration, so adding them one at a time multiplies DB churn.
- **C** (new tables, new `[Toolkit]` procedures, `ApiLevel` 3, the 0.9.1 → 0.9.2 upgrade script, regenerated full-deploy artifact) cannot start until the `GetDbInfo` freeze decision (D1) is settled, because that decision determines how capability information is exposed.
- **D** depends on **C** entirely.
- **E** depends on all of them.

## Suggested implementation order

### Phase 1 — DB lifecycle spine

- define TigerWrap namespaced connection metadata keys and role semantics;
- add role-filtered connection providers;
- adopt prepared execution for the existing upgrade path;
- establish progress-reporting conventions;
- implement `db create` and `db drop` with safeguards;
- replace `TigerWrapDbStatus` with the upgrade-step catalogue and chain resolver;
- implement `db install` with CLI-side empty-database and capability preflight;
- add the capability probe with graceful fallback for pre-0.9.2 databases;
- promote the E2E helpers into a fixture;
- establish disposable-database naming, ownership, teardown, and orphan sweeping.

This is the [Recommended First Implementation Slice](#recommended-first-implementation-slice).

### Phase 2 — Script tooling and SQL-side guards

- implement `db sqlcmd`;
- convert `Script.PreDeployment.sql` to a mode-detecting guard;
- add the SQL-side empty-database and capability guard;
- prove CLI and SQL emptiness definitions agree;
- confirm `:on error exit` behavior under TigerQuery;
- add the small populated fixture database used by later E2E journeys.

### Phase 3 — Response codes and TigerWrapDb 0.9.2 schema

- add the full batch of new `[Enum].[ToolkitResponseCode]` rows in one change;
- add `[dbo].[Project].[Uid]`;
- add `[dbo].[SchemaVersion].[ProjectFormatVersion]` and `[DbInfo].[GetProjectFormatVersion]`;
- add `[Static].[ProjectFormatElement]` and populate it for format 1;
- add `[Static].[LanguageOption].[IntroducedInProjectFormatVersion]`;
- add the `[History]` schema, `Security/History.sql`, `[Enum].[PackageOperationType]`, and `[History].[ProjectPackage]`;
- add `[Toolkit].[GetDbCapabilities]`;
- raise `ApiLevel`/`MinApiLevel` to 3 in `Script.Version.sql` and `ExpectedDbInfo` together;
- regenerate `ToolkitDbHelper` wrappers;
- author the 0.9.1 → 0.9.2 upgrade script and regenerate the full-deploy artifact;
- fix `[View].[Project]` to include the 0.9.1 description-attribute columns.

### Phase 4 — Project export

- implement `[Toolkit].[ExportProjects]` with the canonical shape, ordering, `INCLUDE_NULL_VALUES`, and checksum;
- implement all-projects and multi-select export in the CLI;
- implement export self-validation including read-back;
- store canonical JSON internally;
- commit the format-1 golden package.

### Phase 5 — Project import

- implement package validation (`[Toolkit].[ValidateProjectPackage]`);
- implement the migration dispatch point;
- implement structural unknown-path and unknown-flag detection;
- implement compatibility analysis and loss analysis;
- implement conflict planning and `[Toolkit].[AnalyseProjectImport]`;
- implement Rename, AutoRename, Skip, Replace, and Fail;
- implement transaction-per-project execution and `[Toolkit].[ImportProject]`;
- implement Replace using import-under-temp-name;
- implement `defaultDatabase` policy handling;
- implement pre-commit logical verification;
- implement partial-success reporting;
- commit synthetic format-2 and format-3 fixtures and prove the compatibility matrix.

### Phase 6 — Chained upgrade completion

- add the 0.9.1 → 0.9.2 step to the catalogue with its expected post-conditions;
- test 0.9.0 → 0.9.2 and 0.9.1 → 0.9.2 end to end;
- verify per-step post-conditions and failure reporting.

### Phase 7 — Release hardening

- expand SQL Server-backed coverage;
- resolve the SQL Server 2017 decision and act on it;
- run installer and WinGet upgrade scenarios;
- update documentation and screenshots;
- verify packaged scripts;
- verify clean install and upgrade from 0.9.1;
- Release build and tests green.

## Risk register

| # | Risk | Impact | Likelihood | Mitigation |
| --- | --- | --- | --- | --- |
| R1 | Extending `[Toolkit].[GetDbInfo]` breaks probing of 0.9.0/0.9.1 databases (SQL error 8144) and destroys `db upgrade` | Critical — headline feature fails for every upgrading user | High if undecided | Freeze the signature; additive `GetDbCapabilities` with 2812 fallback. Decision D1. |
| R2 | SQL Server 2017 claimed but DSP targets 2019 and nothing tests 2017 | High — a 2019-only construct ships and 2017 users cannot install | High | Resolve per [SQL Server 2017 coverage](#sql-server-2017-coverage) before Phase 4 writes significant JSON. |
| R3 | `OPENJSON` unavailable because the target database's compatibility level is below 130 | High — install succeeds, import/export fails later with an obscure error | Medium | Check compatibility level in both `db install` preflight and the SQL guard. |
| R4 | `[Toolkit].[CreateProject]` rejects a non-existent `defaultDatabase`, so cross-environment import fails | High — defeats the feature's primary purpose | Certain if unaddressed | Dedicated import write path with an explicit policy. Decision D5. |
| R5 | Export field set drifts from `[dbo].[Project]`, as `[View].[Project]` already has | High — silent data loss in a feature whose premise is no silent data loss | Medium | Registry-completeness test (Invariant I8); fix `[View].[Project]` in Phase 3. |
| R6 | `FOR JSON` returned as a bare statement is split into 2033-character rows | Medium — corrupt packages that look plausible | High without discipline | Always assign to `NVARCHAR(MAX)` then `SELECT`; covered by round-trip tests on a large package. |
| R7 | Pre-deployment comment toggle produces a wrong release artifact | High — either a full deploy with no guard, or an upgrade that refuses everything | Medium | Mode-detecting guard, Phase 2; regenerate and test both artifacts. |
| R8 | `:on error exit` behavior under TigerQuery is unverified | Medium — a failed batch may not stop a half-installed database | Medium | Empirical confirmation in Phase 2 before install relies on it. |
| R9 | Connection metadata cannot be authored from the CLI in 0.8.2 | Medium — E2E flows and user-facing role tagging are limited | Certain | Programmatic-only in 0.9.2; revisit when TigerQuery surfaces `--metadata`. |
| R10 | `db drop` destroys a real database | Critical | Low with safeguards | Layered safeguards; disposable metadata; `--force` and `--force-disconnect` opt-ins; system-database refusal. |
| R11 | New exit codes each require a DB change plus wrapper regeneration | Medium — churn and mismatched CLI/DB versions | High | Batch all new response codes in one Phase 3 change. |
| R12 | Golden packages committed before the format is settled | Medium — a "durable" format is amended after publication | Medium | Do not commit format-1 goldens until Phase 4 self-validation passes; treat the first tagged release as the freeze point. |
| R13 | Scope creep from the "Beyond 0.9.2" list | Medium — release slips | Medium | Out-of-scope list is normative, not advisory. |
| R14 | Chained upgrade partially completes and leaves an intermediate version | Medium — user confusion, unclear recovery | Medium | Per-step verification, explicit "database is now at version X" reporting, documented restore-from-backup recovery. |

## Test matrix

| Area | Level | Requires SQL Server | Phase |
| --- | --- | --- | --- |
| Connection role metadata keys and filtering | Unit | No | 1 |
| Role-filtered providers reject wrong-role named connections | App | No | 1 |
| Upgrade chain resolution: 0.9.0, 0.9.1, current, unknown, newer | Unit | No | 1 |
| Missing catalogue script fails during planning, before mutation | Unit | No | 1 |
| Prepared-mode batch totals reach the progress display | App | Yes | 1 |
| `db create` name validation and rejection cases | App | Yes | 1 |
| `db drop` refuses: system DB, no disposable metadata, connected DB, missing `--confirm` | App | Yes | 1 |
| `db install` into an empty database succeeds and verifies version/API level | E2E | Yes | 1 |
| `db install` refuses a non-empty database | E2E | Yes | 1 |
| `db install` refuses compatibility level < 130 | E2E | Yes | 1 |
| Capability probe falls back cleanly against 0.9.0 and 0.9.1 databases | E2E | Yes | 1 |
| Orphan sweep drops only `TWE2E_`-prefixed stale databases | E2E | Yes | 1 |
| Cleanup failure does not mask the original test failure | Unit | No | 1 |
| SQL-side guard refuses a non-empty database when run directly | E2E | Yes | 2 |
| CLI and SQL emptiness definitions agree on the same database | E2E | Yes | 2 |
| `db sqlcmd` executes a file and reports deterministic exit codes | E2E | Yes | 2 |
| `:on error exit` stops execution as expected | E2E | Yes | 2 |
| API level 3 rejects 0.9.1 CLI; 0.9.2 CLI rejects API level 2 | E2E | Yes | 3 |
| Export field registry completeness vs `[dbo].[Project]` columns | E2E | Yes | 3 |
| Export determinism across repeated runs | E2E | Yes | 4 |
| Export determinism across CI/CS/AS collations | E2E | Yes | 4 |
| Export self-validation and read-back failure handling | E2E | Yes | 4 |
| Large-package `FOR JSON` chunking regression | E2E | Yes | 4 |
| Round trip preserves `$.projects` byte-for-byte | E2E | Yes | 4 |
| Malformed package rejection: envelope, checksum, duplicate keys, duplicate names, missing path, oversize, deep nesting | E2E | Yes | 5 |
| Compatibility matrix cells (1,1), (1,2), (1,3) | E2E | Yes | 5 |
| Undeclared unknown element rejects the package | E2E | Yes | 5 |
| `Structural` loss cannot be confirmed away | E2E | Yes | 5 |
| Analysis mutates nothing (before/after table comparison) | E2E | Yes | 5 |
| Each conflict action: Rename, AutoRename, Skip, Replace, Fail | E2E | Yes | 5 |
| Replace preserves the original at each of its seven steps | E2E | Yes | 5 |
| No `~twimport_` project survives a forced Replace failure | E2E | Yes | 5 |
| Partial success reporting and non-zero exit code | E2E | Yes | 5 |
| `defaultDatabase` policies: keep, clear, fail, map | E2E | Yes | 5 |
| Chained 0.9.0 → 0.9.2 and 0.9.1 → 0.9.2 | E2E | Yes | 6 |
| Per-step verification failure stops the chain and reports actual version | E2E | Yes | 6 |
| Installer packages every catalogue script | Build | No | 7 |
| SQL Server 2017 compatibility (per the chosen option) | E2E | Yes, 2017 instance | 7 |

## Documentation goals for 0.9.2

Documentation must clearly explain:

- TigerWrap CLI and TigerWrapDb are separate components;
- `db install` targets an existing empty database;
- database creation is explicit and not the default;
- the compatibility-level 130 requirement and how to fix it;
- project export/import is the portability and recovery mechanism;
- import conflict behavior and the `defaultDatabase` policy;
- database upgrade chains, and that a failed step is recovered by restoring a backup rather than by re-running;
- backup requirements;
- that connection metadata is a guard rail, not a permission;
- that snapshots grow unboundedly and how to prune them;
- that the package checksum is an integrity check, not a signature;
- that project-name conflict detection follows the target database's collation;
- WinGet installation and update, and that GitHub releases may appear before WinGet updates;
- menu-driven workflows and script-oriented commands.

Screenshots: main menu; DB info; DB install; DB upgrade plan and progress; project export selection; import conflict plan; import result.

## Release acceptance criteria

0.9.2 is not released until:

- project export works for all and selected projects;
- export validates itself, including read-back, and is byte-deterministic;
- project import supports the documented conflict actions;
- Replace preserves the original project on failure at every step;
- import uses one transaction per project;
- all earlier project formats are importable, and the compatibility matrix passes for cells (1,1), (1,2), (1,3);
- one-step-forward import is tested with synthetic newer-format fixtures;
- actual lossy fields and flags are reported per project, with severity and resulting default;
- an undeclared unknown element rejects the package;
- import succeeds into an environment where the recorded `defaultDatabase` does not exist;
- `db install` refuses occupied databases and sub-130 compatibility levels before mutation;
- the full-install script independently refuses occupied databases when run directly;
- chained upgrades work from 0.9.0 and 0.9.1, with per-step verification;
- the 0.9.2 CLI can still probe and upgrade 0.9.0 and 0.9.1 databases (Invariant I1 holds in practice, not only on paper);
- prepared execution is used for all SQL script workflows;
- progress reporting shows batch N of M;
- `db drop` refuses every documented unsafe case;
- E2E tests create and clean up disposable databases, and cleanup failures never mask test failures;
- the SQL Server 2017 decision is resolved and the repository state matches the documented claim;
- `[View].[Project]` matches `[dbo].[Project]`;
- Release build and tests are green;
- packaged installer scripts are verified, including every upgrade-catalogue script.

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
- one-command E2E environment provisioning;
- a composed `db create + install` operation;
- user-facing connection metadata authoring, once TigerQuery surfaces it.

These must not expand the 0.9.2 scope.

## Core design principles

1. Database creation is explicit, not assumed.
2. Normal installation targets an existing empty database.
3. SQL-side guards remain authoritative.
4. Script-oriented commands stay out of the menu.
5. TigerQuery execution and metadata are reused, never re-implemented.
6. Bootstrap and probe surfaces are frozen; capability discovery is additive and failure-tolerant.
7. Import/export is a durable compatibility contract.
8. No silent data loss.
9. No partial project mutation.
10. Replace imports first and deletes later.
11. Real SQL Server testing is part of the release gate.

## Recommended First Implementation Slice

### Slice: the TigerWrapDb lifecycle spine

**One sentence:** make TigerWrap able to create, install into, inspect, chain-upgrade, and dispose of a TigerWrapDb — end to end, on real SQL Server, with prepared execution and role-tagged connections — without changing the TigerWrapDb schema at all.

### Why this and not something else

Three candidates were weighed against the repository as it stands.

- *Project export format v1 first.* Rejected. Export requires new tables, new `[Toolkit]` procedures, and an API-level bump — which requires a 0.9.1 → 0.9.2 upgrade script, which requires chained upgrade, which requires this slice. Starting with export means building the schema before the machinery that delivers and verifies it exists, and every subsequent schema iteration would be tested by hand.
- *Prepared execution plus `db install` alone.* Rejected as too small. It is one command and a mode flag; it leaves `TigerWrapDbStatus`'s hard-coded single step in place, so chained upgrade remains untouched and the riskiest decision in the release (D1) stays unresolved.
- *Connection-role metadata plus E2E primitives alone.* Rejected as not user-visible. It is infrastructure, and the release direction explicitly refuses to be justified by test infrastructure.

The spine is the right size because it is where the release's dependencies converge. It:

- **produces visible architectural progress** — three new commands, a real upgrade framework replacing a class that documents itself as "not a version framework", and genuine batch-level progress;
- **exercises both new TigerQuery capabilities** — prepared execution with `OnExecutionPlanReady`, and `Metadata`/`QueryByMetadata` for connection roles;
- **reduces risk for everything after it** — Decision D1 is settled and *proven* against real 0.9.0 and 0.9.1 databases before any schema change depends on it, and every later phase inherits a working install/upgrade/dispose loop;
- **avoids prematurely implementing import/export** — it touches no project table and adds no `[Toolkit]` procedure;
- **is independently testable** — the packaged 0.9.0 and 0.9.1 full-deploy artifacts are already in the repository, so every journey can run today;
- **leaves the repository coherent** — `db create`, `db drop`, and `db install` are shippable user features on their own; if 0.9.2 were cut short here, what exists is a complete, honest increment.

### Exact boundaries

**In scope**

1. `ItTiger.TigerWrap.Core`: a `TigerWrapConnectionMetadata` static class fixing the four metadata keys and their exact literal spellings, plus role read/write/filter helpers over `SqlServerConnectionProfile` and `SqlServerConnectionStore.QueryByMetadata`.
2. `Commands/Db`: replace `TigerWrapDbStatus` and `UpgradeSourceVersion` with an upgrade-step catalogue (`from`, `to`, `scriptFileName`, expected `version`/`apiLevel`/`minApiLevel`) and a pure, unit-testable chain resolver. The catalogue contains the two existing steps only.
3. `Commands/Db`: a shared script-execution helper that runs a TigerQuery script in `TigerQueryExecutionMode.Prepared`, wires `OnExecutionPlanReady` into a batch-N-of-M activity display, and is used by both install and upgrade.
4. `DbUpgradeCommand`: migrate to the catalogue, chain resolver, prepared execution, per-step verification, and per-step failure reporting that names the version the database is now at.
5. `DbInstallCommand` (new, menu-visible): connection role check, CLI-side emptiness and compatibility-level preflight, plan display, confirmation, prepared execution of the packaged full-deploy artifact with `DatabaseName` variable injection, post-install verification.
6. `DbCreateCommand`, `DbDropCommand` (new, menu-excluded): as specified in [`db create`](#db-create) and [`db drop`](#db-drop).
7. `DbCommandSupport`: a capability probe that calls `[Toolkit].[GetDbCapabilities]` and treats SQL error 2812 as "pre-0.9.2 database", using the existing `ProbeAsync` fallback pattern. The procedure does not exist yet; the fallback path is the entire point and is fully testable today against 0.9.0 and 0.9.1 databases.
8. Role-filtered connection providers registered in `TigerWrapApp`.
9. `ItTiger.TigerWrap.Tests`: promote the `DbCommandsLiveTests` helpers into a `SqlServerE2EFixture` with unique naming, ownership metadata, safe teardown, and orphan sweeping; migrate the existing upgrade journey test onto it.

**Explicitly not in scope**

- Any change to `TigerWrapDb/` source SQL, deployment scripts, static data, or `Script.Version.sql`.
- Any change to `[Enum].[ToolkitResponseCode]` or regeneration of `ToolkitDbHelper`. Codes this slice needs that do not exist yet reuse the closest existing code and are noted for the Phase 3 batch.
- The SQL-side empty-database guard and the pre-deployment mode-detecting guard (Phase 2). This slice's emptiness protection is CLI-side only, and that limitation is stated in the command's own output.
- `db sqlcmd` (Phase 2).
- Any project export, import, snapshot, or format work.
- `ApiLevel` changes.
- Documentation rewrites beyond command help text.

**Boundary note on `db install`.** Because this slice changes no SQL, the only full-deploy artifact available is `TigerWrapDb_FullDeploy_v_0.9.1.sql`, which has no internal guard. `db install` is therefore tested by installing 0.9.1 into an empty database, and its preflight is the only emptiness protection until Phase 2. This is a deliberate, temporary asymmetry and must be recorded in the command's help text, not silently accepted.

### Acceptance criteria for the slice

The slice is done when all of the following hold, verified against a real local SQL Server:

1. `db create` creates a database from an administrative connection, rejects invalid names, refuses a regular-role connection, and reports the created database's collation and compatibility level.
2. `db drop` refuses: a system database; a database with no disposable-tagged connection and no `--force`; the database its own connection targets; a non-interactive run without `--confirm`. It succeeds for a disposable-tagged database and does not force-disconnect unless `--force-disconnect` is supplied.
3. `db install` installs 0.9.1 into an empty database and verifies the resulting version and API level.
4. `db install` refuses a database containing any user object, naming counts and sample objects.
5. `db install` refuses a database whose compatibility level is below 130, naming the required `ALTER DATABASE` statement.
6. `db install` refuses an `Administrative`-role connection.
7. `db upgrade` resolves and executes a chain, verifying `(version, apiLevel, minApiLevel)` after each step. With the current catalogue the resolved chain from 0.9.0 has one step; the resolver's multi-step behavior is proven by unit tests over a synthetic three-step catalogue.
8. `db upgrade` fails during planning — before any mutation — when a catalogue script is missing.
9. A step whose post-conditions do not match stops the chain and reports the database's actual version.
10. Both install and upgrade run in `Prepared` mode and display "batch N of M", with N and M sourced from `ExecutionPlanReady` / `BatchEnd`.
11. A deliberately malformed script fails during preparation, with no connection opened and no database mutation — asserted, not assumed.
12. The capability probe returns "pre-0.9.2" against real 0.9.0 and 0.9.1 databases without throwing, and `db info` renders correctly for both.
13. Connections with no metadata behave exactly as `Regular`; no existing `connections.json` requires migration, and `ConnectionCompatibilityTests` still passes unchanged.
14. Every E2E database created by the suite is named `TWE2E_*`, is dropped on success, and is swept on a subsequent run if leaked.
15. A test whose body fails and whose cleanup also fails reports the body's failure, with the cleanup error as supplementary output only.
16. `dotnet build` in Release is warning-clean and `dotnet test` is green with and without a local SQL Server.

## Next-Agent Implementation Brief

A self-contained specification for the slice above. Implement exactly this; do not begin import/export.

### Objective

Deliver the TigerWrapDb lifecycle spine: `db create`, `db drop`, `db install`, a chained `db upgrade`, connection-role metadata, prepared execution with real batch progress, a failure-tolerant capability probe, and a reusable SQL Server E2E fixture — **with zero changes to `TigerWrapDb/`**.

### Files and areas likely affected

Create:

- `ItTiger.TigerWrap.Core/TigerWrapConnectionMetadata.cs`
- `ItTiger.TigerWrap.Cli/Commands/Db/UpgradeStepCatalogue.cs`
- `ItTiger.TigerWrap.Cli/Commands/Db/UpgradeChainResolver.cs`
- `ItTiger.TigerWrap.Cli/Commands/Db/ScriptRunner.cs`
- `ItTiger.TigerWrap.Cli/Commands/Db/DatabaseEmptinessCheck.cs`
- `ItTiger.TigerWrap.Cli/Commands/Db/DbInstallCommand.cs`
- `ItTiger.TigerWrap.Cli/Commands/Db/DbCreateCommand.cs`
- `ItTiger.TigerWrap.Cli/Commands/Db/DbDropCommand.cs`
- `ItTiger.TigerWrap.Tests/SqlServerE2EFixture.cs`
- `ItTiger.TigerWrap.Tests/DbLifecycleLiveTests.cs`
- `ItTiger.TigerWrap.Tests/UpgradeChainResolverTests.cs`

Modify:

- `ItTiger.TigerWrap.Cli/TigerWrapApp.cs` — register the three new commands, apply `CommandMenuMode.Disabled` to `create`/`drop`, add role-filtered providers, and remove the hard-coded upgrade source version from the `db upgrade` description.
- `ItTiger.TigerWrap.Cli/Commands/Db/DbCommandSupport.cs` — delete `TigerWrapDbStatus` and `UpgradeSourceVersion`; add the capability probe with 2812 fallback; keep `ProbeAsync` and `GetDefaultSqlFolder` intact.
- `ItTiger.TigerWrap.Cli/Commands/Db/DbUpgradeCommand.cs` — chain execution, prepared mode, per-step verification.
- `ItTiger.TigerWrap.Cli/Commands/Db/DbInfoCommand.cs` — render capability information when available.
- `ItTiger.TigerWrap.Tests/DbCommandsLiveTests.cs` — migrate onto the fixture.
- `ItTiger.TigerWrap.Cli/Properties/Resources.resx` — new user-facing strings.

Do not touch: anything under `TigerWrapDb/`, `ItTiger.TigerWrap.Core/ToolkitDbHelper.*.cs` (generated), `Version.props`, `ExpectedDbInfo.cs` (unchanged in this slice), or `ItTiger.TigerWrap.Installer/`.

### Public behavior

```text
tiger-wrap db create   <connection> --name <db> [--confirm]
tiger-wrap db drop     <connection> --name <db> [--confirm] [--force] [--force-disconnect]
tiger-wrap db install  <connection> [--sql-folder <path>] [--confirm]
tiger-wrap db upgrade  <connection> [--backup-confirmed] [--sql-folder <path>]
tiger-wrap db info     <connection>
```

- `create` and `drop` are excluded from the menu; `info`, `install`, and `upgrade` are menu-visible.
- All five accept `--non-interactive`, in which every confirmation must be supplied as a flag or the command exits with `CliInteractiveNotAllowed`, matching `DbUpgradeCommand`'s existing behavior.
- `db upgrade` prints the full resolved chain before requesting the single backup confirmation.

### Architecture

- **Chain resolution is pure.** `UpgradeChainResolver` takes a catalogue and a current version and returns an ordered step list or a typed failure (`AlreadyCurrent`, `NoPathFrom`, `NewerThanTool`, `NotTigerWrapDb`, `MissingScript`). No I/O, no database, no console. Every branch is unit-tested against a synthetic multi-step catalogue, which is how multi-step behavior is proven while only two real scripts exist.
- **Script execution is shared.** `ScriptRunner` owns `TigerQueryEngineOptions` construction: `ExecutionMode = Prepared`, `Mode = SqlCmdMode.SqlCmdEx`, `ContinueOnError = false`, `Variables["DatabaseName"] = <actual database>` (injected variables override the script's own `:setvar`, which is what lets a TigerWrapDb live under a non-default name), `OnExecutionPlanReady` capturing `LogicalBatchCount`, and `OnBatchEnd`/`OnMessage` driving the activity display. Reuse `DbUpgradeCommand`'s existing `UpgradeProgress` and `ActivityDialogSpec` patterns rather than inventing new ones.
- **Preparation is per step, immediately before that step executes.** Verifying the whole chain up front means confirming every script *file* exists and is readable during planning; it does not mean parsing all of them before the first executes. Do not claim more than that in the UI.
- **The capability probe never throws for absence.** `TryGetCapabilitiesAsync` returns `null` on SQL error 2812 and on a missing-column shape, exactly as `ProbeAsync` already handles 2812 for `GetDbInfo`. `null` means "pre-0.9.2 database" and is a normal, expected result.
- **Emptiness is one predicate in one place.** `DatabaseEmptinessCheck` issues a single query returning user-object counts by type, a small sample of names, and the compatibility level. Write it so the T-SQL text can be lifted verbatim into the Phase 2 SQL-side guard.
- **Metadata literals are constants.** All four keys live in `TigerWrapConnectionMetadata` and are never case-folded, trimmed, or reconstructed by string interpolation.

### Safety constraints

- Never concatenate a database name into SQL. `db create` and `db drop` pass the name as a parameter and quote it server-side with `QUOTENAME`.
- `db drop` evaluates its safeguards in the documented order and fails closed on the first unmet one.
- Absent metadata always resolves to `Regular`. No existing connection may break.
- `db install` must not run against a database that is not empty, is below compatibility level 130, or is reached through an `Administrative` connection.
- The upgrade chain stops at the first failed step and reports the database's actual version rather than a presumed one.
- No test may drop a database whose name does not start with `TWE2E_`.
- Cleanup code never throws over a test failure.

### Tests

Unit (no SQL Server): chain resolution across every catalogue and current-version combination, including a synthetic three-step catalogue; missing-script detection; metadata key round-tripping and absent-means-Regular; database-name validation; the cleanup-does-not-mask-failure helper.

E2E (`Category=RequiresSqlServer`, skip when absent): every numbered acceptance criterion above. Reuse `TigerCliAppTestHost` and the existing `[Collection("TigerCli app tests")]` convention.

### Explicit non-goals

- No SQL source, deployment-script, or static-data changes.
- No new `[Enum].[ToolkitResponseCode]` rows and no wrapper regeneration.
- No `db sqlcmd`.
- No SQL-side empty-database guard.
- No project export, import, snapshot, format, or `Uid` work.
- No `ApiLevel` or `Version.props` change.
- No attempt to make `db install` create a database.

### Completion criteria

All sixteen slice acceptance criteria pass; `dotnet build -c Release` is warning-clean; `dotnet test` is green both with and without a local SQL Server; no file under `TigerWrapDb/` is modified; and `git diff --check` is clean.
