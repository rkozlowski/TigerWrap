# TigerWrap

<img src="https://raw.githubusercontent.com/rkozlowski/TigerWrap/main/docs/assets/TigerWrap256.png" alt="TigerWrap Logo" width="80"/>

**TigerWrap** is a schema-first code generator for SQL Server. It creates clean, strongly-typed C# wrappers for your stored procedures and enums — no ORM required.

Designed for developers who want to keep their SQL logic in the database and call it with confidence from their applications.

---

## ⚠️ Use With Care

**TigerWrap is a power tool**.
Like any power tool, it gives you precision, speed, and control — but if you use it carelessly, you can hurt yourself.

TigerWrap does **not** abstract away SQL. It doesn’t try to “save” you from poor design, long-running transactions, or mismatched assumptions between layers. Instead, it assumes:

- You **know your schema**.
- You **respect your stored procedures**.
- You **want clean separation** between your data logic and your application code.

> **Used wisely**, TigerWrap gives you exactly what you ask for — no more, no less.

---

## ✨ Features

- ✅ Stored procedure wrappers with input/output/return handling  
- ✅ Enum table detection and C# enum generation  
- ✅ CLI-first workflow, scriptable and automatable  
- ✅ No runtime dependency — generate once, use anywhere  

---

## 🚀 Quickstart

```bash
tiger-wrap connections add
tiger-wrap projects add
tiger-wrap projects sp add
tiger-wrap generate-code
```

This sets up a project and generates your C# wrapper class.  
For details, see [docs/CLI.md](docs/CLI.md).

---

## 📦 Installation

1. Install the TigerWrap database (TigerWrapDb)  
2. Download and run the [TigerWrap CLI Installer](https://github.com/rkozlowski/TigerWrap/releases)

See [docs/INSTALL.md](docs/INSTALL.md) for full instructions.

---

## 📚 Documentation

- [docs/README.md](docs/README.md) — full documentation  
- [docs/ENUMS.md](docs/ENUMS.md) — enum mapping guide  
- [docs/WRAPPERS.md](docs/WRAPPERS.md) — stored procedure wrappers  
- [docs/CLI.md](docs/CLI.md) — CLI usage  
- [docs/INSTALL.md](docs/INSTALL.md) — database setup  

---

## 🔧 Status

TigerWrap v0.9.0 is a **beta release**.  
It is already stable and useful — and evolving quickly.

---

## 🛡️ Copyright & Project Sponsor

<p align="left">
  <img src="https://raw.githubusercontent.com/rkozlowski/TigerWrap/main/docs/assets/ItTiger-head.png" alt="IT Tiger Logo" width="120"/>
</p>

TigerWrap is an open-source project by **IT Tiger**  
🔗 https://www.ittiger.net/
