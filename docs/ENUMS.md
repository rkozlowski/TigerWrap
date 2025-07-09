# 🧩 ENUMS.md — Enum Table Detection & Requirements

> **Version Note**: This document describes the *intended behavior* starting with **TigerWrap v0.9.1**.  
> The current engine (v0.9.0) may not fully conform to these rules but will be updated accordingly.

---

## 🧭 Overview

TigerWrap supports generating **C# enums** from SQL Server tables, based on a clean, explicit contract.  
Enum tables are treated as part of your application’s **static data layer** — small, stable lookup tables that define semantic values used across stored procedures and application code.

To ensure precision and predictability, TigerWrap uses a **mapping-based detection model** combined with strict table structure validation.

---

## ✅ What Makes a Table an Enum Table?

To qualify as a valid enum table in TigerWrap, all **three of the following rules** must be satisfied:

| Rule | Description |
|------|-------------|
| **Rule 1** | The table must have a **non-identity integer primary key**. |
| **Rule 2** | The table must have a valid **name column** for enum member names. |
| **Rule 3** | The table must match a **mapping** in `[Toolkit].[ProjectEnumMapping]` for the current project. |

---

## 🔢 Rule 1: Primary Key on Integer Column (No Identity)

- The table must define a **primary key** on a single column.
- The column must be of type: `TINYINT`, `SMALLINT`, `INT`, or `BIGINT`.
- The column **must not** be marked as `IDENTITY`.

This ensures that enum IDs are explicitly defined and stable across environments.

---

## 📛 Rule 2: Name Column Requirements

TigerWrap uses a character column in the enum table to generate the corresponding C# enum member names.

### Case A — `NameColumn` *not specified*

- The table must define **exactly one** `UNIQUE` constraint or `UNIQUE` index on a **single column** of type:
  - `CHAR(n)`
  - `VARCHAR(n)`
  - `NCHAR(n)`
  - `NVARCHAR(n)`
- That column will be used as the name source for C# enum members.
- If **multiple single-column unique indexes or constraints** exist on character-based columns, the table is **rejected** to avoid ambiguity.

### Case B — `NameColumn` *is specified*

- The named column must exist in the table and be of a supported character type (`char`, `varchar`, `nchar`, `nvarchar`).
- There is **no requirement** for a unique constraint or index on that column in this case.
- This is intended for **manual overrides** or **nonstandard schemas**.

---

## 🧠 Rule 3: Enum Table Matching via ProjectEnumMapping

TigerWrap will only consider tables that match a row in `[Toolkit].[ProjectEnumMapping]` for the current project.

Each mapping defines:

| Column        | Description |
|---------------|-------------|
| `Schema`      | The schema where enum tables reside (e.g. `Enum`, `Static`). |
| `NameMatchId` | The matching strategy — see below. |
| `NamePattern` | Table name or pattern used in matching. |
| `EscChar`     | Optional: escape character for `LIKE` pattern matching. |
| `IsSetOfFlags`| If `True`, the generated C# enum will be marked with `[Flags]`. |
| `NameColumn`  | Optional: specifies which column to use for enum member names. |

### 🔍 Matching Strategies

| `NameMatchId` | Behavior |
|---------------|----------|
| `Any`         | Matches all tables in the given schema. |
| `ExactMatch`  | Matches tables whose name exactly matches `NamePattern`. |
| `Prefix`      | Matches tables whose names start with `NamePattern`. |
| `Suffix`      | Matches tables whose names end with `NamePattern`. |
| `Like`        | Uses SQL `LIKE` with `NamePattern`; `EscChar` is optional. |

---

## 🧱 Example: Typical Enum Table

```sql
CREATE TABLE [Enum].[UserType] (
    Id   INT          NOT NULL CONSTRAINT [PK_UserType] PRIMARY KEY,
    Code VARCHAR(50)  NOT NULL CONSTRAINT [UQ_UserType_Code] UNIQUE
);

INSERT INTO [Enum].[UserType] (Id, Code) VALUES
    (1, 'Admin'),
    (2, 'Moderator'),
    (3, 'Guest');
```

Corresponding enum mapping:

```
tiger-wrap projects enum add --schema Enum --nameMatch ExactMatch --namePattern UserType --nameColumn Code
```

Generated C# enum:

```csharp
public enum UserType
{
    Admin = 1,
    Moderator = 2,
    Guest = 3
}
```

## Notes & Best Practices

✅ Place enum tables in a dedicated schema (e.g. Enum, Static). Avoid placing them in [dbo].
✅ Use clear and valid C#-friendly names in your name column.
✅ Name your constraints (PK_, UQ_, etc.) for clarity and consistency.
✅ Avoid naming conflicts by ensuring each enum table matches only one mapping.
✅ Use IsSetOfFlags = 1 in mappings to generate [Flags] enums (bitmask style).
