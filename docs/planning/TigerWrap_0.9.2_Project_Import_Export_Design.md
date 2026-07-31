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

The exact CLI syntax may be adjusted to fit TigerCli conventions.

## Canonical implementation layer

Project JSON should be serialized and deserialized in **TigerWrapDb**, using SQL Server 2017-compatible T-SQL JSON features.

Expected SQL features include:

- `FOR JSON PATH`
- `OPENJSON`
- `JSON_VALUE`
- `JSON_QUERY`
- `ISJSON`

The database should own:

- the logical project model;
- reference resolution;
- project format compatibility;
- conflict analysis;
- import execution;
- snapshot creation;
- post-import verification.

The CLI should orchestrate the workflow, display plans and warnings, read and write files, and select projects and conflict policies.

The CLI should not define a second, independent project serialization model.

## Logical format

The export must represent logical project data, not physical database storage.

It must not expose or depend on:

- identity values;
- physical row IDs;
- implementation-specific relationship keys;
- table layout details that are not part of the logical project contract.

The same logical project should produce equivalent JSON regardless of physical IDs.

The package should be readable, versioned, and self-describing.

A conceptual package header:

```json
{
  "format": "TigerWrap.ProjectExport",
  "projectFormatVersion": 1,
  "createdBy": {
    "tigerWrapVersion": "0.9.2",
    "tigerWrapDbVersion": "0.9.2",
    "databaseApiLevel": 3
  },
  "introducedElements": {
    "fields": [],
    "flags": []
  },
  "projects": []
}
```

The exact shape is still to be designed.

## Project format version

`ProjectFormatVersion` must be independent from:

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

The version should be stored in `[dbo].[SchemaVersion]`, for example:

```sql
ProjectFormatVersion int NOT NULL
```

The final column name should be confirmed before implementation.

## Compatibility contract

For a TigerWrapDb with native project format version `x`:

- it must import all earlier format versions;
- it must import format `x`;
- it must import format `x + 1`;
- importing `x + 1` may drop unsupported newly introduced fields or flags;
- all actual data loss must be identified and shown to the user;
- explicit confirmation is required before lossy import;
- formats newer than `x + 1` must be rejected.

This one-step-forward rule is mandatory.

A proposed format change that cannot be safely imported by version `x` cannot be introduced directly as format `x + 1`. It requires preparation in an earlier release.

This creates deliberate release discipline.

## Full backward compatibility

A newer TigerWrap version must import every earlier published project format.

For example, a format 4 importer must support:

```text
format 1
format 2
format 3
format 4
format 5 with one-step-forward loss handling
```

The implementation strategy can be decided later.

Possible approaches include:

- explicit migration functions such as `1 -> 2`, `2 -> 3`, and `3 -> 4`;
- direct deserialization into a current logical model;
- normalization through an intermediate canonical model;
- a hybrid of direct parsing and version-specific migrations.

The compatibility behavior is the contract. The internal migration architecture may evolve.

## Metadata for newly introduced fields

TigerWrapDb needs metadata describing fields introduced in each project format version.

A new static table should map:

```text
ProjectFormatVersion
JSON path
Description
```

Conceptually:

```sql
[Static].[ProjectFormatField]
(
    ProjectFormatVersion int            NOT NULL,
    JsonPath             nvarchar(1000) NOT NULL,
    Description          nvarchar(1000) NOT NULL
)
```

The final schema and name are to be decided.

The JSON path syntax must be canonical and stable from the first published format.

## Metadata for newly introduced flags

`[Static].[LanguageOption]` should gain a column recording the project format version in which the flag was introduced.

Conceptually:

```sql
ProjectFormatVersion int NOT NULL
    DEFAULT (1)
```

This allows TigerWrap to identify flags unknown to an older importer.

## Introduced-elements metadata in exported JSON

An export file should carry metadata for fields and flags introduced in its own project format version.

This allows an older importer to understand what it must ignore and what data may be lost.

Conceptually:

