# TigerWrap 0.9.2 — General Plan

## Release direction

TigerWrap 0.9.2 should be a user-feature release focused on:

- project portability;
- TigerWrapDb lifecycle operations;
- safer installation and upgrades;
- real SQL Server-backed end-to-end testing.

The release should not be justified only by internal refactoring or test infrastructure.

A concise release theme:

> Install, move, recover, and upgrade TigerWrap projects and TigerWrapDb safely.

## Current foundation

TigerWrap has already been updated to the latest Tiger* packages available for this work:

- TigerCli 0.8.1
- TigerQuery 0.8.2

TigerCli 0.8.1 does not add a major TigerWrap-specific feature, but keeps TigerWrap on the current TigerCli foundation.

TigerQuery 0.8.2 adds two important capabilities:

- prepared execution;
- generic namespaced connection metadata.

These should be used as the foundation for 0.9.2 database lifecycle and E2E work.

## Main user-facing features

### 1. Project export/import

TigerWrap 0.9.2 should support:

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

This feature is described in detail in:

```text
TigerWrap_0.9.2_Project_Import_Export_Design.md
```

### 2. TigerWrapDb install

A new normal user workflow should install TigerWrapDb into an already-created empty database.

Command:

```text
db install
```

This command should be visible in the menu.

Default assumptions:

- the database already exists;
- the database was created by the user, DBA, managed service, or another authorized process;
- the user has created a normal TigerQuery connection targeting that database;
- TigerWrap does not assume the user is allowed to create databases;
- TigerWrap does not assume company policy allows application tools to create databases.

Expected flow:

```text
select existing connection
-> inspect target database
-> verify it appears empty
-> show install plan
-> confirm
-> prepare full-install script
-> execute with progress
-> verify TigerWrapDb version and API level
```

The packaged full-install SQL script remains the deployment artifact.

### 3. Chained TigerWrapDb upgrades

The existing 0.9.0 to 0.9.1 guided upgrade should be generalized.

Required paths for 0.9.2:

```text
0.9.0 -> 0.9.1 -> 0.9.2
0.9.1 -> 0.9.2
```

Expected behavior:

- inspect the current database version;
- resolve the complete supported chain;
- verify all required scripts exist;
- prepare all scripts before execution where practical;
- display the complete plan;
- require backup confirmation once;
- execute each step in order;
- show progress;
- verify expected version and API level after each step;
- stop immediately on failure;
- do not skip versions unless a direct upgrade script explicitly exists.

The upgrade SQL scripts remain responsible for verifying:

- the expected TigerWrap database identity;
- the expected starting version;
- the expected upgrade transition.

They are not intended to detect arbitrary schema drift.

The version is treated as the trusted representation of the installed schema.

## Supporting database commands

### Menu-driven commands

These are normal user workflows and should appear in the menu:

```text
db info
db install
db upgrade
```

### Script-oriented commands

These should be discoverable through command help but excluded from the menu:

```text
db create
db drop
db sqlcmd
```

They are primarily for automation, testing, and explicit administrative workflows.

They should prompt only where appropriate, most likely for connection selection.

Other required values should be supplied explicitly.

## `db create`

Purpose:

- create a database explicitly;
- support E2E setup;
- support users who are authorized to create databases.

This command must not be part of the default TigerWrapDb install path.

It should use a special connection profile that:

- targets `master`; or
- has no selected database.

Possible flow:

```text
select administrative connection
-> provide database name
-> validate name
-> confirm
-> create database
-> verify creation
```

The command should not silently proceed into TigerWrapDb installation unless a future explicit composed operation is designed.

## `db drop`

Purpose:

- controlled database cleanup;
- especially E2E test cleanup.

Required safeguards:

- explicit database name;
- refuse system databases;
- clear target display;
- explicit confirmation;
- explicit noninteractive confirmation flag;
- use connection metadata to distinguish E2E-managed resources where practical;
- do not force-disconnect users by default;
- fail safely if ownership or intent is unclear.

The first implementation should favor safety over convenience.

## `db sqlcmd`

Purpose:

- execute TigerWrap test/setup SQL files;
- support E2E database population;
- reuse TigerQuery execution;
- expose only the subset TigerWrap needs.

This intentionally overlaps with `tiger-sqlcmd`, but has a narrower purpose.

Conceptually:

