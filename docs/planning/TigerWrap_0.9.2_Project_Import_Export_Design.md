# TigerWrap 0.9.2 — Project Import/Export Design

## Purpose

Project import/export is a core TigerWrap lifecycle feature, not a convenience feature.

It is intended to become:

- the supported way to move TigerWrap projects between environments;
- a recovery mechanism;
- a safety net before destructive operations;
- a durable compatibility contract between TigerWrap versions;
- a basis for future project history, restore, and audit features.

The exported JSON must be treated as a durable user asset. Once a project format is published, future TigerWrap versions must continue to understand it.

## Scope for 0.9.2

TigerWrap 0.9.2 should support:

- exporting all projects;
- exporting a user-selected subset of projects;
- interactive multi-select;
- importing one or more projects from a package;
- conflict handling per project;
- transaction-per-project import;
- internal storage of canonical project JSON;
- format versioning;
- full backward compatibility;
- one-step-forward import compatibility with explicit loss warnings.

Complex merge semantics are not required for the first release.

### Explicitly out of scope for 0.9.2

- project diff, selective restore, or restore-from-snapshot user commands;
- automatic pre-delete or pre-import snapshots outside the import path itself;
- merge semantics of any kind (a conflicting project is renamed, skipped, replaced, or failed — never merged);
- signing, encryption, or tamper-evidence beyond a content checksum;
- migration functions between project formats (there is only format 1 in 0.9.2; the *mechanism* is designed now, the *functions* arrive with format 2);
- export or import of anything outside the project aggregate (connections, static data, templates, parser data, snapshots themselves).

## Current-state findings that constrain this design

These were established by inspecting the 0.9.1 repository and are load-bearing for everything below.

