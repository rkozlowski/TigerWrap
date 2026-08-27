# Preparing the TigerWrap WinGet package

Run the tracked preparation script after publishing a TigerWrap release, using the
released installer or the byte-identical retained build artifact:

```powershell
.\eng\winget\Prepare-TigerWrapWinGet.ps1 -Validate
```

The script reads `Version.props`, verifies the installer filename and immutable GitHub
release URL, calculates its SHA-256, and writes the three submission files under
`artifacts\winget\manifests\i\ItTiger\TigerWrap\<version>\`. The `artifacts` directory is
ignored; copy the generated version directory to a `winget-pkgs` branch only after review
and validation.

WinGet's `AppsAndFeaturesEntries.DisplayVersion` is optional and must be omitted when the
installed Apps & Features version is identical to `PackageVersion`. The generator does
this by default. If the installer genuinely registers a different version, pass
`-InstalledDisplayVersion <version>`; only then does the generator emit `DisplayVersion`.

Run the focused generator tests after changing the preparation flow:

```powershell
pwsh -NoProfile -File .\eng\winget\tests\TigerWrapWinGet.Tests.ps1
```

The historical 0.9.1 manifests were prepared manually and are published history. Do not
rewrite an accepted version merely to adopt a newer generation policy.