```text
db sqlcmd --connection <name> --mode SqlCmdEx --file PopulateTestDb.sql
```

Expected characteristics:

- command-line/script oriented;
- excluded from the menu;
- connection may be promptable;
- file and mode should be explicit;
- deterministic exit codes;
- TigerQuery-based execution;
- prepared execution;
- progress reporting through TigerCli.

Additional options such as variables or timeout should be added only when needed and already supported cleanly by TigerQuery.

## Prepared execution

TigerQuery prepared execution should become the preferred model for script-based TigerWrap operations.

Likely consumers:

- `db install`
- `db upgrade`
- `db sqlcmd`
- script-driven parts of `db create`
- script-driven parts of `db drop`

Benefits:

- the complete SQLCMD structure is parsed before execution;
- later parser failures are detected before database mutation;
- logical batch counts are available;
- scheduled execution totals are available;
- TigerCli can display meaningful progress;
- failure reporting can identify the exact stage and batch more clearly.

For chained upgrade, progress may be shown at both chain and batch level:

```text
Preparing upgrade chain
Step 1 of 2: 0.9.0 -> 0.9.1
Batch 47 of 140
Step 2 of 2: 0.9.1 -> 0.9.2
Batch 18 of 93
```

Prepared execution does not replace SQL-side guards or transaction logic.

## Connection metadata conventions

TigerQuery namespaced metadata should distinguish connection purpose.

TigerWrap should define a stable namespace and a small set of documented keys.

Possible roles:

```text
Regular
Administrative
E2E
```

### Regular connection

Targets a TigerWrapDb or a candidate empty database.

Used by:

- `db info`
- `db install`
- `db upgrade`
- project commands
- code generation
- import/export

### Administrative connection

Targets `master` or has no selected database.

Used by:

- `db create`
- `db drop`
- test environment setup and cleanup

### E2E connection

Marks a test-owned resource.

May include metadata such as:

- test run ID;
- intended database name;
- ownership marker;
- creation timestamp;
- cleanup eligibility.

The metadata must remain generic TigerQuery metadata under a TigerWrap-owned namespace.

TigerWrap should not create a separate connection store.

## Empty-database protection

The current full-install script assumes an empty database but does not verify it.

0.9.2 should add protection in two places:

1. `db install` preflight;
2. the full-install SQL script itself.

The CLI check provides early, readable feedback.

The SQL check remains the final barrier when:

- the script is run directly;
- the CLI check is bypassed;
- the database changes between preflight and execution.

“Empty enough for TigerWrap installation” should mean no user application objects are present.

At minimum, reject:

- user tables;
- views;
- stored procedures;
- functions;
- sequences;
- synonyms;
- user-defined types;
- assemblies;
- TigerWrap-owned schemas.

Normal infrastructure should not automatically disqualify the database:

- users;
- roles;
- permissions;
- database settings;
- platform-created metadata;
- system objects.

The script must fail before creating any TigerWrap object.

The error should report useful details, such as object counts or sample objects.

The CLI and SQL script should use the same logical definition of emptiness to avoid drift.

## Upgrade safety philosophy

Upgrade scripts should continue to use faithful identity and version checks.

They should verify:

- expected database identity;
- expected source version;
- expected upgrade path.

They should not attempt to prove that no one has manually modified the schema.

TigerWrap assumes the declared version represents the intended schema.

Schema-drift detection is a separate problem and is not required for 0.9.2.

## E2E testing foundation

0.9.2 should establish real SQL Server-backed automated testing.

TigerQuery connection metadata and the new DB commands make this practical.

A typical install test:

```text
create administrative E2E connection
-> db create unique test database
-> create regular connection targeting it
-> db install
-> db info
-> db sqlcmd --mode SqlCmdEx --file PopulateTestDb.sql
-> configure or import projects
-> generate wrappers
-> verify output
-> db drop
-> remove temporary connections
```

A chained upgrade test:

```text
db create
-> deploy TigerWrapDb 0.9.0
-> db upgrade
-> verify 0.9.2
-> db drop
```

An import/export test:

```text
export projects
-> install fresh TigerWrapDb
-> import package
-> export again
-> compare logical project state
-> db drop
```

Tests should use unique disposable databases.

Cleanup must be robust but must not hide the original test failure.

## Suggested implementation order

### Phase 1 — Foundation

