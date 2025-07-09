# 🚀 CLI.md — Using the TigerWrap CLI

TigerWrap is a CLI-first tool designed to make calling SQL Server stored procedures and working with enum tables easy and reliable from C#.

This guide gives a practical overview of how to use the CLI to define projects, select stored procedures, and generate wrapper code.

---

## 🧭 Discovering Commands

To explore available commands:

```bash
tiger-wrap --help
```

This will list top-level command groups like `connections`, `projects`, and `generate-code`.

To see help for a specific command:

```bash
tiger-wrap <command> --help
```

Examples:

```bash
tiger-wrap connections add --help
tiger-wrap projects sp add --help
```

---

## ⚙️ Interactive vs Non-Interactive Mode

Most commands run in **interactive mode** by default, prompting for values.

For scripting or automation, you can use the `--non-interactive` flag:

```bash
tiger-wrap connections add MyConn --server . --db TigerWrapDb --auth Integrated --trust-server-cert Yes --non-interactive
```

---

## 🧩 Key Concepts

### 🔌 Connection

A **connection** is a reference to your **TigerWrap metadata database**, not your application database.

TigerWrap needs a place to store project definitions, enum mappings, and code generation settings. This metadata is stored in a dedicated TigerWrapDb on your dev SQL Server.

You can register multiple connections if you work across different environments.

---

### 📁 Project

A **project** defines:
- Which database (on your SQL instance) to analyze
- Which stored procedures and enums to wrap
- How the generated C# code should look (language, namespace, class name)

Each project is stored in the TigerWrap metadata database and can be updated, inspected, and regenerated anytime.

---

## ⚙️ Typical Workflow

Once your TigerWrap database is installed, a typical CLI workflow looks like this:

---

### 🔹 1. Add a Connection

Add a connection to your **TigerWrapDb** metadata database:

```bash
tiger-wrap connections add --name MyLocalTigerWrap --server . --auth Integrated
```

This will prompt for:
- Trust server certificate option
- TigerWrap database (select your TigerWrapDb)

---

### 🔹 2. Add a New Project

Define a new code generation project:

```bash
tiger-wrap projects add MyLocalTigerWrap TestDbProject   --language-name c#   --namespace MyCompany.MyTestApp   --class DbHelper
```

This defines how the generated C# code should be structured.

---

### 🔹 3. Add Stored Procedure Mapping

Specify which stored procedures to include:

```bash
tiger-wrap projects sp add MyLocalTigerWrap TestDbProject   --schema Oltp --nameMatch Prefix --namePattern User
```

This will include all procedures starting with `User` from the `Oltp` schema.  
You can use other name matching methods like `ExactMatch`, `Suffix`, `Like`, or `Any`.

---

### 🔹 4. (Optional) Add Enum Mapping

If your application uses enum-style tables, you can map them:

```bash
tiger-wrap projects enum add MyLocalTigerWrap TestDbProject   --schema Enum --nameMatch Any
```

TigerWrap will generate corresponding C# enums.

---

### 🔹 5. Generate Code

Generate the wrapper code:

```bash
tiger-wrap generate-code MyLocalTigerWrap TestDbProject
```

This will analyze the database, apply your mappings, and output a `.cs` file with the generated code.

---

## ✅ What Next?

You can now:

- Add additional stored procedure or enum mappings  
- Update project settings (namespace, class name, etc.)  
- Regenerate code at any time as your database evolves

If your project follows TigerWrap’s recommended structure — using dedicated schemas for enums and stored procedures — you will **rarely need to modify the project definition**.

In most cases, simply running:

```bash
tiger-wrap generate-code <Connection> <Project>
```

is enough after:

- Adding a new enum table
- Adding a new stored procedure
- Changing rows in an enum table
- Modifying stored procedure parameters
- Modifying the result set of a procedure

> 📚 For deeper topics, see:  
> [`ENUMS.md`](./ENUMS.md) — how enum tables work  
> [`WRAPPERS.md`](./WRAPPERS.md) — how procedures are wrapped  
> [`INSTALL.md`](./INSTALL.md) — setting up the TigerWrap database