```json
{
  "projectFormatVersion": 2,
  "introducedElements": {
    "fields": [
      {
        "jsonPath": "$.projects[*].someNewField",
        "description": "Controls a newly introduced project behavior."
      }
    ],
    "flags": [
      {
        "language": "CSharp",
        "name": "SomeNewFlag",
        "description": "Enables a newly introduced generation option."
      }
    ]
  }
}
```

The older importer should warn only about introduced fields and flags that are actually present and meaningful in the imported package.

It should not display irrelevant warnings for unused features.

## Export validation

Export must be verified before being reported as successful.

Expected flow:

```text
serialize
-> write file
-> read file back
-> validate JSON
-> deserialize
-> verify package metadata
-> verify project identities and counts
-> compare reconstructed logical data with the source
-> report success
```

The export should fail if:

- JSON is malformed;
- required metadata is missing;
- the package cannot be deserialized;
- project counts or identities do not match;
- introduced field/flag metadata is incomplete;
- logical verification fails.

Export should be deterministic where practical.

Timestamp and provenance metadata may differ, but project ordering and logical content should be stable.

## Internal package storage

TigerWrapDb should contain a table that stores canonical import/export JSON and associated metadata.

Possible names include:

```text
[History].[ProjectSnapshot]
[Toolkit].[ProjectPackage]
```

The final name and schema should be decided during design.

Potential metadata:

```text
Id
CreatedAt
OperationType
ProjectFormatVersion
TigerWrapVersion
TigerWrapDbVersion
ProjectCount
ProjectNames
JsonData
Checksum
Source
Status
Description
```

The JSON should use the same canonical package format as external export files.

No separate internal snapshot format should be created.

Possible future uses:

- explicit project export history;
- pre-import snapshots;
- pre-replace snapshots;
- pre-delete snapshots;
- automatic storage of the last version before project deletion;
- recovery;
- audit;
- diagnostics;
- future undo or restore workflows.

These future uses do not all need to be exposed in 0.9.2.

## Import phases

Import must separate analysis from mutation.

Expected flow:

```text
read package
-> validate package
-> determine format compatibility
-> migrate to current logical model
-> resolve references
-> detect project-name conflicts
-> determine actual data loss
-> build a complete import plan
-> show plan
-> resolve conflict actions
-> confirm
-> execute per project
-> verify each imported project
-> show final result
```

No project should be modified while the package is still being interpreted or while conflict decisions are unresolved.

## Transaction model

The preferred model is **one transaction per project**.

Reasons:

- each project remains atomic;
- one failed project does not roll back unrelated successful projects;
- transactions stay smaller;
- conflict handling remains project-specific;
- retrying failed projects becomes practical;
- final reporting can be precise.

The entire package must still be fully analyzed before any project transaction begins.

Transaction-per-project means partial success is possible and must be treated as a first-class result.

Example:

```text
Import completed with partial success.

Succeeded: 6
Skipped:   1
Failed:    1
```

A distinct return code for partial success should be considered.

## Conflict handling

When a project with the same name already exists, the supported actions are:

- **Rename**
- **AutoRename**
- **Skip**
- **Replace**
- **Fail**

Conflict decisions should be resolved during planning, before execution.

### Rename

Prompt for a new project name.

Validation must ensure:

- the name is not empty;
- the length is valid;
- the name is unique in the target database;
- the name does not collide with another planned rename;
- the planned mapping is displayed clearly.

Example:

```text
OrdersApi -> OrdersApi_Imported
```

### AutoRename

Generate a deterministic unique name.

Preferred pattern:

```text
OrdersApi
OrdersApi_2
OrdersApi_3
```

Avoid random or timestamp-based names unless there is a strong reason.

The generated name must be visible in the import plan before execution.

### Skip

Leave the existing project unchanged and do not import the conflicting package project.

The final report must show the project as skipped.

### Fail

Treat the conflicting project as failed without modifying it.

Whether the import continues with later projects should be controlled by the command execution policy.

Stopping on first error is the safer default for scripted operation unless an explicit continue-on-error option is provided.