1. **A project's only identity today is `[dbo].[Project].[Name]`.** `Id` is a `SMALLINT IDENTITY`; the sole natural key is `UX_Project_Name`. There is no stable, rename-proof logical identifier.
2. **The project aggregate is exactly four tables**: `[dbo].[Project]`, `[dbo].[ProjectEnum]`, `[dbo].[ProjectStoredProc]`, `[dbo].[ProjectNameNormalization]`. Nothing else is project-owned.
3. **`[View].[Project]` is already stale.** It does not project `DescriptionAttributeClassName` / `DescriptionAttributeNamespaceName`, which were added to `[dbo].[Project]` in 0.9.1. Field drift between the table and its projections is not hypothetical in this codebase; it has already happened once.
4. **`[Toolkit].[CreateProject]` rejects a `@defaultDatabase` that does not exist on the target server**, and also rejects `NULL` (`IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE [name]=@defaultDatabase)` returns `InvalidDatabase` for `NULL`). Naive reuse of this procedure makes cross-environment import — the primary use case — fail.
5. **Language options are bitmasks whose bits are language-scoped.** In `[Static].[LanguageOption]`, options with `LanguageId IS NULL` occupy the low bits (`0x1`–`0x10`) and `LanguageId = 1` (C#) options occupy `0x10000`+. `FU_LanguageOption_LanguageId_IsPrimary_Value` is a *filtered* unique index (`WHERE IsPrimary = 1`), so non-primary rows may share a value with a primary row — aliases are structurally permitted. A raw `BIGINT` is therefore not a portable representation of a flag set.
6. **`[Toolkit].[GetDbInfo]` has had a byte-identical four-`OUTPUT`-parameter signature since 0.8.5**, and `DbCommandSupport.ProbeAsync` calls it through the *generated* wrapper against databases of unknown version. See [Invariant I1](#invariants) — this constrains how project-format information may be surfaced.
7. **`[Enum].[ToolkitResponseCode]` is the source of the CLI's own exit codes** (rows 1000+ and 2002+ are mirrored into the generated `ToolkitResponseCode` enum). Any new exit code this feature needs is a TigerWrapDb change plus a wrapper regeneration, not a CLI-only change.
8. **The database has no JSON usage today** beyond one `FOR JSON PATH` in `[Toolkit].[GetProjectDbSchemaEnumCandidates]`, and no snapshot or history concept of any kind. Everything in this document is new construction.
9. **The SSDT project targets `Sql150DatabaseSchemaProvider` (SQL Server 2019)**, not `Sql140` (2017). The SQL Server 2017 compatibility goal is currently unenforced. See the General Plan risk register.

## Export selection

Interactive export should support:

- **All projects**
- **Multi-select projects**

Command-line use should support an explicit all-projects mode and repeatable project selection.

Conceptually:

```text
project export --all
project export --project ProjectA --project ProjectB
```

The exact CLI syntax may be adjusted to fit TigerCli conventions, but the following are fixed:

- `--all` and `--project` are mutually exclusive; supplying both is an argument error;
- supplying neither in non-interactive mode is an argument error (there is no implicit default);
- a named project that does not exist is a hard failure before any file is written — export never produces a partial package.

## Canonical implementation layer

Project JSON is serialized and deserialized in **TigerWrapDb**, using SQL Server 2017-compatible T-SQL JSON features.

Expected SQL features include:

- `FOR JSON PATH`
- `OPENJSON`
- `JSON_VALUE`
- `JSON_QUERY`
- `ISJSON`

The database owns:

- the logical project model;
- reference resolution;
- project format compatibility;
- conflict analysis;
- import execution;
- snapshot creation;
- post-import verification.

The CLI orchestrates the workflow, displays plans and warnings, reads and writes files, and selects projects and conflict policies.

**The CLI must not define a second, independent project serialization model.** Specifically, the CLI must not parse the package into a typed C# object graph in order to make decisions about it. The CLI may read the package as opaque text and may read a small, explicitly frozen *envelope* (see [Package envelope](#package-envelope)) for display and early rejection, but every decision that depends on project content is made by TigerWrapDb.

### Architectural boundary

| Concern | Owner |
| --- | --- |
| Canonical JSON shape, ordering, escaping | TigerWrapDb |
| Format version arithmetic and compatibility verdicts | TigerWrapDb |
| Unknown-path detection and loss analysis | TigerWrapDb |
| Conflict detection (name collisions in the target) | TigerWrapDb |
| Import execution and per-project transactions | TigerWrapDb |
| Post-import logical verification | TigerWrapDb |
| Snapshot storage | TigerWrapDb |
| File I/O, encoding, BOM handling | CLI |
| Project selection UI and multi-select | CLI |
| Conflict *policy* selection and rename mappings | CLI |
| Plan rendering, warnings, confirmation prompts | CLI |
| Exit-code mapping | CLI |
| Envelope pre-read for early rejection and display | CLI (read-only, frozen subset) |

## Logical format

The export represents logical project data, not physical database storage.

It must not expose or depend on:

- identity values;
- physical row IDs;
- implementation-specific relationship keys;
- table layout details that are not part of the logical project contract.

The same logical project produces byte-identical JSON regardless of physical IDs, insertion order, or the server it was exported from.

The package is readable, versioned, and self-describing.

### Package envelope

The envelope is the small prefix of the package that a *format-x* importer — and the CLI — may read before knowing whether it understands the rest. Its shape is frozen for all time.

```json
{
  "format": "TigerWrap.ProjectExport",
  "projectFormatVersion": 1,
  "package": {
    "createdAtUtc": "2026-08-14T10:22:31Z",
    "createdBy": {
      "tigerWrapVersion": "0.9.2",
      "tigerWrapDbVersion": "0.9.2",
      "databaseApiLevel": 3
    },
    "sourceServer": null,
    "sourceDatabase": null,
    "projectCount": 2,
    "checksum": "sha256:2f1c…"
  },
  "introducedElements": { "fields": [], "flags": [] },
  "projects": []
}
```

Envelope rules (frozen from format 1):

- `format` is the literal string `TigerWrap.ProjectExport`. Any other value is rejected without further parsing.
- `projectFormatVersion` is a positive integer. It is the *only* value used to decide compatibility.
- `package`, `introducedElements`, and `projects` always exist, in this order.
- `projects` is always an array, possibly empty. An empty export is legal and produces a valid package.
- No future format may rename, remove, retype, or reorder these five root properties. Additions at the root are permitted and are subject to the [one-step-forward rules](#compatibility-contract).
- `sourceServer` and `sourceDatabase` are provenance only, are nullable, and are **excluded from the checksum**. They must never be used to make an import decision. Export must offer a way to omit them for users who consider server names sensitive.

### Package-level versus project-level metadata

- **Package level** carries provenance, counts, the checksum, and `introducedElements`. It is *not* part of the logical data and does not round-trip: re-exporting an imported project produces a package with different provenance and a different `createdAtUtc`.
- **Project level** carries only logical project data. It is the unit of round-trip equality.

A round-trip test compares the `projects` array, never the whole package.

### Project identity

`[dbo].[Project].[Name]` is the operational identity: it is what conflicts are detected on, what the user sees, and what `Rename`/`Replace` operate on. It is not stable — renaming a project destroys the correlation between an old export and the live project.

**Decision:** 0.9.2 adds a stable logical identifier to the project aggregate and exports it in format 1.

```sql
-- [dbo].[Project]
[Uid] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_Project_Uid] DEFAULT (NEWID())
-- plus UNIQUE index UX_Project_Uid
```

Rationale and consequences are recorded as [Decision D2](#d2--does-a-project-get-a-stable-uid-in-format-1). In summary: adding it later is a format change that older packages cannot supply, so no importer could ever correlate a pre-Uid export with a post-Uid project. Adding it now costs one column and one exported field.

`Uid` semantics in format 1:

- It is exported and imported verbatim.
- It is **not** used for conflict detection in 0.9.2. Conflicts are name-based only. `Uid` is recorded so that later releases can offer identity-based reconciliation without a format change.
- On import, a `Uid` that already exists in the target on a *different* project is a package/target conflict. In 0.9.2 the importer resolves this by generating a fresh `Uid` for the incoming project and reporting it in the plan; it does not fail. (Failing would make "import the same package twice under different names" impossible, which is a legitimate workflow.)
- `Replace` preserves the *incoming* project's `Uid`, not the replaced project's.

### Deterministic ordering

Ordering is part of the format, not an implementation detail, because golden-file comparison depends on it.

- Projects are ordered by `Name` using an explicit binary collation: `ORDER BY [Name] COLLATE Latin1_General_100_BIN2`.
- `enumMappings` are ordered by `(schema, nameMatch, namePattern)`, each with the same explicit binary collation, `namePattern` nulls first.
- `storedProcedureMappings` use the same key and rule.
- `nameNormalizations` are ordered by `(namePartType, namePart)`.
- `languageOptions` name arrays are ordered by option `Value` ascending, then `Name` binary-ascending.

The explicit `COLLATE` is mandatory. Without it, a package exported from a `Latin1_General_CI_AS` database and one exported from a case-sensitive or accent-sensitive database would order differently for identical logical content, breaking checksums and golden files.

### Null versus omitted properties

**Decision:** export uses `INCLUDE_NULL_VALUES` for every object in the package.

Consequences, which are the point of the decision:

- Every property defined by the package's format version is physically present in the package.
- `null` means "this element exists in this format and has no value."
- **Absent means "this element is not part of this format."**

This makes the structural comparison in [Unknown-path detection](#unknown-path-detection-is-authoritative) sound in both directions: a format-x importer reading a format-x package can assert that every path it knows is present, and can treat any path it does not know as a genuine format extension rather than as an ordinary optional field.

Empty child collections serialize as `[]`, never as `null` and never omitted. In T-SQL this requires an explicit guard, because `JSON_QUERY((SELECT … FOR JSON PATH))` yields `NULL` for an empty set:

```sql
JSON_QUERY(ISNULL((SELECT … FOR JSON PATH, INCLUDE_NULL_VALUES), N'[]'))
```

### Flag representation

Flags are exported as **names scoped by language**, never as bitmask values.

```json
"languageOptions": {
  "value": null,
  "names": [
    { "language": null,     "name": "GenerateStaticClass" },
    { "language": "CSharp", "name": "UseSyncWrappers" }
  ]
}
```

Rules:

- `language` is the `[Enum].[Language].[Code]` value, or `null` for language-independent options — matching `[Static].[LanguageOption].[LanguageId]` nullability exactly.
- `(language, name)` is the flag's stable public identity. See [Invariant I5](#invariants).
- Only `IsPrimary = 1` rows are emitted, so aliases never appear in a package and export stays deterministic.
- `value` is present, always `null` in format 1, and reserved. It exists so that a future format can carry a raw mask for diagnostics without a structural change. Importers must ignore it.
- `[dbo].[ProjectStoredProc].[LanguageOptionsReset]` and `[LanguageOptionsSet]` use the same representation, as `languageOptionsReset` / `languageOptionsSet` name arrays. A `NULL` mask exports as `null`; an empty mask exports as `[]`. These are distinct and must round-trip distinctly.
- On import, a `(language, name)` pair the target does not know is a **loss event**, subject to the one-step-forward rules. A pair the target knows but whose bit value differs from the source database is *not* a loss event — resolution is by name, which is the whole point.

### JSON path conventions

Canonical paths are used in `introducedElements`, in the field registry, and in loss messages. They are frozen from format 1.

- Paths are rooted at `$`.
- Collections are addressed with `[*]`, never with an index.
- Property names are camelCase and match the package exactly.
- Object-valued containers are named, so a path always identifies one logical element.

Canonical path set for format 1:

```text
$.format
$.projectFormatVersion
$.package.createdAtUtc
$.package.createdBy.tigerWrapVersion
$.package.createdBy.tigerWrapDbVersion
$.package.createdBy.databaseApiLevel
$.package.sourceServer
$.package.sourceDatabase
$.package.projectCount
$.package.checksum
$.introducedElements.fields[*]
$.introducedElements.flags[*]
$.projects[*].uid
$.projects[*].name
$.projects[*].namespaceName
$.projects[*].className
$.projects[*].classAccess
$.projects[*].language
$.projects[*].languageOptions.value
$.projects[*].languageOptions.names[*].language
$.projects[*].languageOptions.names[*].name
$.projects[*].paramEnumMapping
$.projects[*].mapResultSetEnums
$.projects[*].defaultDatabase
$.projects[*].descriptionAttributeClassName
$.projects[*].descriptionAttributeNamespaceName
$.projects[*].enumMappings[*].schema
$.projects[*].enumMappings[*].nameMatch
$.projects[*].enumMappings[*].namePattern
$.projects[*].enumMappings[*].escapeChar
$.projects[*].enumMappings[*].isSetOfFlags
$.projects[*].enumMappings[*].nameColumn
$.projects[*].enumMappings[*].description
$.projects[*].enumMappings[*].descriptionColumn
$.projects[*].enumMappings[*].descriptionAttributeClassName
$.projects[*].enumMappings[*].descriptionAttributeNamespaceName
$.projects[*].storedProcedureMappings[*].schema
$.projects[*].storedProcedureMappings[*].nameMatch
$.projects[*].storedProcedureMappings[*].namePattern
$.projects[*].storedProcedureMappings[*].escapeChar
$.projects[*].storedProcedureMappings[*].languageOptionsReset[*].language
$.projects[*].storedProcedureMappings[*].languageOptionsReset[*].name
$.projects[*].storedProcedureMappings[*].languageOptionsSet[*].language
$.projects[*].storedProcedureMappings[*].languageOptionsSet[*].name
$.projects[*].nameNormalizations[*].namePart
$.projects[*].nameNormalizations[*].namePartType
```

Enumerated references (`classAccess`, `language`, `paramEnumMapping`, `nameMatch`, `namePartType`) are exported as their `[Name]` string from the corresponding `[Enum].*` table, never as an `Id`. Enum `Id` values are static data and could in principle be renumbered; names are the contract.

### Duplicate detection

Two distinct problems, with distinct handling:

- **Duplicate JSON properties** within one object. SQL Server's `JSON_VALUE` silently takes the last occurrence, so a malicious or malformed package could hide a value. `OPENJSON` with the default schema returns one row per key, so the importer detects duplicates by counting keys per object and rejecting any object where a key appears more than once. This check runs on every object the importer parses, not only the root.
- **Duplicate projects** within one package, by `name` (compared using the target database's collation, because that is the collation the target's uniqueness constraint uses) and independently by `uid`. Either duplicate rejects the package during validation, before any planning. A package with duplicate project names is malformed, not a conflict to be resolved.

### Package checksum

- Algorithm: `HASHBYTES('SHA2_256', @canonicalPayload)`, rendered lowercase hex with a `sha256:` prefix. `HASHBYTES` accepts `NVARCHAR(MAX)` on SQL Server 2016 and later, so this is safe on the 2017 floor.
- **The hashed payload is the concatenation of `$.projectFormatVersion` and the canonical `$.projects` array only.** It deliberately excludes `$.package` (self-referential and volatile) and `$.introducedElements` (descriptive, and its absence must not be maskable by a checksum mismatch — it is validated structurally instead).
- The checksum proves *transport integrity and canonical-form stability*. It is not a signature and provides no tamper evidence against a motivated attacker. Documentation must say so; a wrong claim here is worse than no claim.
- A checksum mismatch is a hard package rejection.
- A **missing** checksum is also a hard rejection: `$.package.checksum` is required from format 1, so "old packages had no checksum" can never become an excuse.

## Project format version

`ProjectFormatVersion` is independent from:

- TigerWrap release version;
- TigerWrapDb schema version;
- `[dbo].[SchemaVersion].[ApiLevel]`;
- `[dbo].[SchemaVersion].[MinApiLevel]`.

The project format version changes only when the logical import/export contract changes.

Internal schema changes alone must not force a new project format version.

Examples of changes that may justify a project format bump:

- a new exported field;
- a new exported flag;
- a changed logical structure;
- changed meaning of an existing exported element;
- a migration requirement between logical formats.

Storage:

```sql
-- [dbo].[SchemaVersion]
[ProjectFormatVersion] INT NOT NULL CONSTRAINT [DF_SchemaVersion_ProjectFormatVersion] DEFAULT (1)
```

`[dbo].[SchemaVersion]` is an append-only history table read with `TOP (1) … ORDER BY [Id] DESC`. A new accessor `[DbInfo].[GetProjectFormatVersion]()` reads it with exactly the same `TOP (1) … ORDER BY [Id] DESC` shape, so the reported project format version and the reported schema version always come from the same row. See [Invariant I7](#invariants).

**How the value reaches the CLI.** Not by extending `[Toolkit].[GetDbInfo]` — see [Invariant I1](#invariants). A separate, additive procedure carries capability information, and the CLI tolerates its absence:

```sql
[Toolkit].[GetDbCapabilities]
    @projectFormatVersion   INT     OUTPUT,   -- native format this DB writes
    @maxImportFormatVersion INT     OUTPUT,   -- native + 1, per the one-step-forward rule
    @errorMessage           NVARCHAR(2000) OUTPUT
```

The CLI calls it and treats SQL error 2812 ("could not find stored procedure") as "this database predates capability discovery", exactly as `DbCommandSupport.ProbeAsync` already does for `GetDbInfo`. This keeps the 0.9.2 CLI able to probe and upgrade 0.9.0 and 0.9.1 databases, which is a headline 0.9.2 feature.

## Compatibility contract

For a TigerWrapDb whose native project format version is `x`:

- it must import all earlier format versions;
- it must import format `x`;
- it must import format `x + 1`;
- importing `x + 1` may drop unsupported newly introduced fields or flags;
- all actual data loss must be identified and shown to the user;
- explicit confirmation is required before lossy import;
- formats newer than `x + 1` must be rejected;
- format `0` or any non-positive or non-integer value is rejected as malformed, not as "too old".

This one-step-forward rule is mandatory.

A proposed format change that cannot be safely imported by version `x` cannot be introduced directly as format `x + 1`. It requires preparation in an earlier release.

This creates deliberate release discipline.

### Unknown-path detection is authoritative

The original weakness of a metadata-only approach: `introducedElements` is *self-declared by the producer of the package*. A format-`x` importer that trusts it is trusting an untrusted file to describe what the importer cannot understand. A producer that omits an entry — through a bug, an incomplete release, or malice — causes exactly the silent data loss the design forbids.

**The importer therefore does not rely on `introducedElements` to find what it does not understand. It finds that structurally.**

Mechanism:

1. TigerWrapDb holds a **canonical path registry** for its own native format (the list under [JSON path conventions](#json-path-conventions), stored as data — see `[Static].[ProjectFormatElement]`).
2. On import, the importer shreds the package with `OPENJSON` and enumerates every path actually present.
3. Any path present in the package but absent from the registry is an **unknown path**.
4. Any path present in the registry but absent from the package is a **missing path** and rejects the package as malformed for its declared format — this is what `INCLUDE_NULL_VALUES` buys.
5. Unknown paths at format `x + 1` are the authoritative loss set. `introducedElements` is then consulted **only** to attach a human-readable description, severity, and default to each unknown path.
6. An unknown path with **no** corresponding `introducedElements` entry rejects the package: the producer failed to describe its own extension, and TigerWrap will not guess. This is a normative rule, not merely a test case.
7. An `introducedElements` entry that describes a path **not** present in the package is ignored, not an error. Producers legitimately ship the full registry delta for their format even when a given package does not exercise every element.

Consequences: `introducedElements` becomes *descriptive*, not *load-bearing for correctness*. A lying package cannot cause silent loss; it can only cause rejection.

### Restrictions this places on future format evolution

Because a format-`x` importer must be able to make sense of format `x + 1` using only structural comparison plus descriptions, every format `x + 1` is restricted to changes that are *ignorable* by construction:

| Change in `x + 1` | Allowed? | Why |
| --- | --- | --- |
| Add an optional scalar property to an existing object | Yes | `x` sees an unknown path, can drop it, and the remaining object is still valid format `x`. |
| Add a new optional array whose parent object exists in `x` | Yes | Same. The whole array is one unknown path prefix. |
| Add a new element to an existing enumerated reference (e.g. a new `nameMatch` name) | **No** — this is a *value* change, not a path change, and structural comparison cannot see it. Must be introduced as a prepared change: `x` must already tolerate unknown enumerated values, or the value must not be usable until `x + 2`. |
| Add a new `(language, name)` flag | Yes | Flags are values, but they live at a registry-backed path and are explicitly enumerated in `introducedElements.flags`; the importer compares against `[Static].[LanguageOption]` directly, not against the path registry. |
| Make an existing optional property required | No | `x` cannot know; it would produce a valid-looking but semantically wrong project. |
| Remove a property that existed in `x` | No | Violates the missing-path rule. Deprecate by making it always `null` first; remove only after every supported importer treats it as ignorable. |
| Change a property's type or cardinality | No | Requires a preparation release in which `x` learns to accept both shapes. |
| Change the meaning of an existing property | No | Structurally invisible; always requires a new path plus a preparation release. |
| Rename a property | No | Equivalent to remove + add. |
| Add a root-level property | Yes, subject to the frozen five | See [Package envelope](#package-envelope). |

**This table is the real compatibility contract.** The one-step-forward rule is only achievable because the permitted change set is this narrow. Any proposal outside it needs a preparation release, and that is the intended cost.

### Full backward compatibility

A newer TigerWrap version must import every earlier published project format.

For example, a format 4 importer must support:

```text
format 1
format 2
format 3
format 4
format 5 with one-step-forward loss handling
```

**Decision for 0.9.2:** the backward path is implemented as **explicit stepwise migration functions** (`1 -> 2`, `2 -> 3`, …), each of which upgrades a package's `projects` array in place to the next format, so that only the current-format importer ever touches the database.

Rationale over the alternatives:

- *Direct deserialization into the current model* concentrates every historical special case into one procedure that grows without bound and cannot be tested per-step.
- *Normalization through an intermediate canonical model* adds a third format that must itself be versioned.
- Stepwise migration is testable in isolation (`golden(n) -> migrate -> equals golden(n+1) modulo new elements`), and each function is written once and frozen.

In 0.9.2 there are zero migration functions, because there is exactly one format. What 0.9.2 must deliver is the **dispatch point** — a single procedure that inspects `$.projectFormatVersion` and routes through the (currently empty) chain — so that format 2 is an addition rather than a redesign.

The compatibility behavior is the contract. The internal migration architecture may evolve within it.

## Metadata for format elements

TigerWrapDb needs metadata describing the elements of each project format version. This table is both the path registry used for structural detection and the source of the `introducedElements` block written into exports.

```sql
CREATE TABLE [Static].[ProjectFormatElement] (
    [Id]                  SMALLINT       IDENTITY (1, 1) NOT NULL,
    [ElementId]           VARCHAR (100)  NOT NULL,  -- stable, rename-proof key
    [IntroducedInVersion] INT            NOT NULL,
    [JsonPath]            NVARCHAR (400) NOT NULL,  -- canonical, [*] for collections
    [ContainingEntity]    VARCHAR (30)   NOT NULL,  -- Package | Project | EnumMapping | StoredProcMapping | NameNormalization
    [ElementKind]         VARCHAR (20)   NOT NULL,  -- Scalar | Object | Collection | EnumRef | FlagSet
    [DataType]            VARCHAR (30)   NOT NULL,  -- string | int | bool | guid | datetime | array | object | null
    [Cardinality]         VARCHAR (10)   NOT NULL,  -- One | Many
    [IsRequired]          BIT            NOT NULL,  -- required *within its declaring format*
    [LossSeverity]        VARCHAR (20)   NOT NULL,  -- None | Cosmetic | Behavioral | Structural
    [DefaultWhenAbsent]   NVARCHAR (200) NULL,      -- literal an older importer substitutes
    [Description]         NVARCHAR (1000) NOT NULL,
    CONSTRAINT [PK_ProjectFormatElement] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_ProjectFormatElement_ElementId] ON [Static].[ProjectFormatElement] ([ElementId]);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_ProjectFormatElement_JsonPath] ON [Static].[ProjectFormatElement] ([JsonPath]);
```

The extra columns beyond `(version, path, description)` are not speculative; each is required by a behavior this document specifies:

| Column | Required by |
| --- | --- |
| `ElementId` | Migration functions must key on something a rename cannot break, and loss reports must be stable across localizations. |
| `ContainingEntity` | Loss must be reported *per affected project*, which means knowing whether an unknown path sits on the package, a project, or a child collection row. |
| `ElementKind`, `DataType`, `Cardinality` | Validation of a same-format package (type and shape checking) and correct `[]`-vs-`null`-vs-omitted handling. |
| `IsRequired` | The missing-path rule needs to know whether absence is malformed or merely "not in that format". |
| `LossSeverity` | Determines whether a lossy import may be offered at all. `Structural` loss is **not** offerable — it is a rejection. `Cosmetic` and `Behavioral` loss may be confirmed. Without this, every warning reads identically and users learn to click through. |
| `DefaultWhenAbsent` | The loss message must state what the value *becomes*, not only what is dropped. "`nullableReferenceTypes` will be ignored" is much weaker than "`nullableReferenceTypes` will be ignored; generation will behave as if it were `false`." |

**Is `introducedElements` metadata sufficient by itself?** No — and this is the central correction to the earlier design. It is necessary for *explaining* loss and insufficient for *detecting* it. Detection is structural (see above). The table serves both roles: registry for detection, and payload for explanation.

## Metadata for newly introduced flags

`[Static].[LanguageOption]` gains a column recording the project format version in which the flag was introduced.

```sql
[IntroducedInProjectFormatVersion] INT NOT NULL
    CONSTRAINT [DF_LanguageOption_IntroducedInProjectFormatVersion] DEFAULT (1)
```

All seven options that exist in 0.9.1 default to `1`.

Flags are detected differently from fields: a flag is a *value* at a known path, so the importer compares each `(language, name)` pair in the package against `[Static].[LanguageOption]` directly. An unknown pair is a loss event. `introducedElements.flags` supplies its description and severity, and — as with fields — an unknown pair with no matching `introducedElements.flags` entry rejects the package.

**Do flags need identifiers beyond display names?** Today `(LanguageId, Name)` *is* the identity, enforced by `UX_LanguageOption_LanguageId_Name`, and `Name` doubles as the CLI-facing token parsed by `ToolkitHelper.ResolveLanguageOptionsAsync`. Introducing a second identifier would create two sources of truth for the same concept and a rename would then be silently permitted, corrupting existing packages.

**Decision:** do not add a separate flag identifier. Instead promote the existing pair to a contract — see [Invariant I5](#invariants): a published `(language, name)` pair is immutable; renaming an option is a breaking format change requiring a preparation release, and a retired option must remain present as a non-primary alias so old packages continue to resolve.

## Introduced-elements metadata in exported JSON

An export carries metadata for the fields and flags introduced in **its own** project format version — not the cumulative history, which an importer at `x` already has for every version up to `x`.

```json
{
  "projectFormatVersion": 2,
  "introducedElements": {
    "fields": [
      {
        "elementId": "project.nullableReferenceTypes",
        "jsonPath": "$.projects[*].nullableReferenceTypes",
        "containingEntity": "Project",
        "elementKind": "Scalar",
        "dataType": "bool",
        "cardinality": "One",
        "isRequired": true,
        "lossSeverity": "Behavioral",
        "defaultWhenAbsent": "false",
        "description": "Emits nullable reference type annotations in generated code."
      }
    ],
    "flags": [
      {
        "language": "CSharp",
        "name": "NullableReferenceTypes",
        "lossSeverity": "Behavioral",
        "defaultWhenAbsent": "off",
        "description": "Enables a newly introduced generation option."
      }
    ]
  }
}
```

For a format-1 export both arrays are empty (`[]`, never omitted): format 1 introduces everything, and no earlier importer exists.

The older importer warns only about introduced fields and flags that are **actually present and meaningful** in the imported package — a project that never sets a new flag loses nothing by having that flag dropped. It must not display warnings for unused features.

## Export validation

Export must be verified before being reported as successful.

```text
serialize in TigerWrapDb
-> compute checksum over the canonical payload
-> write file
-> read file back
-> verify byte-for-byte equality with what was written
-> hand the file contents back to TigerWrapDb for validation
-> validate JSON and envelope
-> recompute and compare checksum
-> verify project identities and counts
-> compare the reconstructed logical data with the source
-> report success
```

The read-back step is not ceremony: it is the only thing that catches encoding damage, truncation, and a partially flushed file, which are the realistic export failure modes.

Export fails if:

- JSON is malformed;
- required metadata is missing;
- the package cannot be deserialized;
- project counts or identities do not match;
- introduced field/flag metadata is incomplete;
- the checksum does not reproduce;
- the file read back differs from the file written;
- logical verification fails.

On failure the partial file is deleted, unless deletion itself fails, in which case the path is reported and left in place with a non-zero exit code. Export never leaves a file that looks valid but is not.

**Encoding:** packages are written as UTF-8 **without** a BOM, LF line endings, no trailing newline after the closing brace. Import accepts UTF-8 with or without a BOM (users' editors add them) but the checksum is computed over the decoded text, so a BOM never changes the checksum.

Export is deterministic: two exports of the same logical projects from the same database produce identical `$.projects` arrays and identical checksums. `$.package.createdAtUtc` and provenance differ, by design and outside the checksum.

## Internal package storage

TigerWrapDb contains a table storing canonical import/export JSON and associated metadata. The JSON uses the same canonical package format as external export files. **No separate internal snapshot format exists.**

```sql
CREATE TABLE [History].[ProjectPackage] (
    [Id]                   INT             IDENTITY (1, 1) NOT NULL,
    [CreatedAtUtc]         DATETIME2 (2)   NOT NULL CONSTRAINT [DF_ProjectPackage_CreatedAtUtc] DEFAULT (sysutcdatetime()),
    [CreatedBy]            NVARCHAR (128)  NOT NULL CONSTRAINT [DF_ProjectPackage_CreatedBy]    DEFAULT (original_login()),
    [OperationTypeId]      TINYINT         NOT NULL,  -- [Enum].[PackageOperationType]
    [ProjectFormatVersion] INT             NOT NULL,
    [TigerWrapDbVersion]   VARCHAR (50)    NOT NULL,
    [TigerWrapVersion]     VARCHAR (50)    NULL,      -- client-reported, may be absent
    [ProjectCount]         INT             NOT NULL,
    [ProjectNames]         NVARCHAR (MAX)  NOT NULL,  -- JSON array, for cheap listing without shredding JsonData
    [Checksum]             VARCHAR (80)    NOT NULL,
    [JsonData]             NVARCHAR (MAX)  NOT NULL,
    [Description]          NVARCHAR (500)  NULL,
    CONSTRAINT [PK_ProjectPackage] PRIMARY KEY CLUSTERED ([Id] ASC)
);
```

Notes on the schema:

- A new schema `[History]` is introduced rather than overloading `[Toolkit]`, because `[Toolkit]` is the generated-wrapper surface and every object added there becomes public API. `[History]` objects are not wrapped in 0.9.2.
- `OperationTypeId` is a real `[Enum]` table (`Export`, `PreReplace`, `Import`), not a string, so it participates in the existing enum-generation machinery if it is ever needed client-side.
- `Status` from the earlier sketch is **removed**. A row exists only if its transaction committed; a status column implies rows that describe failures, which cannot exist under the transaction model below. Failure diagnostics go to the existing `[dbo].[ErrorLog]`.
- `Source` from the earlier sketch is folded into `OperationTypeId` and `Description`.
- `[ProjectNames]` is denormalized deliberately: listing snapshots must not require shredding megabytes of `NVARCHAR(MAX)`.

### Large payload storage

`NVARCHAR(MAX)` is correct and no chunking table is needed, but three constraints follow:

- Any procedure returning a package to the client returns it as a **result set with an `NVARCHAR(MAX)` column**, following the existing `[Toolkit].[GenerateCode]` pattern, never as an `OUTPUT` parameter. `NVARCHAR(MAX)` output parameters are awkward through Dapper and cap at `NVARCHAR(4000)` when a size is not set correctly.
- `SELECT … FOR JSON` executed as a bare statement returns JSON **split across multiple ~2033-character rows** in a single column named `JSON_F52E2B61-…`. Every serialization must assign into a variable first — `SET @json = (SELECT … FOR JSON PATH, INCLUDE_NULL_VALUES);` — and then `SELECT @json AS [Text]`. This is the single most likely implementation bug in the whole feature.
- A package size ceiling is enforced on import before parsing. **Default 64 MB of decoded text**, rejected with a distinct response code. This bounds `OPENJSON` memory and the failure mode of a hostile file.

### Retention

- 0.9.2 **stores** snapshots and never prunes them automatically. Automatic retention is a policy decision users must be able to see before it deletes anything.
- `[History].[ProjectPackage]` is excluded from export and import: packages never contain packages.
- `db install` creates the table empty. `db upgrade` never reads, rewrites, or migrates existing rows — a snapshot is a historical artifact of the format it was written in, and rewriting it would destroy its evidentiary value. Old-format snapshots are readable because the importer supports all earlier formats.
- Documentation must state that snapshots grow unboundedly and how to prune them manually, and that they are included in database backups.

### Snapshot creation inside project transactions

The pre-`Replace` snapshot is written **inside** the project transaction.

Consequence, accepted deliberately: if the project transaction rolls back, the snapshot disappears. This is correct — a rolled-back `Replace` leaves the original project untouched, so the snapshot has nothing to protect. Retaining it would create rows describing states that were never lost.

The failure itself is not lost: it is written to `[dbo].[ErrorLog]` (outside the transaction, or after rollback) and reported in the import result.

## Import phases

Import separates analysis from mutation.

```text
read package (CLI)
-> size and encoding check (CLI)
-> envelope pre-read and early rejection (CLI)
-> hand to TigerWrapDb
-> validate JSON, duplicates, checksum
-> determine format compatibility
-> migrate to the current logical model
-> structural path comparison against the registry
-> resolve enumerated and flag references
-> detect project-name conflicts
-> determine actual data loss
-> build a complete import plan
-> show plan (CLI)
-> resolve conflict actions (CLI)
-> confirm (CLI)
-> execute per project (TigerWrapDb, one transaction each)
-> verify each imported project
-> show final result (CLI)
```

No project is modified while the package is still being interpreted or while conflict decisions are unresolved. `[Toolkit].[AnalyseProjectImport]` must not mutate data; this is enforced by a test that snapshots all four project tables before and after an analysis call and asserts equality.

### Import planning

The plan is a first-class artifact, not console output. `AnalyseProjectImport` returns it as canonical JSON:

```json
{
  "packageFormatVersion": 1,
  "targetFormatVersion": 1,
  "compatibility": "Exact",
  "lossEvents": [],
  "actions": [
    { "sourceName": "OrdersApi", "targetName": "OrdersApi_2", "conflict": "Existing", "action": "AutoRename", "uid": "…", "uidAction": "Regenerate" },
    { "sourceName": "Billing",   "targetName": "Billing",     "conflict": "None",     "action": "Create",     "uid": "…", "uidAction": "Preserve" }
  ],
  "unresolved": []
}
```

- `compatibility` is one of `Older`, `Exact`, `OneStepForward`, `TooNew`, `Malformed`.
- `unresolved` lists actions the caller must decide before execution. A plan with a non-empty `unresolved` array cannot be executed.
- Execution consumes the plan. `[Toolkit].[ImportProject]` takes the package plus **one** resolved action, so the caller cannot execute an action the planner did not produce.

## Transaction model

The model is **one transaction per project**.

Reasons:

- each project remains atomic;
- one failed project does not roll back unrelated successful projects;
- transactions stay smaller;
- conflict handling remains project-specific;
- retrying failed projects becomes practical;
- final reporting can be precise.

The entire package is still fully analyzed before any project transaction begins.

Transaction-per-project means partial success is possible and is a first-class result.

```text
Import completed with partial success.

Succeeded: 6
Skipped:   1
Failed:    1
```

### Transaction and error-handling rules

These are normative because the existing procedures already establish a pattern that must be followed:

- Every mutating procedure sets `XACT_ABORT ON` and uses the `@tranCount = @@TRANCOUNT` / conditional `BEGIN TRANSACTION` / `SAVE TRANSACTION` idiom already used by `[Toolkit].[CreateProject]`, so the procedures compose whether or not the caller opened a transaction.
- `[Toolkit].[ImportProject]` owns exactly one project transaction. The CLI never opens a transaction of its own and never spans two projects in one.
- Isolation is the server default (`READ COMMITTED`). The design does not depend on a stronger level; it depends on the uniqueness constraint `UX_Project_Name` as the final arbiter of name collisions. Two concurrent imports racing for the same name resolve by one of them receiving a duplicate-key error, which is reported as that project's failure and rolls back only that project.
- A failed project transaction never leaves a temporary project behind: the temporary name is created inside the same transaction that would rename it.

### Partial success and exit codes

New `[Enum].[ToolkitResponseCode]` rows are required. They must be added in **one batch** early in 0.9.2, because each addition costs a DB change plus a wrapper regeneration (finding 7 above).

| Name | Meaning |
| --- | --- |
| `ImportPartialSuccess` | At least one project succeeded and at least one did not. |
| `ProjectFormatTooNew` | Package format exceeds native + 1. |
| `ProjectPackageMalformed` | Envelope, JSON, duplicate-key, missing-path, or checksum failure. |
| `ProjectPackageTooLarge` | Payload exceeds the configured ceiling. |
| `LossyImportNotConfirmed` | Loss was detected and confirmation was not supplied. |
| `LossyImportNotPermitted` | A `Structural` loss event was detected; the import cannot be offered. |
| `ImportPlanUnresolved` | Execution was attempted with unresolved conflict actions. |
| `DatabaseNotEmpty` | Reserved here for `db install`; batched with the above. |

`ImportPartialSuccess` is a **non-zero** exit code. Scripts must not treat a partially failed import as success. A `--fail-on-partial=false` style opt-out may be added later; it is not in 0.9.2.

### Retry semantics

Import is **not idempotent**, and pretending otherwise would be a lie: `AutoRename` produces a different name on a second run, and `Replace` will have already replaced.

Defined behavior:

- Re-running an import after a partial failure with `--on-conflict skip` imports exactly the projects that did not previously succeed. This is the supported retry.
- Re-running with `--on-conflict auto-rename` produces *additional* projects. This is a legitimate operation, not a retry, and the plan makes it obvious before execution.
- Persisting a resolved plan to a file so a retry replays identical decisions is **deferred beyond 0.9.2** and recorded in [Decision D8](#d8--is-a-persisted-import-plan-required-in-092).

## Conflict handling

When a project with the same name already exists, the supported actions are:

- **Rename**
- **AutoRename**
- **Skip**
- **Replace**
- **Fail**

Conflict decisions are resolved during planning, before execution.

Name comparison uses the **target database's collation**, because that is the collation `UX_Project_Name` enforces. On a default `Latin1_General_CI_AS` database, `OrdersApi` and `ordersapi` collide; on a case-sensitive database they do not. The plan must display the comparison outcome rather than assume a rule, and documentation must state the dependency.

### Rename

Prompt for a new project name.

Validation must ensure:

- the name is not empty and is not whitespace-only;
- the length is within `NVARCHAR(200)`;
- the name is unique in the target database, in the target's collation;
- the name does not collide with another planned rename **or** with another project being created by the same package;
- the planned mapping is displayed clearly.

```text
OrdersApi -> OrdersApi_Imported
```

### AutoRename

Generate a deterministic unique name.

```text
OrdersApi
OrdersApi_2
OrdersApi_3
```

Rules:

- the suffix search starts at `_2` and increments until a free name is found, checking both the target database and the set of names already claimed by this plan;
- if appending the suffix would exceed 200 characters, the base name is truncated from the right to make room, and the truncation is shown in the plan;
- the search is bounded (1000 attempts) and then fails the project rather than looping;
- random or timestamp-based names are not used;
- the generated name is visible in the import plan before execution.

### Skip

Leave the existing project unchanged and do not import the conflicting package project.

The final report shows the project as skipped. Skipped projects do not make the overall result a partial success on their own — a run in which every conflict was skipped and nothing failed exits `Ok`, with the skip count reported.

### Fail

Treat the conflicting project as failed without modifying it.

Whether the import continues with later projects is controlled by the command execution policy. **Stopping on the first error is the default.** A `--continue-on-error` option enables the alternative. This is the safer default for scripted operation.

### Replace

Replace must preserve the existing project until the incoming project has been imported successfully.

The required project-level transaction is:

1. Serialize the existing project into `[History].[ProjectPackage]` with `OperationTypeId = PreReplace`.
2. Import the incoming project under a guaranteed-unique temporary name.
3. Fully validate the imported temporary project.
4. Delete the existing project.
5. Rename the temporary project to the original target name.
6. Verify the final logical state.
7. Commit.

On any failure, roll back the complete project transaction. The original project must remain unchanged.

Temporary-name rules:

- format `~twimport_{8-hex}` — the leading `~` is not producible through `project add` validation, so a temporary name can never collide with a real project or be mistaken for one;
- uniqueness is verified inside the transaction before use;
- because the name is created and renamed inside one transaction, no cleanup path is needed for orphaned temporaries;
- if a temporary name is ever observed by `project list`, that is a bug, and a test asserts its absence after a forced mid-`Replace` failure.

Step 4's delete must respect the four-table aggregate: children are deleted before the parent, in `ProjectNameNormalization`, `ProjectStoredProc`, `ProjectEnum`, `Project` order. There is no `ON DELETE CASCADE` on the existing foreign keys, so this is explicit work, not a database behavior to rely on.

## Reference resolution on import

Import must resolve references from names to the target database's identifiers. Each has a defined failure mode.

| Reference | Resolution | If unresolvable |
| --- | --- | --- |
| `classAccess`, `paramEnumMapping`, `nameMatch`, `namePartType` | Name lookup in the corresponding `[Enum]` table | Project fails with the existing `Invalid*` response code. These are static data present in every TigerWrapDb of a compatible API level, so failure means a corrupt package or an out-of-range format. |
| `language` | `[Enum].[Language].[Code]` | Project fails with `InvalidLanguage`. |
| Flag `(language, name)` | `[Static].[LanguageOption]`, `IsPrimary` or alias | Loss event, subject to one-step-forward rules. |
| `defaultDatabase` | See below | See below. |
| `enumMappings[*].schema`, `storedProcedureMappings[*].schema` | **Not resolved.** | Not an error. |

### Schemas are patterns, not resolved references

`[Toolkit].[AddProjectEnumMapping]` only requires `@schema` to be non-empty; it does not check that the schema exists. This is correct and is now a **deliberate contract**: mappings are *matching rules* evaluated at code-generation time against whatever database is targeted then. A project may legitimately be imported into an environment where the application database does not yet exist. Import therefore never validates schema existence, and code generation continues to be the place where a missing schema is reported.

### `defaultDatabase` is the real portability problem

`[Toolkit].[CreateProject]` returns `InvalidDatabase` when `@defaultDatabase` names a database that does not exist on the server — and also when it is `NULL`. Reusing it unchanged makes cross-environment import fail in exactly the scenario the feature exists for. `[Toolkit].[GetProjectDetails]` already takes the opposite view, silently nulling out a `DefaultDatabase` that is not a user database.

**Decision:** import does not call `[Toolkit].[CreateProject]`. It writes the project aggregate through a dedicated internal procedure whose `defaultDatabase` handling is explicit and policy-driven:

```text
--on-missing-database keep    (default) import the value as recorded; report it in the plan as unresolved
--on-missing-database clear   import NULL; the project must be given a database before generating code
--on-missing-database fail    fail that project
--map-database Old=New        rewrite the value during planning; repeatable
```

`keep` is the default because the recorded name is information the user may need in order to fix the environment, and destroying it on import is unrecoverable. The plan always shows which projects have an unresolved `defaultDatabase`, so the state is visible rather than silent.

This also requires `[dbo].[Project].[DefaultDatabase]` to remain genuinely nullable at the storage layer, which it already is.

## Noninteractive conflict policy

Scripted imports need explicit conflict behavior.

```text
--on-conflict rename
--on-conflict auto-rename
--on-conflict skip
--on-conflict replace
--on-conflict fail
```

Rules:

- there is **no default** in non-interactive mode; omitting `--on-conflict` when a conflict exists exits with `ImportPlanUnresolved`;
- `--on-conflict rename` is meaningless without mappings in non-interactive mode and is rejected as an argument error unless every conflicting project has a `--rename` mapping;
- explicit mappings use `--rename OrdersApi=OrdersApi_Imported`, repeatable;
- a `--rename` mapping for a project that does not conflict is an argument error, not a silent no-op — it means the operator's assumptions do not match the target;
- lossy import in non-interactive mode requires `--accept-data-loss`; without it the run exits `LossyImportNotConfirmed`;
- `--accept-data-loss` never permits a `Structural` loss event.

Ambiguous conflicts must never be resolved silently.

## Import verification

Successful SQL execution is not sufficient.

After each project transaction and **before commit**, TigerWrapDb:

- re-serializes the imported project from the four tables using the same export serializer;
- compares it with the expected post-migration, post-policy project object;
- verifies the final project name;
- verifies the resolved flag set;
- verifies child collection counts and content;
- verifies that any intentional loss matches the approved plan — nothing more was dropped, and nothing that was supposed to be dropped survived.

A project transaction is not reported as successful if logical verification fails; the transaction rolls back.

Verifying before commit is what makes the guarantee meaningful. Verifying after commit would only tell the user that their database is already wrong.

The comparison excludes elements the policy intentionally altered: a `Rename`d name, a regenerated `Uid`, a mapped or cleared `defaultDatabase`. These are compared against the *plan*, not against the package.

## Data-loss warnings

Data loss must never be silent.

When an importer at format `x` reads a format `x + 1` package, it:

- identifies unknown paths structurally;
- identifies unknown flags by `(language, name)`;
- determines which are actually populated in this package (a `null` value at an unknown path is not a loss);
- looks up description, severity, and default from `introducedElements`;
- rejects the package if any unknown element lacks an `introducedElements` entry;
- rejects the import if any loss event has severity `Structural`;
- describes the impact per affected project;
- requires explicit confirmation for `Cosmetic` and `Behavioral` loss.

```text
This package uses project format 2.
The target TigerWrapDb supports project format 1 (and can read format 2 with loss).

The following data will be ignored:

Project: OrdersApi
  Field: $.projects[*].nullableReferenceTypes  (Behavioral)
    Emits nullable reference type annotations in generated code.
    After import this project will behave as if the value were: false
  Flag:  CSharp.NullableReferenceTypes  (Behavioral)
    Enables a newly introduced generation option.
    After import this flag will be: off

Project: Billing
  No data will be lost.

Continue with lossy import?
```

## Security and safety

Import files are untrusted input.

TigerWrap validates:

- payload size, before parsing (default ceiling 64 MB decoded);
- text encoding and `ISJSON`;
- envelope shape and the literal `format` discriminator;
- `projectFormatVersion` range;
- checksum;
- duplicate JSON keys in every parsed object;
- required-path presence and unknown-path absence against the registry;
- string lengths against the target column widths, before insert;
- project names against the same rules `project add` enforces;
- duplicate project names and duplicate `uid`s within the package;
- enumerated reference names;
- flag `(language, name)` pairs;
- nesting depth (bounded; `OPENJSON` recursion over hostile input is otherwise unbounded).

**Dynamic SQL must not be generated from untrusted JSON values.** The only identifier constructed from package data is the temporary project name, which is generated by TigerWrap from a hex suffix and never taken from the package. Every value from the package reaches the database as a parameter or as a value in an `OPENJSON … WITH (…)` projection.

Import must not be usable to read the file system: TigerWrapDb never opens files. The CLI reads the file and passes contents as a parameter; `OPENROWSET(BULK …)` is explicitly not used, because it would run under the SQL Server service account against paths the CLI user may not be entitled to.

## Stored procedure surface

```text
[Toolkit].[ExportProjects]          -- read-only; returns package JSON as NVARCHAR(MAX) result set
[Toolkit].[ValidateProjectPackage]  -- read-only; envelope, checksum, structure, duplicates
[Toolkit].[AnalyseProjectImport]    -- read-only; returns the import plan JSON
[Toolkit].[ImportProject]           -- mutating; exactly one planned action, one transaction
[Toolkit].[GetProjectFormatInfo]    -- read-only; native format, max importable, element registry
[History].[StoreProjectPackage]     -- internal; called inside a project transaction
[History].[GetProjectPackage]       -- read-only; snapshot retrieval
```

Design rules for this surface:

- `AnalyseProjectImport` must not mutate data.
- `ImportProject` imports exactly one planned project action, and refuses an action that is not internally consistent with the package it is given.
- Only the `[Toolkit]` procedures are wrapped into `ToolkitDbHelper`; `[History]` stays internal in 0.9.2 so that the snapshot schema can change without an API-level bump.
- Adding these procedures raises `ApiLevel` from 2 to 3. `MinApiLevel` also becomes 3, because the 0.9.2 CLI's generated wrappers will call them. This must be reflected in `ExpectedDbInfo` and `Scripts/Script.Version.sql` together.

## Invariants

These hold for every release from 0.9.2 onward. Breaking one is a breaking change requiring a preparation release.

- **I1 — `[Toolkit].[GetDbInfo]` is frozen.** Its four `OUTPUT` parameters, their names, order, and types may never change. It is the bootstrap probe used against databases of unknown and older versions; extending it makes the 0.9.2 CLI fail with SQL error 8144 against every 0.9.0 and 0.9.1 database and destroys the upgrade path. New capability information is exposed through additive procedures whose absence the CLI tolerates.
- **I2 — The project aggregate is exactly four tables.** Any table added to the project aggregate is a project format change.
- **I3 — Published format versions are immutable.** The serialization of format `n` never changes after release, including ordering, null handling, and checksum scope.
- **I4 — Enumerated references are exported by name, never by `Id`.**
- **I5 — A published `(language, name)` language-option pair is immutable.** Renaming an option is a breaking format change. A retired option remains present as a non-primary alias so that existing packages continue to resolve.
- **I6 — Analysis never mutates.** Every read-only procedure in the surface above is verified by a before/after table comparison test.
- **I7 — Version-bearing reads agree.** `[DbInfo].[GetCurrentVersion]`, `[DbInfo].[GetProjectFormatVersion]`, and `[Toolkit].[GetDbInfo]` all read `[dbo].[SchemaVersion]` with `TOP (1) … ORDER BY [Id] DESC` so they can never report values from different rows. `ProjectFormatVersion` is non-decreasing across ascending `[Id]`.
- **I8 — The exported field set is complete.** A column added to any of the four project tables is either exported or explicitly registered as non-exported, and a test fails otherwise. `[View].[Project]` has already drifted once; this invariant exists to prevent the export contract from drifting the same way.
- **I9 — One transaction per project, never per package.**
- **I10 — `Replace` imports before it deletes.**

## Required testing

Import/export requires unusually strong testing.

For every project format version `x`, tests prove:

- `x` imports every earlier format;
- `x` imports `x`;
- `x` imports `x + 1`;
- `x` identifies actual unsupported fields and flags;
- `x` warns correctly about loss and states the resulting default;
- `x` rejects formats newer than `x + 1`;
- `x` rejects an `x + 1` package whose unknown element is undeclared in `introducedElements`;
- `x` rejects an `x + 1` package containing a `Structural` loss event, even with `--accept-data-loss`;
- export/import round trips preserve logical state (`$.projects` equality, not whole-package equality);
- export is deterministic across repeated runs and across collations;
- malformed packages are rejected: bad envelope, bad checksum, duplicate keys, duplicate project names, missing required path, oversize payload, hostile nesting;
- a failed project import leaves the existing project unchanged;
- `Replace` preserves the original project on failure at each of its seven steps;
- no `~twimport_` project survives a forced mid-`Replace` failure;
- multi-project import produces correct partial-success reporting and a non-zero exit code;
- internal snapshots use the same canonical format as external export;
- `AnalyseProjectImport` leaves all four project tables byte-identical;
- import into a database where `defaultDatabase` does not exist succeeds under `keep` and behaves as specified under `clear`, `fail`, and `--map-database`;
- a column added to a project table without a registry entry fails the completeness test (Invariant I8).

### Golden files and the compatibility matrix

- One golden package per published format version, retained forever under `ItTiger.TigerWrap.Tests/GoldenPackages/format-{n}/`.
- Each golden package exercises every element of its format, including nulls, empty collections, and every enumerated value.
- Golden files are **byte-compared**. A test that only compares parsed structure would not catch ordering, null-handling, or encoding regressions — the exact things determinism is claimed for.
- The matrix is `importer format` × `package format`, and every cell has an expected verdict:

| Importer \ Package | 1 | 2 | 3 |
| --- | --- | --- | --- |
| **1** | Exact | OneStepForward | TooNew |
| **2** | Older | Exact | OneStepForward |
| **3** | Older | Older | Exact |

In 0.9.2 only the `(1, 1)` cell can be exercised with a real database. The `(1, 2)` and `(1, 3)` cells are exercised with **hand-authored synthetic format-2 and format-3 packages** committed as fixtures. Writing these fixtures in 0.9.2 is not optional: they are the only way to prove the one-step-forward machinery works before a format 2 exists, and they are cheap to write now and expensive to reconstruct later.

Real SQL Server-backed tests are required. Serialization-only unit tests are not enough.

## Architecture Decisions Required Before Implementation

Decisions are ordered by how much rework they cause if deferred and then changed.

### D1 — Does `[Toolkit].[GetDbInfo]` get extended, or is it frozen?

- **Question:** How does the CLI learn a database's project format version?
- **Recommended answer:** Freeze `[Toolkit].[GetDbInfo]` permanently. Add `[Toolkit].[GetDbCapabilities]` as an additive procedure, and have the CLI treat SQL error 2812 as "pre-0.9.2 database".
- **Alternatives considered:** (a) Add an `OUTPUT` parameter to `GetDbInfo` — breaks probing of 0.9.0/0.9.1 databases with SQL error 8144 and destroys `db upgrade`, the release's other headline feature. (b) Read `[dbo].[SchemaVersion]` directly from the CLI — bypasses the API surface and makes the storage location part of the contract.
- **Consequences:** One extra procedure and one extra probe round-trip. `DbCommandSupport` gains a fallback path it already has a template for. In exchange, every future capability addition is safe by construction.
- **Timing:** **Must be decided now.** Every other DB-side decision in 0.9.2 depends on it, and getting it wrong is discovered only when a user upgrades from 0.9.1.

### D2 — Does a project get a stable `Uid` in format 1?

- **Question:** Is `Name` the only project identity in the published format, or is a `UNIQUEIDENTIFIER` added and exported from the first format?
- **Recommended answer:** Add `[dbo].[Project].[Uid]` in 0.9.2 and export it in format 1, with the semantics in [Project identity](#project-identity) — recorded, not used for conflict detection.
- **Alternatives considered:** (a) Name-only, add `Uid` in format 2 — every format-1 package would lack it forever, so no importer could ever correlate a pre-`Uid` export with a post-`Uid` project; identity-based reconciliation would be permanently impossible for the first generation of exports. (b) Use a content hash as identity — changes whenever the project changes, which is the opposite of what identity means.
- **Consequences:** One column, one index, one exported field, one line in the upgrade script. Enables later identity-based reconciliation, cross-environment tracking, and unambiguous snapshot attribution with no format change.
- **Timing:** **Must be decided now.** It is cheap today and impossible to retrofit.

### D3 — Is loss detection structural or metadata-driven?

- **Question:** Does a format-`x` importer discover what it cannot understand by trusting the package's `introducedElements`, or by comparing against its own registry?
- **Recommended answer:** Structural detection is authoritative; `introducedElements` supplies descriptions only. An unknown element without a declaration rejects the package.
- **Alternatives considered:** Metadata-driven detection — makes correctness depend on an untrusted file being honest and complete, which contradicts "no silent data loss" and cannot be defended.
- **Consequences:** Requires `INCLUDE_NULL_VALUES` and the missing-path rule, requires the registry as data, and narrows permitted future format changes to the table in [Restrictions this places on future format evolution](#restrictions-this-places-on-future-format-evolution). That narrowing is a feature.
- **Timing:** **Must be decided now.** It determines the shape of the serializer, the registry table, and the validation procedure.

### D4 — Does `introducedElements` carry more than path and description?

- **Question:** Is `(jsonPath, description)` enough?
- **Recommended answer:** No. Carry `elementId`, `containingEntity`, `elementKind`, `dataType`, `cardinality`, `isRequired`, `lossSeverity`, and `defaultWhenAbsent`, per [Metadata for format elements](#metadata-for-format-elements).
- **Alternatives considered:** Minimal metadata plus hard-coded importer knowledge — puts format-2 knowledge into format-1 code, which is exactly what the one-step-forward rule is meant to avoid.
- **Consequences:** A wider static table and a stricter producer obligation. Enables per-project loss attribution, severity-gated rejection, and accurate "the value becomes X" messages.
- **Timing:** **Must be decided now** — the format-1 export writes this block, and its shape is frozen once published.

### D5 — How does import handle a `defaultDatabase` that does not exist on the target?

- **Question:** `[Toolkit].[CreateProject]` rejects it. What does import do?
- **Recommended answer:** Import bypasses `CreateProject` and applies an explicit policy, defaulting to `keep` with the unresolved state shown in the plan. See [`defaultDatabase` is the real portability problem](#defaultdatabase-is-the-real-portability-problem).
- **Alternatives considered:** (a) Reuse `CreateProject` — cross-environment import fails, defeating the feature. (b) Always clear — destroys information irreversibly and silently. (c) Always fail — forces users to hand-edit packages.
- **Consequences:** A new internal write procedure, one more CLI option, and one more column in the plan display. Also creates a second project-creation path that must stay consistent with `CreateProject`'s validation for everything *except* `defaultDatabase`; a test must assert that equivalence.
- **Timing:** **Must be decided now.** It determines whether import reuses or replaces the existing write path.

### D6 — Where does snapshot storage live, and is it wrapped?

- **Question:** `[History]` schema versus `[Toolkit]`, and does the snapshot API become generated public surface?
- **Recommended answer:** A new `[History]` schema, not wrapped in 0.9.2.
- **Alternatives considered:** Put it in `[Toolkit]` — every object there becomes generated public API, so the snapshot schema would be frozen by the API level before its shape has been validated by real use.
- **Consequences:** One new schema plus a `Security/History.sql` file. Snapshot shape stays changeable through 0.9.3 without an API-level bump; the cost is that no CLI command can list snapshots in 0.9.2, which matches the stated scope.
- **Timing:** **Must be decided now** — it is a schema-creation decision baked into the full-deploy artifact.

### D7 — Is the backward-compatibility strategy stepwise migration or direct parsing?

- **Question:** How does a format-4 importer read a format-1 package?
- **Recommended answer:** Stepwise migration functions, with the dispatch point built in 0.9.2 and zero functions in it.
- **Alternatives considered:** Direct parsing per version (untestable growth, no per-step isolation); intermediate canonical model (a third versioned format).
- **Consequences:** In 0.9.2 the cost is one dispatch procedure that currently does nothing but validate and pass through. Deferring it means format 2 requires restructuring the import entry point rather than adding a function.
- **Timing:** **Should be decided now**, but only the dispatch point is built now. The migration-function signature can be refined when format 2 is designed.

### D8 — Is a persisted import plan required in 0.9.2?

- **Question:** Should `AnalyseProjectImport` output be writable to a file and replayable by `ImportProject`?
- **Recommended answer:** No. Deferred beyond 0.9.2. The plan is produced, displayed, and consumed within one command invocation.
- **Alternatives considered:** Persist and replay — a genuinely better automation story, but it makes the plan an externally versioned artifact with its own compatibility contract, which is a second format to maintain in the same release that introduces the first one.
- **Consequences:** Retry in 0.9.2 is "re-run with `--on-conflict skip`", which is documented and sufficient. The plan JSON shape stays internal and changeable.
- **Timing:** **May be deferred.** The plan is already emitted as JSON, so persisting it later is additive.

### D9 — What is the package size ceiling and is it configurable?

- **Question:** How large a package will import accept?
- **Recommended answer:** 64 MB of decoded text, fixed, with a distinct response code. Not configurable in 0.9.2.
- **Alternatives considered:** No ceiling (unbounded `OPENJSON` memory on hostile input); a configurable ceiling (a setting with no established storage location, since TigerWrap has no config file).
- **Consequences:** A project aggregate is small; 64 MB is several orders of magnitude above any realistic package, so the ceiling only ever fires on corrupt or hostile input.
- **Timing:** **May be deferred** to implementation, but the response code must be in the batch added early.

### D10 — Does export offer to omit provenance?

- **Question:** `sourceServer` and `sourceDatabase` may be considered sensitive in regulated environments.
- **Recommended answer:** Include them by default, with `--no-provenance` to write `null`. They are already outside the checksum, so omitting them changes nothing structurally.
- **Alternatives considered:** Always omit (loses genuinely useful diagnostic context); always include (a hard blocker for some users, discovered late).
- **Consequences:** One CLI option and one export parameter.
- **Timing:** **May be deferred** to implementation. The fields are nullable from format 1, so the capability exists whether or not the option ships in 0.9.2.

## Design principles

1. Export files are durable user assets.
2. No silent data loss.
3. Loss is detected structurally, never by trusting the package.
4. No mutation during analysis.
5. One transaction per project.
6. Replace must import first and delete later.
7. Verification happens before commit, not after.
8. External exports and internal snapshots use one canonical format.
9. New versions import all earlier formats.
10. Version `x` imports `x + 1`, and the permitted change set is narrow enough to make that true.
11. Format changes require logic, not merely schema changes.
12. The database owns the logical model; the CLI owns the workflow.
13. Compatibility rules are part of the product contract.
