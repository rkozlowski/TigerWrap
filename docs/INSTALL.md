# 🛠 INSTALL.md — Installing TigerWrapDb (v0.9.0)

TigerWrap requires a dedicated SQL Server database to store its metadata, such as:
- Project definitions
- Enum mappings
- Stored procedure selections
- Code generation settings

This database is called **TigerWrapDb**.

> ⚠️ **Do not install TigerWrapDb in a production database or mix it with application data.**
> It is strictly a development-time metadata store.

---

## 📋 Prerequisites

| Requirement             | Details                                     |
|-------------------------|---------------------------------------------|
| SQL Server version      | SQL Server 2017 or later                    |
| Admin permissions       | You must be able to create schemas, types, etc. |
| SQL Server Management Studio (SSMS) | Required to run the script with SQLCMD mode enabled |
| CLI installer           | [Download TigerWrapSetup_0_9_0.exe](https://github.com/rkozlowski/TigerWrap/releases) |
| Full deploy script      | [Download TigerWrapDb_FullDeploy_v_0.9.0.sql](https://github.com/rkozlowski/TigerWrap/releases) |

---

## 🏗 Step-by-Step Installation

### 🔹 Step 1: Manually Create an Empty Database

In SSMS (or similar), run:

```sql
CREATE DATABASE [TigerWrapDb];
```

You must create the database yourself. TigerWrap does **not** create it automatically.

---

### 🔹 Step 2: Download the Installation Script

Get the latest version of:

- [`TigerWrapDb_FullDeploy_v_0.9.0.sql`](https://github.com/rkozlowski/TigerWrap/releases)

Place it in any working directory.

---

### 🔹 Step 3: Edit the `:setvar` Value in the Script

Open the script in SSMS and locate the first few lines:

```sql
:setvar DatabaseName "TigerWrapDb"
USE [$(DatabaseName)]
```

If your database name is different, update `"TigerWrapDb"` to match.

---

### 🔹 Step 4: Enable SQLCMD Mode in SSMS

- In SSMS:  
  Go to `Query` → `SQLCMD Mode` (ensure it's checked)

- Or press:  
  `Alt + Q`, then `M`

> ⚠️ The install script uses SQLCMD features like `:setvar`.  
> Without SQLCMD mode, the script **will not run correctly**.

---

### 🔹 Step 5: Run the Script

With SQLCMD mode enabled and `:setvar` updated, execute the script.

This will:
- Create schemas
- Add tables, views, types, and stored procedures
- Register the installed version and API level

---

### 🔹 Step 6: Verify the Installation

Run the following SQL to confirm installation and version:

```sql
DECLARE @return_value INT,
        @dbName NVARCHAR(128),
        @version NVARCHAR(50),
        @apiLevel TINYINT,
        @minApiLevel TINYINT;

EXEC @return_value = [Toolkit].[GetDbInfo]
     @dbName = @dbName OUTPUT,
     @version = @version OUTPUT,
     @apiLevel = @apiLevel OUTPUT,
     @minApiLevel = @minApiLevel OUTPUT;

SELECT @return_value AS [@return_value],
       @dbName       AS [@dbName],
       @version      AS [@version],
       @apiLevel     AS [@apiLevel],
       @minApiLevel  AS [@minApiLevel];
```

#### Expected Output:
- `@version` = `0.9.0`
- `@dbName` = **`TigerWrapDb`** ← *logical name, not actual database name*
- API levels should reflect compatibility

> **Note:** `@dbName` is a *logical identifier*, not the physical database name.  
> It is used by the CLI and upgrade scripts to verify you're connected to a valid TigerWrap database, regardless of what the actual database is called.

---

## 🔐 Where Not to Install

| Environment      | Allowed? | Reason |
|------------------|----------|--------|
| Local dev server | ✅ Yes   | Typical installation target |
| Shared dev server| ✅ Yes   | As long as it's not production |
| UAT/staging      | ❌ No    | Never used at runtime |
| Production       | ❌ No    | Dangerous and unsupported |

---

## 🧰 What the Script Installs

| Component Type     | Location                   |
|--------------------|----------------------------|
| Tables             | `[dbo]`, `[Enum]`, etc.    |
| Stored Procedures  | `[Toolkit]`, `[Internal]`  |
| Views              | `[View]`                   |
| Types (TVPs, UDTs) | `[dbo]`                    |
| Sequences          | `[dbo]`                    |
| Version tracking   | `[dbo].[SchemaVersion]`, `[Toolkit].[GetDbInfo]` |

---

## 🧼 Upgrade Path

If you're upgrading from a previous version (e.g. `v0.8.5`), use:

- [`TigerWrapDb_Upgrade_v_0.8.5_to_0.9.0.sql`](https://github.com/rkozlowski/TigerWrap/releases)

Follow the same rules: edit `:setvar`, enable SQLCMD mode, run script.

---

## ✅ What Next?

Once installed, you can begin using the TigerWrap CLI:

```bash
tiger-wrap connections add
tiger-wrap projects add
tiger-wrap projects sp add
tiger-wrap generate-code
```

➡️ See [`CLI.md`](./CLI.md) for full usage instructions.
