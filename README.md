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
tiger-wrap connection add
tiger-wrap db info
tiger-wrap project add
tiger-wrap project sp add
tiger-wrap generate-code
```

This sets up a project and generates your C# wrapper class.  
For details, see [docs/CLI.md](docs/CLI.md).

---

## 📦 Installation and Updates

WinGet is the preferred way to install and update the TigerWrap CLI:

```bash
winget install ItTiger.TigerWrap
winget upgrade ItTiger.TigerWrap
```

The package ID is `ItTiger.TigerWrap`, and its moniker is `tiger-wrap`.
`winget update --all` can also update TigerWrap; this has been verified when moving
from a manually installed TigerWrap 0.9.0 to the WinGet-distributed 0.9.1 package.

GitHub releases may be available before the corresponding WinGet update completes
review and publication. If you need the newest release immediately, download its
installer from [GitHub Releases](https://github.com/rkozlowski/TigerWrap/releases).
WinGet remains the preferred normal installation and update path.

The CLI and TigerWrapDb have related, but separate, versions. After updating the CLI,
run `tiger-wrap db info` and upgrade the database if required. See
[docs/INSTALL.md](docs/INSTALL.md) for database setup, compatibility, backup, and
upgrade instructions.

---

## 📚 Documentation

- [docs/README.md](docs/README.md) — full documentation  
- [docs/ENUMS.md](docs/ENUMS.md) — enum mapping guide  
- [docs/WRAPPERS.md](docs/WRAPPERS.md) — stored procedure wrappers  
- [docs/CLI.md](docs/CLI.md) — CLI usage  
- [docs/INSTALL.md](docs/INSTALL.md) — CLI installation and database setup

---

## 🔧 Status

TigerWrap v0.9.1 is a **beta release**.  
It is already stable and useful — and evolving quickly.

---

## 🛡️ Copyright & Project Sponsor

<p align="left">
  <img src="https://raw.githubusercontent.com/rkozlowski/TigerWrap/main/docs/assets/ItTiger-head.png" alt="IT Tiger Logo" width="120"/>
</p>

TigerWrap is an open-source project by **IT Tiger**  
🔗 https://www.ittiger.net/
