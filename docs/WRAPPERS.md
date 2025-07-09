# 📦 WRAPPERS.md — Stored Procedure Wrappers in TigerWrap

TigerWrap generates C# wrapper methods for selected stored procedures, giving you a strongly-typed, convenient way to call SQL logic from your application.

This document explains:

1. What stored procedures are
2. What a wrapper is
3. How TigerWrap identifies and includes stored procedures
4. How input/output parameters and return values are handled
5. Recommended schema usage for stored procedures
6. Requirements for compatibility

---

## 🧾 1. What Is a Stored Procedure?

A **stored procedure (SP)** is a reusable unit of logic stored in a SQL Server database. It can accept input parameters, return output parameters, and execute statements such as queries, inserts, updates, or deletes.

Example:

```sql
CREATE PROCEDURE [dbo].[UserGetById]
    @id INT
AS
BEGIN
    SELECT [Id], [Name], [Email]
    FROM [dbo].[User]
    WHERE [Id] = @id;
END
```

---

## 🧰 2. What Is a Wrapper?

A **wrapper** is a generated C# method that corresponds to a stored procedure. It handles:

- Passing input parameters to the SQL procedure
- Returning result sets as strongly-typed objects
- Retrieving output parameters and return values
- Managing connection and command execution logic

Example (simplified):

```csharp
public async Task<User> UserGetByIdAsync(int id)
{
    ...
}
```

TigerWrap generates wrapper classes based on your project settings (namespace, class name, visibility, etc.).

---

## 🧩 3. How TigerWrap Selects Stored Procedures

Stored procedures are not discovered automatically. You must **explicitly add** them to a TigerWrap project using the CLI:

```bash
tiger-wrap projects sp add <CONNECTION_NAME> <PROJECT_NAME> --schema Oltp --nameMatch Prefix --namePattern User
```

### 🎯 Matching Methods

| Match Type   | Description |
|--------------|-------------|
| `ExactMatch` | Matches a procedure by exact name |
| `Prefix`     | Matches names starting with a given prefix |
| `Suffix`     | Matches names ending with a given suffix |
| `Like`       | Matches names using a SQL `LIKE` pattern (e.g. `%Get%`) |
| `Any`        | Matches all procedures in the specified schema — ideal when the schema is dedicated to a specific app/module |

---

## 🧱 4. Recommended Schema Usage

Stored procedures **can** be created in the `[dbo]` schema, but it is **strongly recommended** to define them in separate, purpose-specific schemas. For example:

| Schema        | Purpose                         |
|---------------|---------------------------------|
| `[Portal]`     | Web-facing API procedures       |
| `[Oltp]`       | Core transactional operations   |
| `[Reporting]`  | Queries for reports or exports  |

### ✅ Advantages

#### 1. Easy Code Management

Adding all procedures in a schema to a TigerWrap project is simple:

```bash
tiger-wrap projects sp add MyConn MyApp --schema Portal --nameMatch Any
```

This ensures new procedures added in future releases are **automatically included** when code is regenerated.

#### 2. Clean Security Model

SQL Server allows granting `EXECUTE` at the schema level:

```sql
GRANT EXECUTE ON SCHEMA::[Portal] TO [portal_user_role];
```

This simplifies role-based access control and avoids needing to update permissions for every new stored procedure.

---

## 📥 5. Input, Output, and Return Values

TigerWrap fully supports:

- **Input parameters** (e.g. `@userId INT`)
- **Output parameters** (e.g. `@statusCode INT OUTPUT`)
- **Return values** (`RETURN 0`)

All of these are exposed in the generated wrapper method signature. Result sets are parsed and mapped to generated model classes.

---

## ✅ 6. Requirements for Stored Procedure Compatibility

To be successfully wrapped, a stored procedure must:

- Be valid and executable on the target SQL Server version
- Have clearly defined input/output parameters
- Use stable result set structure (column names and types)
- Avoid highly dynamic SQL that alters the shape of results