- confirm TigerCli and TigerQuery package upgrades;
- define TigerWrap namespaced connection metadata;
- adopt prepared execution for current upgrade execution;
- establish progress reporting conventions;
- establish disposable DB naming and ownership conventions.

### Phase 2 — DB lifecycle primitives

- implement script-oriented `db create`;
- implement script-oriented `db drop`;
- implement script-oriented `db sqlcmd`;
- add safety checks;
- add E2E setup and cleanup helpers.

### Phase 3 — TigerWrapDb install

- define empty-database rules;
- add SQL-side full-install guard;
- add CLI preflight;
- implement menu-driven `db install`;
- add prepared execution and progress;
- verify version/API level after install;
- add real DB install tests.

### Phase 4 — Project export

- define project format versioning;
- add `[dbo].[SchemaVersion]` field;
- add introduced-field metadata table;
- add introduced-version column to `[Static].[LanguageOption]`;
- define canonical JSON shape;
- implement all and multi-select export;
- store canonical JSON internally;
- add self-validation and round-trip checks.

### Phase 5 — Project import

- implement package validation;
- implement compatibility analysis;
- implement all-earlier-version support foundation;
- implement one-step-forward loss analysis;
- implement conflict planning;
- implement Rename, AutoRename, Skip, Replace, and Fail;
- implement transaction-per-project execution;
- implement Replace using import-under-temp-name;
- verify each imported project;
- add partial-success result handling.

### Phase 6 — Chained upgrade

- add 0.9.1 to 0.9.2 upgrade script;
- define upgrade-step metadata;
- implement chain resolution;
- prepare complete chain;
- show complete plan;
- execute and verify each step;
- test 0.9.0 to 0.9.2 and 0.9.1 to 0.9.2.

### Phase 7 — Release hardening

- expand SQL Server-backed test coverage;
- retain golden import/export files;
- test SQL Server 2017 compatibility;
- run installer and WinGet upgrade scenarios;
- update documentation;
- add screenshots for menu-driven flows;
- verify packaged scripts;
- verify clean install and upgrade from 0.9.1.

## Documentation goals for 0.9.2

Documentation should clearly explain:

- TigerWrap CLI and TigerWrapDb are separate components;
- `db install` targets an existing empty database;
- database creation is explicit and not the default;
- project export/import is the portability and recovery mechanism;
- import conflict behavior;
- database upgrade chains;
- backup requirements;
- WinGet installation and update;
- GitHub releases may appear before WinGet updates;
- menu-driven workflows where available;
- script-oriented commands where appropriate.

Screenshots should focus on:

- main menu;
- DB info;
- DB install;
- DB upgrade plan and progress;
- project export selection;
- import conflict plan;
- import result.

## Release acceptance criteria

0.9.2 should not be released until:

- project export works for all and selected projects;
- export validates itself;
- project import supports the documented conflict actions;
- Replace preserves the original project on failure;
- import uses transaction per project;
- all earlier project formats are importable;
- one-step-forward import is tested;
- actual lossy fields and flags are reported;
- `db install` refuses occupied databases before mutation;
- the full-install script independently refuses occupied databases;
- chained upgrades work from 0.9.0 and 0.9.1;
- prepared execution is used for SQL script workflows;
- progress reporting is meaningful;
- E2E tests create and clean up disposable databases;
- SQL Server 2017 compatibility is preserved;
- Release build and tests are green;
- packaged installer scripts are verified.

## Beyond 0.9.2

Possible later features:

- restore from internal project snapshots;
- automatic pre-delete snapshots;
- automatic pre-import snapshots;
- project history browsing;
- selective restore;
- project diff;
- richer import merge behavior;
- import dry-run as a persistent report;
- export signing or stronger integrity metadata;
- automatic export before database upgrade;
- broader generated-wrapper E2E coverage;
- parser stress database integration;
- one-command E2E environment provisioning.

These should not be allowed to expand the 0.9.2 scope prematurely.

## Core design principles

1. Database creation is explicit, not assumed.
2. Normal installation targets an existing empty database.
3. SQL-side guards remain authoritative.
4. Script-oriented commands stay out of the menu.
5. TigerQuery execution and metadata are reused.
6. Import/export is a durable compatibility contract.
7. No silent data loss.
8. No partial project mutation.
9. Replace imports first and deletes later.
10. Real SQL Server testing is part of the release gate.