### Replace

Replace must preserve the existing project until the incoming project has been imported successfully.

The required project-level transaction is:

1. Serialize the existing project into the internal snapshot table.
2. Import the incoming project under a guaranteed-unique temporary name.
3. Fully validate the imported temporary project.
4. Delete the existing project.
5. Rename the temporary project to the original target name.
6. Verify the final logical state.
7. Commit.

On any failure, roll back the complete project transaction.

The original project must remain unchanged.

The temporary name should be reserved, diagnosable, and guaranteed unique.

## Noninteractive conflict policy

Scripted imports need explicit conflict behavior.

Conceptually:

```text
--on-conflict rename
--on-conflict auto-rename
--on-conflict skip
--on-conflict replace
--on-conflict fail
```

Explicit rename may require mappings such as:

```text
--rename OrdersApi=OrdersApi_Imported
```

The exact command-line surface should follow TigerCli conventions.

Ambiguous conflicts must never be resolved silently.

## Import verification

Successful SQL execution is not sufficient.

After each project transaction, TigerWrap should:

- read the imported project back;
- serialize or reconstruct its logical model;
- compare it with the expected post-migration model;
- verify the final project name;
- verify expected flags and fields;
- verify any intentional loss matches the approved plan.

A project transaction should not be reported as successful if logical verification fails.

## Data-loss warnings

Data loss must never be silent.

When an importer at format `x` reads a format `x + 1` package, it should:

- identify unsupported introduced fields;
- identify unsupported introduced flags;
- determine which are actually used in the package;
- describe the impact;
- show the affected projects;
- require explicit confirmation.

Example:

```text
This package uses project format 2.
The target TigerWrapDb supports project format 1.

The following data will be ignored:

Project: OrdersApi
- Field: $.projects[*].nullableReferenceTypes
- Flag: CSharp.NullableReferenceTypes

Continue with lossy import?
```

## Security and safety

Import files are untrusted input.

TigerWrap must validate:

- JSON shape;
- required fields;
- version range;
- string lengths;
- project names;
- duplicate projects;
- duplicate properties where practical;
- unknown structural elements;
- invalid flag names;
- invalid enum or option references;
- unexpected nulls;
- payload size;
- maliciously deep or excessive JSON where relevant.

Dynamic SQL must not be generated from untrusted JSON values without strict parameterization or validation.

## Stored procedure surface

A possible database API may include:

```text
[Toolkit].[ExportProjects]
[Toolkit].[ValidateProjectPackage]
[Toolkit].[AnalyseProjectImport]
[Toolkit].[ImportProject]
[Toolkit].[StoreProjectPackage]
[Toolkit].[GetProjectPackage]
```

The final API should be designed around project-level transactions and read-only planning.

`AnalyseProjectImport` must not mutate data.

`ImportProject` should import exactly one planned project action.

## Required testing

Import/export requires unusually strong testing.

For every project format version `x`, tests should prove:

- `x` imports every earlier format;
- `x` imports `x`;
- `x` imports `x + 1`;
- `x` identifies actual unsupported fields and flags;
- `x` warns correctly about loss;
- `x` rejects formats newer than `x + 1`;
- export/import round trips preserve logical state;
- malformed packages are rejected;
- incomplete introduced-elements metadata is rejected;
- a failed project import leaves the existing project unchanged;
- Replace preserves the original project on any failure;
- multi-project import produces correct partial-success reporting;
- internal snapshots use the same canonical format as external export.

Golden package files should be retained for every published project format version.

Real SQL Server-backed tests are required. Serialization-only unit tests are not enough.

## Design principles

1. Export files are durable user assets.
2. No silent data loss.
3. No mutation during analysis.
4. One transaction per project.
5. Replace must import first and delete later.
6. External exports and internal snapshots use one canonical format.
7. New versions import all earlier formats.
8. Version `x` imports `x + 1`.
9. Format changes require logic, not merely schema changes.
10. Compatibility rules are part of the product contract.
