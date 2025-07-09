<p align="center">
  <a href="https://www.ittiger.net">
    <img src="https://raw.githubusercontent.com/rkozlowski/TigerWrap/main/docs/assets/ItTiger-head.png" alt="IT Tiger Logo" width="120" />
  </a>
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://raw.githubusercontent.com/rkozlowski/TigerWrap/main/docs/assets/TigerWrap256.png" alt="TigerWrap Icon" width="100" />
</p>
# 🐅 TigerWrap

**TigerWrap** is a schema-first code generator for SQL Server. It creates clean, strongly-typed C# wrappers for your stored procedures and enums — no ORM required.

Designed for developers who want to keep their SQL logic in the database and call it with confidence from their applications.

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
