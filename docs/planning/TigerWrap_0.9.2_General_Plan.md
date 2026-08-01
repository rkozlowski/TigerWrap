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

TigerQuery 0.8.2 adds capabilities this release builds on. The statements below were verified against
the implementation and tests at TigerQuery tag `v0.8.2`, not inferred from documentation.

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

**Managed connection stores.**

- `SqlServerConnectionStoreOptions.Shared(...)` and `AppSpecific(...)` resolve platform-specific
  per-user paths; an arbitrary JSON path is already supported through `FilePath`.
- `SqlServerConnectionStore` already supplies `Load`, `Find`, `Exists`, `Add`, `AddOrUpdate`,
  `Delete`, `Save`, and `QueryByMetadata`. Names and metadata comparisons are ordinal and
  case-sensitive. `Add` rejects an exact duplicate name; `AddOrUpdate` is intentionally an upsert.
- Profiles contain the complete first-class connection surface plus the case-insensitive `Options`
  escape hatch. `Database` maps to `SqlConnectionStringBuilder.InitialCatalog`, so a detached
  profile can target a different database without rebuilding a raw connection string.
- Metadata is persisted as opaque string data, is excluded from generated connection strings, and
  survives add/edit/update unless a selected key is explicitly changed or removed. The reusable
  `connection add`/`edit` commands expose `--metadata` and `--remove-metadata`; `connection list`
  exposes equals/is-set/is-not-set filters. The earlier claim that metadata is programmatic-only was
  incorrect for the verified `v0.8.2` source.
- The default Windows protector is current-user DPAPI. A loaded SQL-password profile contains both
  its persisted `EncryptedPassword`/`PasswordEncryption` fields and, when decryption succeeds, an
  in-memory `PlainPassword`. Edit preserves an existing protected blob when plaintext is unavailable.
- `SqlServerConnectionCommands.Configure` takes a host-created store through
  `SqlServerConnectionCommandOptions.Store`. TigerWrap already passes the same store to its
  providers and command constructors. This injection point, rather than a TigerCli change, is the
  correct place to enforce one selected store for an application run.

### Verified TigerQuery prerequisite gaps

1. **There is no first-class managed-connection copy operation.** TigerWrap must not reconstruct a
   connection string or manually duplicate profile properties. A generic same-store copy is needed
   so future profile fields are preserved automatically and protected credentials are copied without
   exposing or recreating plaintext.
2. **The current load/mutate/save path cannot promise ciphertext-preserving copy semantics.** `Load`
   unprotects profiles and `Save` invokes `ProtectForSave` on every supplied profile. On Windows that
   can re-encrypt every loaded SQL password, including unrelated profiles. The copy operation needs
   a persistence-safe path that clones the stored protected representation and does not depend on
   `PlainPassword`.
3. **Store mutations are neither synchronized nor atomic.** Every mutation loads the complete file
   and writes it with `File.WriteAllText`; the class documentation explicitly makes callers
   coordinate concurrent access. Concurrent test processes or a CLI/test overlap can lose updates,
   and an interrupted write can corrupt the store. This must be corrected before the default user
   store is used by E2E automation.
4. **Store selection exists at the Core API level but not as one reusable application-run contract.**
   TigerQuery deliberately does not define a universal default: `tiger-sqlcmd` selects a shared
   vendor store while TigerWrap selects an app-specific store. The host must choose default versus
   explicit `FilePath` once, construct one store, and inject it everywhere. TigerQuery must document
   and test this composition; it must not add a TigerWrap-specific option or fallback behavior.
