<p align="center">
  <a href="https://www.ittiger.net">
    <img src="https://raw.githubusercontent.com/rkozlowski/TigerWrap/main/docs/assets/ItTiger-head.png" alt="IT Tiger Logo" width="120" />
  </a>
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://raw.githubusercontent.com/rkozlowski/TigerWrap/main/docs/assets/TigerWrap256.png" alt="TigerWrap Icon" width="100" />
</p>

# 🐅 TigerWrap — Documentation Hub

Welcome to **TigerWrap**, a schema-first code generator for SQL Server that produces clean, strongly-typed C# wrappers for stored procedures and enum tables.

This documentation hub provides everything you need to install, configure, and use TigerWrap effectively.

---

## 🎯 Purpose and Philosophy

TigerWrap is **not** an ORM.

Instead, it helps you:
- Treat **stored procedures** as the API surface of your database
- Define **enum tables** as the single source of truth for shared static data
- Generate clean, dependency-free C# code to access them

This promotes:
- Clear boundaries between application logic and data access
- Stable, explicit database contracts
- Testable and maintainable integration

TigerWrap does **not** generate code for:
- Tables or views
- User-defined functions (UDFs)
- Ad hoc SQL queries

---

## 🧱 Core Concepts

### 🔌 Connection
A named reference to your **TigerWrap metadata database** — not your application DB.

### 📁 Project
Defines how code is generated for a target database:
- Language, namespace, class name
- Which stored procedures and enum tables to wrap

### 🧾 Enum Table
A table containing ID-to-name mappings. Used to generate C# `enum` types.

### 🧰 Stored Procedure Wrapper
A generated C# method that calls a stored procedure with proper parameters, result mapping, output handling, and return value support.

---

## 🚀 Typical Workflow

```bash
tiger-wrap connections add
tiger-wrap projects add
tiger-wrap projects sp add
tiger-wrap generate-code
```

If your schema design follows TigerWrap best practices (separate schemas for enums and procedures), most future changes require only:

```bash
tiger-wrap generate-code ...
```

---

## 📚 Available Docs

| File             | Description                                |
|------------------|--------------------------------------------|
| [INSTALL.md](INSTALL.md)   | How to install and upgrade the TigerWrap database |
| [CLI.md](CLI.md)           | Common CLI usage and workflow        |
| [ENUMS.md](ENUMS.md)       | How enum tables are detected and used |
| [WRAPPERS.md](WRAPPERS.md) | How stored procedures are mapped and wrapped |

---

## 🧱 Recommended Practices

- Use dedicated schemas for:
  - Stored procedures (e.g. `[Oltp]`, `[Portal]`, `[Reporting]`)
  - Enum tables (e.g. `[Enum]`)
- Grant `EXECUTE` on schema level — simplifies deployments and upgrades
- Avoid placing enum tables in `[dbo]`

For more reasoning, see:
- [`ENUMS.md`](ENUMS.md)
- [`WRAPPERS.md`](WRAPPERS.md)

---

## 🔄 Versioning & Compatibility

- SQL Server 2017 or newer recommended
- CLI and DB use API levels to track compatibility
- For upgrade logic and version detection, see `Toolkit.GetDbInfo`

---

## 🛠 Roadmap

TigerWrap is currently in **beta** (`v0.9.x`). Planned improvements include:

- Optional GUI (planned for v0.9.5+)
- Better test coverage and validation tools
- Integrated upgrade/installer helpers
- Extensibility model (post-1.0)

---

## 💬 Questions or Feedback?

See the project page at  
🔗 [https://www.ittiger.net/projects/tigerwrap](https://www.ittiger.net/projects/tigerwrap)  
or file issues at  
🔗 [https://github.com/rkozlowski/TigerWrap](https://github.com/rkozlowski/TigerWrap)