5. **Prepared SqlCmdEx execution mishandles `:on error exit`.** See [Prepared execution](#prepared-execution).
6. **`SqlServerConnectionValidationPolicy` has only `DatabaseOptional` and `DatabaseRequired`, and
   TigerWrap sets `DatabaseRequired` group-wide.** The permanent E2E bootstrap therefore targets
   `master`; no database-less-profile exception or TigerCli change is required.

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

**Status: implemented.** `db install` is registered menu-visible in the `db` group, runs the CLI
preflight, executes the packaged full-install artifact in prepared mode with batch-level progress,
and verifies the resulting version and API level. The authoritative SQL-side guard
(`TigerWrapDb/Scripts/Script.PreInstallEmptyCheck.sql`) is in the SSDT source and expanded into the
newly generated `TigerWrapDb_FullDeploy_v_0.9.2.sql`. Connection-role filtering is **not** part of
this increment: `db install` accepts any saved connection, because the role metadata belongs to the
(still outstanding) `db create`/`db drop` work.

**Versioning.** Adding the guard changes what a full install produces, so it is a TigerWrapDb
change and gets its own version: `Script.Version.sql` moves to `0.9.2` (API level unchanged at 2 —
no schema object changed) and `ExpectedDbInfo.CurrentSchemaVersion` tracks it. The released
`TigerWrapDb_FullDeploy_v_0.9.1.sql` stays byte-for-byte as shipped and is *not* retro-fitted with
the guard; `ReleasedArtifactTests` compares every released artifact against its blob in `git HEAD`
so an in-place edit fails the suite. Because 0.9.2 and 0.9.1 contain the same schema objects at the
same API level, there is no `0.9.1 -> 0.9.2` upgrade script and a 0.9.1 database needs none;
`db upgrade` therefore still targets `DbCommandSupport.UpgradeTargetVersion` (`0.9.1`) and its
`0.9.0 -> 0.9.1` path is unchanged. Generalizing that to a chain stays with the chained-upgrade
increment.

Exit codes: a refused install returns `InvalidDatabase` (17). The dedicated `DatabaseNotEmpty` code
is an `[Enum].[ToolkitResponseCode]` row and therefore requires a TigerWrapDb change plus a wrapper
regeneration — it stays in the batched response-code change, and `db install` moves onto it then.
No wrapper regeneration was needed for this increment: `[Toolkit].[GetDbInfo]` and its four-output
contract are untouched.

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
- **`E2E` is not a `TigerWrap:ConnectionRole` value.** `Regular` / `Administrative` describes
  user-facing DB-command eligibility. The separate `TigerWrap:E2E:Role` lifecycle axis uses
  `Bootstrap` / `TestDatabase`; the permanent bootstrap is explicitly non-disposable and only the
  temporary database connection is disposable. Do not collapse these independent axes.
- Metadata is **not** a security boundary. It is a guard rail that prevents mistakes, not privilege. A user who edits `connections.json` can set anything. Documentation must say so; permissions remain the server's job.
- TigerWrap does not require or automatically create a separate connection store. Everything goes
  through the one default or explicitly selected `SqlServerConnectionStore`.

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
- the deployment scripts contain `:on error exit`, and TigerQuery currently does **not** honour it
  correctly. With `ExecutionMode = Prepared`, `Mode = SqlCmdEx`, and a severity-16 SQL error, the
  diagnostic reaches `OnMessage`, but later batches can execute, `ResultCode` can remain `Success`,
  and `FailedBatches` can remain zero. The current TigerWrap `ScriptRunner.Errors > 0` check detects
  the bad final state but is only a backstop; it does not restore stop-on-error semantics and is not
  an acceptable architectural workaround.

The strongest implementation evidence identifies a coordinator defect rather than a parser or plan
defect:

1. `SqlCmdParser` correctly changes `QueryExecutionContext.ContinueOnError` for `:ON ERROR IGNORE`
   and `:ON ERROR EXIT`.
2. `PrepareExecutionPlanAsync` correctly captures that Boolean on each `ExecutionBatch`, and tests
   prove alternating policies are retained.
3. `ConfigureConnection` sets `SqlConnection.FireInfoMessageEventOnUserErrors = true`. Consequently,
   provider user errors, including the confirmed severity-16 case, can arrive through `InfoMessage`.
4. The `InfoMessage` handler only calls `LogAndRaise`; it does not mark the active batch failed or
   signal the scheduler to stop.
5. `ExecuteBatchesAsync` increments `FailedBatches`, sets `BatchEnd.Success = false`, and applies
   `ContinueOnError` only in exception catch paths. If `ExecuteReaderAsync` completes after an error
   was delivered as an info-message event, the coordinator increments `ExecutedBatches` and reports
   success.

TigerQuery must make server error diagnostics part of the active batch outcome, without double
counting diagnostics also present on a thrown `SqlException`. Under `:on error exit`, the triggering
batch ends once as failed, later scheduled executions do not start, the result is non-success, and
the original SQL diagnostic remains observable. Under `:on error ignore` (or an effective
continue-on-error option), the batch is still counted as failed but later batches run. Prepared and
streaming modes must share the same coordinator semantics and coherent `BatchStart`, `OnMessage`,
`BatchEnd`, plan/progress counts, and final aggregation. This correction is a TigerQuery release gate
for TigerWrap E2E integration.

## Empty-database protection

**Status: implemented.** Both layers exist and are covered by SQL Server-backed tests.

Before this change the full-install script assumed an empty database and did not verify it: its
pre-deployment section was inert, because `:r .\Script.PreUpgradeVersionCheck.sql` is commented out
for full-deploy generation, so a full deploy had **no guard at all**.

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

**As implemented**, the shared text lives in `DatabaseEmptinessCheck.ConflictQuery` and in
`Script.PreInstallEmptyCheck.sql`; `InstallGuardArtifactTests` asserts the two are textually
identical (and that the full-deploy artifact embeds the same text), and
`DbInstallLiveTests.CliPreflightAndSqlGuard_AgreeOnTheSameDatabase` asserts they classify the same
database identically.

Two corrections to the predicate came out of implementation, both verified against SQL Server 2022:

- **Table types are not `sys.objects` rows with `is_ms_shipped = 0`.** A `CREATE TYPE … AS TABLE`
  produces a `TT` row that is flagged as MS-shipped, so filtering `sys.objects` by type would miss
  it entirely. Table types are therefore caught by `sys.types WHERE is_user_defined = 1`, which
  covers both alias and table types, and `'TT'` is deliberately absent from the `sys.objects` type
  list.
- **The guard must set `QUOTED_IDENTIFIER ON` itself.** Its diagnostics use
  `FOR XML PATH(…).value(…)`, which fails with error 1934 under sqlcmd's default
  `QUOTED_IDENTIFIER OFF`. The generated artifact sets it at the top, but a hand-run of the
  standalone script does not, so the guard sets it in its own batch.

### The pre-deployment toggle problem

`Scripts/Script.PreDeployment.sql` carries a manual comment toggle: the upgrade-version-check `:r` is commented out for full-deploy generation and uncommented for upgrade generation. Adding a second, mutually exclusive guard doubles the number of ways a release artifact can be generated wrong — and generating the full deploy with the upgrade guard active, or vice versa, produces a script that either refuses every valid target or protects nothing.

**Recommendation:** replace the comment toggle with a single mode-detecting guard that branches at runtime on whether `[DbInfo].[GetName]` exists:

- object absent → this is a full install → assert emptiness and capability;
- object present → this is an upgrade → assert identity and exact source version.

The expected source version stays a per-artifact `:setvar` so the generated upgrade script is still specific to its transition. This removes the manual step entirely and makes both artifacts correct by construction. It is a change to SSDT source and to how release artifacts are generated, so it must be scheduled deliberately and validated by regenerating both artifacts and running them against real databases.

**Status: not adopted in the install increment; the toggle now has two arms instead of one.**
Runtime mode detection cannot in fact be based on `[DbInfo].[GetName]`: a full install into a
database that *already* contains TigerWrap objects would detect "upgrade" and skip the emptiness
assertion, which is exactly the case the guard has to reject. Making detection artifact-based
instead requires a `:setvar`, which is the same manual step under another name.

What shipped instead: `Script.PreDeployment.sql` documents the two mutually exclusive includes
explicitly, and the risk is closed by verification rather than by construction —
`InstallGuardArtifactTests` asserts that the packaged full deploy contains the install guard, that
the guard's `SET NOEXEC ON` precedes the first `CREATE SCHEMA`, and that the upgrade version check
is *not* active in it. `BuildInstaller.ps1` fails the installer build if the packaged artifact does
not contain the guard. R7 is therefore mitigated by test and by build gate, not eliminated; the
mode-detecting rewrite remains open if a better detection mechanism is found.

## Upgrade safety philosophy

Upgrade scripts continue to use faithful identity and version checks. They verify:

- expected database identity;
- expected source version;
- expected upgrade path.

They do not attempt to prove that no one has manually modified the schema. TigerWrap assumes the declared version represents the intended schema. Schema-drift detection is a separate problem and is not required for 0.9.2.

One invariant follows from how the version is read: `[DbInfo].[GetCurrentVersion]` and `[Toolkit].[GetDbInfo]` both use `TOP (1) … ORDER BY [Id] DESC` on the append-only `[dbo].[SchemaVersion]` — that is *last inserted*, not *highest version*. Every version-bearing accessor must keep that identical shape, and `ProjectFormatVersion` must be non-decreasing across ascending `[Id]`. This is recorded as Invariant I7 in the import/export design.

## E2E testing foundation

0.9.2 establishes real SQL Server-backed automated testing through TigerQuery-managed connections.
The current `SqlServerTestDatabase` is useful evidence for database naming, deployment, and
best-effort cleanup, but its hard-coded `Data Source=.` raw connection strings, inferred local
instance, temporary no-op-protected store, broad age-based orphan sweep, and direct profile
reconstruction are explicitly replaced by this architecture.

### Permanent bootstrap connection contract

A human creates exactly one permanent managed connection in the selected TigerQuery JSON store:

| Property | Required value |
| --- | --- |
| Name | `TigerWrap-E2E-Test` |
| Database / initial catalog | `master` |
| `TigerWrap:E2E:Type` | `TW-E2E-TEST` |
| `TigerWrap:E2E:Role` | `Bootstrap` |
| `TigerWrap:E2E:Disposable` | `false` |

It may use Windows authentication or SQL authentication. A SQL password is stored only through
TigerQuery's existing current-user DPAPI mechanism. The profile's existence is the explicit human
authorization to run destructive TigerWrap E2E activity against that one SQL Server instance.

The suite never creates, edits, deletes, replaces, or repairs this connection. It never selects a
different connection, reads a raw connection string from an environment variable, or infers a
server from `localhost`, `.`, LocalDB, source code, or machine defaults. A missing or invalid
bootstrap causes an explicit skip/failure according to the test-run policy; it never causes fallback.

Before creating anything, the harness finds the profile by exact name and verifies all five values,
including exact metadata casing, then resolves and opens it to prove the `master` target is reachable.
Metadata is a safety/ownership guard rail, not an authorization boundary beyond the deliberate human
act of provisioning this profile; SQL Server permissions remain authoritative.

### Default and optional connection stores

The normal E2E path uses TigerWrap's existing default TigerQuery store, currently selected by
`ToolkitHelper.CreateDefaultConnectionStoreOptions()` with
`SqlServerConnectionStoreOptions.AppSpecific("ItTiger.net", "TigerWrap")`. A dedicated E2E store is
optional, not required.

For isolation, CI, or an advanced local setup, the caller may explicitly select another JSON path.
TigerQuery Core already accepts `SqlServerConnectionStoreOptions.FilePath`; the clean integration fit
is for TigerWrap to resolve its application-level configuration once, create one
`SqlServerConnectionStore`, and pass that same instance to `TigerWrapApp.Build`,
`SqlServerConnectionCommands.Configure`, providers, commands, and the E2E fixture. Do not add a
TigerWrap-domain global option to TigerCli, and do not add TigerWrap concepts to TigerQuery. The
eventual TigerWrap-facing configuration name and CLI spelling are intentionally not fixed here.

The alternatives fit the actual composition as follows:

- a TigerQuery command-group option is too narrow because TigerWrap commands and E2E setup also need
  the selected store, and it would be available only after application composition;
- settings inherited only by TigerQuery-provided connection commands have the same split-store flaw;
- a TigerQuery generic service/configuration object can formalize selection but still has to be
  created by the host; and
- **recommended:** a TigerWrap application-level configuration value chooses default versus explicit
  path before `TigerWrapApp.Build`, then the host forwards the resulting generic store instance into
  the existing TigerQuery registration flow and every TigerWrap consumer.

This needs no TigerCli modification and creates no TigerQuery default-store policy.

When an explicit path is selected, lookup, filtering, copy, save/update, and delete all operate on
that store instance. The code must not probe or fall back to the default path when the explicit file
is absent, invalid, or lacks the bootstrap. The TigerQuery copy API is an instance method precisely
so a copy cannot silently cross stores.

### Temporary managed-connection lifecycle

For each E2E run:

1. Select the default store or the one explicitly requested store.
2. Find and validate `TigerWrap-E2E-Test` as the permanent, non-disposable `master` bootstrap.
3. Generate a cryptographically unique run ID, database name
   `TWE2E_{yyyyMMddHHmmss}_{random}`, and temporary connection name.
4. Through the bootstrap, create the database using a parameter and server-side `QUOTENAME`.
5. Through TigerQuery's first-class copy operation, copy `TigerWrap-E2E-Test` in the same store.
   Preserve server/instance, authentication, username, protected password material, encryption,
   certificate trust, timeouts, pooling, free-form options, unrelated metadata, and all future generic
   profile fields. Override only the name, database/initial catalog, and the following TigerWrap-owned
   metadata:

   | Key | Temporary value |
   | --- | --- |
   | `TigerWrap:E2E:Type` | `TW-E2E-TEST` |
   | `TigerWrap:E2E:Role` | `TestDatabase` |
   | `TigerWrap:E2E:Disposable` | `true` |
   | `TigerWrap:E2E:ParentConnection` | `TigerWrap-E2E-Test` |
   | `TigerWrap:E2E:RunId` | current run ID |
   | `TigerWrap:E2E:DatabaseName` | exact disposable database name |

6. Resolve the temporary connection by name from the same store and run every database-specific
   TigerWrap command/test through it. TigerWrap never reconstructs a raw connection string.
7. In cleanup, delete the temporary managed connection through the same TigerQuery store, then drop
   the database through the permanent bootstrap. Never delete or alter the bootstrap.

Track `databaseCreated` and `temporaryConnectionCreated` independently as soon as each operation
succeeds. This allows cleanup after failures between the two creations and avoids pretending that
one resource implies the other.

### Cleanup safeguards and failure reporting

A database is eligible for cleanup only when every check passes:

- its name starts with `TWE2E_` using ordinal comparison;
- it is not `master`, `tempdb`, `model`, `msdb`, or another system database;
- its name and ownership metadata match the current run, or it matches a separately recorded
  disposable ownership record;
- the drop is issued through the validated `TigerWrap-E2E-Test` bootstrap from the selected store.

Cleanup always attempts each applicable operation independently, in this order:

```text
delete temporary managed connection from the selected store
-> drop disposable database through the approved bootstrap
-> report each cleanup failure and every orphaned connection/database prominently
```

The harness captures the original test exception before cleanup. If cleanup also fails, the original
exception remains primary and cleanup errors are supplementary. If the test body succeeds but cleanup
fails, the test fails on cleanup. A process-kill recovery path may enumerate `TWE2E_` databases, but
prefix and age alone are insufficient authority to drop: recorded disposable ownership must also
match, and the approved bootstrap must be used.

### Test journeys

Install, chained upgrade, and import/export journeys share the lifecycle above. Negative journeys
include invalid bootstrap metadata, wrong database, disposable bootstrap, missing explicit-store
bootstrap, duplicate temporary name, copy validation failure, failure between database and connection
creation, install into non-empty or low-compatibility databases, unsupported upgrades, and cleanup
refusal for mismatched ownership or a system database.

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
| Human-provisioned bootstrap validation, unique naming, ownership metadata, safe teardown | Yes | |
| Default TigerWrap store plus optional explicit TigerQuery JSON store | Yes | |
| Same-store temporary managed-connection copy | Yes, after the TigerQuery prerequisite | |
| `db create` / `db drop` / `db install` / `db info` journeys | Yes | |
| Chained upgrade from packaged 0.9.0 and 0.9.1 artifacts | Yes | |
| Export/import round trip against a real database | Yes | |
| Golden package byte-comparison and the compatibility matrix | Yes | |
| Populated application test database via `db sqlcmd` | Yes (a small fixture database is enough) | Rich parser-stress database |
| Generated-code **compilation** | | Yes — needs a compiler harness and a stable expected-output baseline |
| Generated-wrapper **execution** against a live database | | Yes — depends on compilation |
| Multi-version SQL Server matrix in CI | | Yes, unless option 1 above is chosen |
| Automatic bootstrap provisioning | Never | |

Compilation and execution coverage are deferred deliberately: each needs infrastructure of its own, and neither reduces risk for anything else in 0.9.2. Attempting them here would displace the work that does.

## Work streams and dependencies

Six streams. Arrows are hard dependencies.

```text
Q. TigerQuery prerequisite ──> A. Managed-connection E2E integration ──┬──> E. Release hardening
   (copy, store safety,         (bootstrap, temporary connection,         │
    :on error semantics)         lifecycle journeys)                     │
                                                                           │
B. DB lifecycle spine ───────────────> C. TigerWrapDb 0.9.2 schema ──> D. Import/export
Response-code batch ─────────────────> C, D
```

- **Q is the next upstream task and the gate for A.** TigerWrap must consume a released TigerQuery
  implementation; it must not implement profile-copy or error-handling workarounds locally.
- **A** integrates the released generic APIs with the human-managed bootstrap lifecycle. It may
  reuse completed TigerWrap database helpers but starts only after Q passes unit and live tests.
- **B** is the remaining TigerWrap DB-lifecycle work and can proceed independently where it does not
  depend on the managed E2E harness.
- The response-code batch remains one DB change plus wrapper regeneration and must land before **C** freezes.
- **C** (new tables, new `[Toolkit]` procedures, `ApiLevel` 3, the 0.9.1 → 0.9.2 upgrade script,
  regenerated full-deploy artifact) still precedes **D**.
- **E** depends on Q, A, B, C, and D.

## Suggested implementation order

### Phase 0 — TigerQuery prerequisite release

- implement the generic same-store managed-connection copy API and options;
- preserve stored protected credentials without reconstructing or exposing plaintext;
- make mutating store operations coordinated and crash-safe through atomic replacement;
- document host-owned default versus explicit store selection and prove one injected store is used;
- correct SQL user-error aggregation and `:on error exit` in the shared execution coordinator;
- add unit and real SQL Server-backed coverage for prepared and streaming modes;
- publish the TigerQuery release before changing TigerWrap's package dependency in a later task.

This is specified in [TigerQuery Prerequisite Implementation](#tigerquery-prerequisite-implementation).

### Phase 1 — TigerWrap managed E2E integration and DB lifecycle spine

- consume the released TigerQuery APIs without changing TigerCli or reconstructing profiles;
- define the exact `TigerWrap:E2E:*` metadata keys and bootstrap/test-database semantics;
- select TigerWrap's default store or one explicit path once and inject the same store everywhere;
- validate the human-created `TigerWrap-E2E-Test` bootstrap; never create or repair it;
- replace `SqlServerTestDatabase`'s inferred `.` connection and temporary no-op store with bootstrap
  database creation plus same-store temporary managed-connection copy;
- implement independently tracked, failure-preserving connection/database cleanup and ownership-safe
  orphan reporting;
- add role-filtered connection providers;
- **done** — adopt prepared execution for the existing upgrade path (`ScriptRunner`, shared by
  install and upgrade);
- **done** — establish progress-reporting conventions ("batch N of M" from `ExecutionPlanReady`
  and `BatchEnd`);
- implement `db create` and `db drop` with safeguards;
- replace `TigerWrapDbStatus` with the upgrade-step catalogue and chain resolver;
- **done** — implement `db install` with CLI-side empty-database and capability preflight;
- add the capability probe with graceful fallback for pre-0.9.2 databases;
- reuse the completed deployment, unique-name, and basic teardown primitives only after removing
  their raw-connection and prefix/age-only assumptions.

Phase 1 is blocked until Phase 0 is released.

### Phase 2 — Script tooling and SQL-side guards

- implement `db sqlcmd`;
- ~~convert `Script.PreDeployment.sql` to a mode-detecting guard~~ — **not adopted**; see
  [The pre-deployment toggle problem](#the-pre-deployment-toggle-problem);
- **done** — add the SQL-side empty-database and capability guard
  (`Script.PreInstallEmptyCheck.sql`, expanded into the new 0.9.2 full-deploy artifact);
- **done** — prove CLI and SQL emptiness definitions agree (textually and behaviourally);
- verify the released TigerQuery correction against TigerWrap's real deployment artifacts;
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
| R7 | Pre-deployment comment toggle produces a wrong release artifact | High — either a full deploy with no guard, or an upgrade that refuses everything | Medium | **Mitigated.** `InstallGuardArtifactTests` asserts the packaged full deploy carries the install guard before the first `CREATE SCHEMA` and does not carry the upgrade check; `BuildInstaller.ps1` fails the build otherwise. Mode-detecting rewrite still open. |
| R8 | TigerQuery treats severity-16 `InfoMessage` diagnostics as successful batches, so `:on error exit` does not stop | High — later batches mutate state and the final result lies | Certain in the confirmed path | Fix the TigerQuery coordinator first; require failed batch/result/event and prepared/streaming live tests. TigerWrap's message-count check remains defense in depth only. |
| R9 | The E2E bootstrap is inferred, auto-created, repaired, or replaced | Critical — tests run destructively without explicit human authorization | Medium without a closed contract | Exact-name/metadata/`master` validation; fail or skip closed; no fallback, raw connection string, localhost, `.`, or LocalDB inference. |
| R10 | `db drop` destroys a real database | Critical | Low with safeguards | Layered safeguards; disposable metadata; `--force` and `--force-disconnect` opt-ins; system-database refusal. |
| R11 | New exit codes each require a DB change plus wrapper regeneration | Medium — churn and mismatched CLI/DB versions | High | Batch all new response codes in one Phase 3 change. |
| R12 | Golden packages committed before the format is settled | Medium — a "durable" format is amended after publication | Medium | Do not commit format-1 goldens until Phase 4 self-validation passes; treat the first tagged release as the freeze point. |
| R13 | Scope creep from the "Beyond 0.9.2" list | Medium — release slips | Medium | Out-of-scope list is normative, not advisory. |
| R14 | Chained upgrade partially completes and leaves an intermediate version | Medium — user confusion, unclear recovery | Medium | Per-step verification, explicit "database is now at version X" reporting, documented restore-from-backup recovery. |
| R15 | A temporary profile is reconstructed and silently loses a new option or protected credential | High — E2E differs from the approved bootstrap or exposes secrets | High without a generic copy API | TigerQuery same-store copy preserves every field by default and copies protected representation without plaintext; TigerWrap overrides only name, database, and selected metadata. |
| R16 | Default/explicit store operations split across two JSON files | High — bootstrap lookup and cleanup disagree, leaving or deleting the wrong resource | Medium | Resolve store selection once, inject one instance, and test that missing explicit-store data never falls back. |
| R17 | Concurrent whole-file store writes lose profiles or an interrupted write corrupts the user's default store | High | Medium when tests and CLI overlap | TigerQuery-coordinated mutations plus same-directory temporary write, flush, and atomic replace; concurrency and failure-injection tests. |
| R18 | Prefix/age orphan sweeping drops a database not owned by the current or recorded run | Critical | Low but unacceptable | Require `TWE2E_`, non-system status, approved bootstrap, and matching recorded ownership; otherwise report but do not drop. |

## Test matrix

| Area | Level | Requires SQL Server | Phase |
| --- | --- | --- | --- |
| Same-store copy preserves every profile field, unrelated metadata, and source profile | TigerQuery unit | No | 0 |
| Copy preserves the exact DPAPI protected representation without requiring plaintext | TigerQuery unit (Windows) | No | 0 |
| Copy rejects missing source, duplicate target, invalid overrides, and never crosses stores | TigerQuery unit | No | 0 |
| Concurrent add/copy/update/delete cannot lose updates; interrupted write preserves prior JSON | TigerQuery unit/integration | No | 0 |
| Severity-16 `:on error exit` stops, fails the triggering batch/result, and preserves diagnostics | TigerQuery E2E | Yes | 0 |
| `:on error ignore` records failure and continues; prepared/streaming event sequences agree | TigerQuery unit + E2E | Yes | 0 |
| Connection role metadata keys and filtering | Unit | No | 1 |
| Default store and explicit store each use only the selected bootstrap and temporary connection | App/E2E | Yes | 1 |
| Missing/invalid bootstrap and missing explicit-store bootstrap fail closed without fallback | App | No | 1 |
| Bootstrap remains byte-for-byte unchanged across successful and failed E2E runs | E2E | Yes | 1 |
| Temporary copy preserves Windows/SQL authentication and generic settings | E2E | Yes | 1 |
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
| Cleanup drops only owned `TWE2E_` non-system databases through the approved bootstrap | E2E | Yes | 1 |
| Cleanup failure does not mask the original test failure | Unit | No | 1 |
| SQL-side guard refuses a non-empty database when run directly | E2E | Yes | 2 |
| CLI and SQL emptiness definitions agree on the same database | E2E | Yes | 2 |
| `db sqlcmd` executes a file and reports deterministic exit codes | E2E | Yes | 2 |
| TigerWrap deployment artifacts observe corrected TigerQuery `:on error exit` semantics | E2E | Yes | 2 |
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
- menu-driven workflows and script-oriented commands;
- human provisioning of `TigerWrap-E2E-Test`, the default-store behavior, optional explicit-store
  isolation, and the fact that the bootstrap is permanent and never managed by the test suite;
- orphaned-resource diagnostics and the manual recovery procedure.

Screenshots: main menu; DB info; DB install; DB upgrade plan and progress; project export selection; import conflict plan; import result.

## Release acceptance criteria

0.9.2 is not released until:

- the TigerQuery prerequisite release provides tested same-store managed-connection copy,
  coordinated atomic store mutation, and corrected `:on error` result/event semantics;
- the E2E suite uses only the exact human-created `TigerWrap-E2E-Test` bootstrap from the selected
  default or explicit store and refuses every missing/invalid/fallback case;
- neither TigerWrap production code nor tests use raw/inferred SQL Server connection strings for
  E2E setup, and the bootstrap is never created, modified, or deleted by automation;
- each E2E database is reached through a TigerQuery copy that preserves the bootstrap's connection
  and protected-credential settings while overriding only name, database, and selected metadata;
- explicit-store lookup, filtering, copy, update/save, and delete never touch the default store;
- cleanup tracks the database and temporary connection separately, preserves the original failure,
  reports orphaned resources, and drops only an owned `TWE2E_` non-system database through the
  approved bootstrap;
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
- prepared execution is used for all SQL script workflows, and a triggering SQL error under
  `:on error exit` stops later batches, fails the batch and final result, and preserves diagnostics;
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
- one-command disposable E2E environment provisioning after (and never including) human bootstrap provisioning;
- a composed `db create + install` operation;

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
12. The permanent managed bootstrap is explicit authorization; automation never provisions it or
    falls back to another server or store.
13. Temporary managed connections are copied through TigerQuery, never rebuilt from raw connection
    strings or property lists in TigerWrap.
14. Store selection is made once per application/test run and is honored by every operation.

## TigerQuery Prerequisite Implementation

This is the one substantial next implementation task. It modifies `C:\Projects\TigerQuery` first.
TigerWrap E2E integration does not start until the resulting generic TigerQuery release is available.

### Objective

Make TigerQuery a safe generic foundation for managed-connection test lifecycles and reliable sqlcmd
execution by delivering, as one coherent change:

- a first-class, same-store managed-connection copy operation;
- coordinated, atomic managed-store mutations suitable for a normal user store;
- an explicit host-owned default/explicit store-selection contract; and
- correct SQL-error aggregation and `:on error exit` behavior in prepared and streaming execution.

TigerQuery remains unaware of TigerWrap names, metadata keys, database prefixes, roles, and cleanup
policy. TigerWrap composes the released generic capabilities later.

### Current gaps

- `SqlServerConnectionStore` has read/add/upsert/delete/filter APIs but no copy/clone API.
- `SqlServerConnectionProfile` is mutable and has no complete deep-copy primitive. Hand-copying its
  current property list would be fragile; `Options` and metadata also require independent copies.
- `Load` unprotects secrets and `Save` protects all supplied profiles. A copy built through that path
  can re-encrypt source/unrelated DPAPI blobs and depends on plaintext being available.
- store mutation is unsynchronized read-modify-write with direct `File.WriteAllText`, so concurrent
  writers can lose updates and a torn write can destroy the only JSON file.
- explicit `FilePath` construction exists, but default selection belongs to each host and there is no
  documented invariant that one selected store instance must serve all operations in a run.
- parser and prepared-plan handling of `:on error` are correct, but user errors delivered through
  `SqlConnection.InfoMessage` are not incorporated into the active batch outcome.

### Generic API changes required

Add a small Core surface whose naming may follow repository conventions but whose semantics are fixed:

```csharp
public sealed class SqlServerConnectionCopyOptions
{
    public required string TargetName { get; init; }

    // null = preserve the source value; empty = clear; non-empty = replace.
    public string? InitialCatalogOverride { get; init; }

    public IReadOnlyDictionary<string, string> MetadataToSet { get; init; }
        = new Dictionary<string, string>();
    public IReadOnlyCollection<string> MetadataToRemove { get; init; }
        = Array.Empty<string>();
}

public sealed class SqlServerConnectionStore
{
    public SqlServerConnectionProfile Copy(
        string sourceName,
        SqlServerConnectionCopyOptions options,
        SqlServerConnectionValidationPolicy? validationPolicy = null);
}
```

The implementation may choose a result type instead of documented exceptions if that fits TigerQuery
better, but do not expose a property-by-property TigerWrap callback and do not accept a destination
store. Binding copy to the source store is the no-cross-store guarantee. Default validation policy is
`DatabaseOptional`; a caller may require a database. Promote complete profile validation into Core if
needed so copy validates required fields, authentication/credential presence, and
`SqlConnectionStringBuilder` compatibility without making CLI internals public.

Do not add a universal TigerQuery default store. `Shared`, `AppSpecific`, and explicit `FilePath` are
valid because the host owns that choice. If a lightweight generic factory/configuration type improves
composition, it may select exactly one of a host-supplied default-options factory or an explicit path,
but it must have no fallback and no TigerCli dependency. Existing
`SqlServerConnectionCommandOptions.Store` remains the command-group injection point.

### Managed connection copy semantics

One atomic call must:

1. validate nonblank source and target names;
2. read the source and check the exact, case-sensitive target name while holding the same mutation
   coordination used through commit;
3. fail when the source is absent or target exists; it is never an upsert;
4. deep-copy every current and future generic profile property, free-form option, and metadata value;
5. preserve persisted protected-secret fields exactly and never require, expose, log, callback, or
   reconstruct plaintext;
6. override only target name, optional initial catalog, metadata entries explicitly set, and metadata
   keys explicitly removed; preserve all unrelated metadata;
7. validate the resulting profile without opening a SQL connection;
8. persist through TigerQuery's normal store transaction in the same selected JSON file;
9. leave the source profile and every unrelated profile semantically and byte-for-byte unchanged,
   including encrypted password values; and
10. return the detached persisted copy so callers can resolve it and later delete it through normal
    APIs.

The persistence design must not serialize from a set of already-unprotected live profiles. Introduce
an internal persisted-profile load/clone path or equivalent separation between at-rest and resolved
models. It must automatically carry newly added profile fields so future additions do not require
TigerWrap changes. DPAPI ciphertext is opaque data for copy; only ordinary connection resolution may
unprotect it.

### Default and explicit store behavior

- Existing `Shared(...)`, `AppSpecific(...)`, and direct `FilePath` behavior stays compatible.
- A host chooses its default or explicit path once and constructs/injects one store.
- `Load`, `Find`, metadata filtering, copy, add, update, save, and delete all use that exact store.
- A missing, malformed, inaccessible, or incomplete explicit store reports that error; no operation
  probes a default location.
- Expose the normalized selected path read-only if diagnostics/tests need to prove store identity;
  never log profile contents or secrets.
- The reusable connection commands continue to accept a store from the host. Do not add a TigerCli
  global option; do not define TigerWrap CLI syntax in TigerQuery.

### Metadata requirements

Metadata remains generic, opaque, ordinal, case-sensitive, non-secret string data. Copy preserves it
all by default, then applies exact-key removals and sets. Reject empty keys, null values, duplicate set
keys, and a key present in both set and remove collections. Reuse the existing validation semantics
behind `SqlServerConnectionMetadataOptions` where practical, moving only genuinely generic logic into
Core. TigerQuery must never recognize `TigerWrap:E2E:*` or any value used by TigerWrap.

### Protected credential handling

- Windows DPAPI remains the default Windows strategy; non-Windows behavior remains non-persisting.
- Copying a stored SQL-auth profile copies `EncryptedPassword` and `PasswordEncryption` exactly while
  leaving `PlainPassword` absent from the copy transaction.
- Copy succeeds when the current process cannot decrypt the blob; usability later follows the normal
  resolver/protector behavior.
- Copy does not re-protect source or unrelated profiles and never changes their ciphertext.
- Add/update compatibility remains, but atomic mutation must not introduce plaintext persistence.
- Tests and diagnostics compare protected blobs where needed but never print plaintext.

### Store coordination and atomic writes

All read-modify-write mutations (`Add`, `AddOrUpdate`, `Delete`, `Copy`, and any public whole-store
save path) must share coordination scoped to the normalized file path. Serialize to a same-directory
temporary file, flush it, and atomically replace/move the destination only after serialization and
validation succeed. Preserve the previous valid file on failure and remove only the operation's own
temporary artifact. Define behavior for first creation and platforms where replace primitives differ.

At minimum, coordination must protect writers within one process. Prefer a narrowly scoped cross-process
lock because the default store can be opened by TigerWrap, tiger-sqlcmd, tests, and another process;
document the guarantee actually delivered and make timeout/cancellation/failure behavior explicit.
Preserve existing JSON shape, ordering, metadata ordering, and case-sensitive duplicate rules.

### `:on error exit` correction

Treat SQL diagnostics raised through `InfoMessage` as part of the currently executing batch:

- collect diagnostics only inside the active `BatchStart`/`BatchEnd` interval;
- distinguish informational messages from errors using the existing `SqlCmdMessage` severity model;
- if any qualifying SQL error was observed, mark that batch attempt failed even when provider
  execution returned normally;
- preserve every diagnostic through `OnMessage` exactly once and avoid double counting an error that
  is also present in a thrown `SqlException`;
- under effective exit-on-error, set a non-success `ExecutionResultCode`, increment `FailedBatches`,
  set `BatchEnd.Success=false`, retain an appropriate exception/diagnostic representation, and do not
  raise `BatchStart`/`BatchEnd` for unexecuted batches;
- under effective ignore/continue, increment `FailedBatches`, end the triggering batch unsuccessfully,
  then execute the next scheduled batch; final result compatibility must remain documented (currently
  `Success` may coexist with ignored failed batches);
- fatal, cancellation, parser, connection-opening, and callback behavior must remain coherent; and
- prepared and streaming schedulers must use the same active-batch outcome logic.

Match normal sqlcmd semantics for at least `RAISERROR`/`THROW` severity 16 under `:on error exit` and
`:on error ignore`. Test any intentional severity threshold difference explicitly instead of relying
on the `InfoMessage` transport accident.

### Affected TigerQuery areas

- `ItTiger.TigerQuery.Core/SqlServerConnectionStore*`
- `SqlServerConnectionProfile`, password-protector integration, validation, and metadata mutation
- Core README/XML/API documentation and DocFX output
- `ItTiger.TigerQuery.CliCore` only where it can reuse promoted generic validation or document injected
  store selection; existing command behavior and exit mappings remain compatible
- `SqlCmdParser` and `PreparedExecutionPlan` primarily as regression boundaries, not expected root-cause
  locations
- `TigerQueryEngine.ConfigureConnection`, batch scheduler/coordinator, message handling, `BatchEnd`,
  `ExecutionResult`, and related documentation
- TigerQuery unit and SQL Server-backed test projects

### Unit tests

- copy every profile field, an independent `Options` dictionary, all metadata, and future-field
  completeness; source mutation after copy cannot affect target and vice versa;
- override name/catalog/selected metadata, remove selected metadata, and preserve unrelated keys;
- missing source, blank names, exact-case duplicate target, invalid metadata mutations, invalid profile,
  and persistence failure leave the store unchanged;
- integrated-auth and SQL-auth copy; exact DPAPI blob preservation without plaintext; undecryptable
  protected blob copy; no source/unrelated ciphertext churn;
- default-path options and explicit path create distinct stores; every operation stays on the chosen
  store and missing explicit data never triggers a default probe;
- concurrent add/copy/update/delete has no lost updates; fault injection before atomic replace leaves
  the old JSON readable; no partial JSON is observable;
- parser/plan policy capture remains correct around `GO`, repeated batches, and alternating directives;
- coordinator tests cover info-only, one user error, multiple diagnostics, thrown `SqlException`
  deduplication, exit versus ignore, repeat counts, event order, counts, and unexecuted batches.

### Real SQL Server-backed tests

Run both prepared and streaming modes against scripts containing successful batches before and after:

- `:on error exit` plus `RAISERROR(..., 16, ...)`;
- `:on error exit` plus `THROW`;
- `:on error ignore` plus the same failures;
- fatal/error variants supported by the existing result model; and
- `GO n` where an early iteration fails.

Assert executed SQL side effects, `ExecutionPlanReady` presence/absence, `BatchStart`/`OnMessage`/
`BatchEnd` order, failed and executed counts, final result code, preserved SQL number/severity/state/line,
and absence of success events for unexecuted work. Add a Windows SQL-auth store/copy/resolve/open test
when credentials are available; otherwise keep DPAPI mechanics in Windows unit tests and cover
integrated-auth copy/open live.

### Compatibility and public API implications

- Existing JSON files, metadata omission/order, profile names, path helpers, connection strings,
  add/edit/list/show/delete commands, semantic exit kinds, and default execution mode remain compatible.
- Do not rename existing properties or change default store paths.
- Do not change NuGet versions in this planning task; the later TigerQuery implementation/release task
  owns normal versioning and package notes.
- New public types/members require XML comments, Core/CliCore README examples, DocFX inclusion, and
  release notes that call out the stronger mutation guarantee and corrected execution semantics.
- If ignored failed batches retain `ExecutionResultCode.Success`, document that compatibility
  explicitly; exit-on-error must never return success.

### Completion criteria

- the generic copy API satisfies every semantic rule above without plaintext reconstruction;
- all mutating store APIs use the documented coordination/atomic-write path;
- default and explicit-store tests prove there is no fallback or cross-store mutation;
- prepared and streaming live tests prove sqlcmd-compatible exit/ignore behavior and coherent events;
- existing TigerQuery tests and CLI exit-code contracts remain green;
- Core/CliCore/engine XML docs, READMEs, DocFX, build, test, and `git diff --check` are clean; and
- a TigerQuery release containing these capabilities is available before TigerWrap integration begins.

### Explicit non-goals

- no TigerWrap connection names, metadata keys/values, database prefixes, ownership rules, or cleanup
  logic in TigerQuery;
- no bootstrap creation or E2E fixture in TigerQuery;
- no raw connection-string reconstruction helper;
- no cross-store copy;
- no TigerCli changes and no TigerCli global option;
- no TigerWrap workaround for engine result aggregation;
- no automatic store fallback, store migration, cloud secret vault, or replacement for DPAPI; and
- no TigerWrap production or test changes in this upstream task.

## Deferred TigerWrap Lifecycle Slice

The former recommended first slice below is retained as downstream historical context. It is not the
next task and must not be implemented until the TigerQuery prerequisite above has been released and
consumed. Where it conflicts with the managed-connection lifecycle above, the newer lifecycle wins.

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
9. `ItTiger.TigerWrap.Tests`: after the TigerQuery prerequisite is consumed, replace the current
   raw/inferred connection fixture with the permanent-bootstrap, same-store copy, ownership, and safe
   cleanup lifecycle specified above; migrate the existing upgrade journey test onto it.

**Explicitly not in scope**

- Any change to `TigerWrapDb/` source SQL, deployment scripts, static data, or `Script.Version.sql`.
- Any change to `[Enum].[ToolkitResponseCode]` or regeneration of `ToolkitDbHelper`. Codes this slice needs that do not exist yet reuse the closest existing code and are noted for the Phase 3 batch.
- The SQL-side empty-database guard and the pre-deployment mode-detecting guard (Phase 2). This slice's emptiness protection is CLI-side only, and that limitation is stated in the command's own output.
- `db sqlcmd` (Phase 2).
- Any project export, import, snapshot, or format work.
- `ApiLevel` changes.
- Documentation rewrites beyond command help text.

**Boundary note on `db install`.** ~~Because this slice changes no SQL, the only full-deploy artifact available is `TigerWrapDb_FullDeploy_v_0.9.1.sql`, which has no internal guard.~~ **Superseded.** The install increment shipped the SQL-side guard together with the command, so the asymmetry never existed — but it *does* change SQL, and therefore the TigerWrapDb version: the guard went into a newly generated `TigerWrapDb_FullDeploy_v_0.9.2.sql`, the released `0.9.1` artifact was left exactly as shipped, and `db install` is tested by installing 0.9.2 into an empty database with both layers active.

### Acceptance criteria for the slice

The slice is done when all of the following hold, verified against the SQL Server explicitly approved
by the selected bootstrap connection:

1. `db create` creates a database from an administrative connection, rejects invalid names, refuses a regular-role connection, and reports the created database's collation and compatibility level.
2. `db drop` refuses: a system database; a database with no disposable-tagged connection and no `--force`; the database its own connection targets; a non-interactive run without `--confirm`. It succeeds for a disposable-tagged database and does not force-disconnect unless `--force-disconnect` is supplied.
3. `db install` installs 0.9.2 into an empty database and verifies the resulting version and API level.
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
14. Every E2E database created by the suite is named `TWE2E_*`; cleanup or recovery drops it only
    through the approved bootstrap and only with matching current/recorded ownership.
15. A test whose body fails and whose cleanup also fails reports the body's failure, with the cleanup error as supplementary output only.
16. `dotnet build` in Release is warning-clean and `dotnet test` is green with and without a local SQL Server.

## Deferred TigerWrap Implementation Brief

This is downstream reference material, not the next task. Do not execute it until the
[TigerQuery prerequisite](#tigerquery-prerequisite-implementation) is released; then reconcile it
with the authoritative managed-connection E2E architecture before coding.

### Objective

After the upstream gate, deliver the remaining TigerWrapDb lifecycle spine and the managed-connection
E2E fixture — **with zero changes to `TigerWrapDb/` in this downstream slice**.

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
- Prefix alone is never sufficient: require matching ownership, a non-system database, and the
  validated permanent bootstrap; never create, edit, or delete the bootstrap.
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

The TigerQuery prerequisite has first been released and consumed; all sixteen downstream slice
acceptance criteria plus the managed-connection acceptance criteria pass; `dotnet build -c Release`
is warning-clean; `dotnet test` is green both with and without a configured bootstrap; no file under
`TigerWrapDb/` is modified; and `git diff --check` is clean.
