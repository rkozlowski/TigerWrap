#Requires -Version 7.0
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$wingetDirectory = Split-Path -Parent $PSScriptRoot
$repositoryRoot = Split-Path -Parent (Split-Path -Parent $wingetDirectory)
$prepareScript = Join-Path $wingetDirectory 'Prepare-TigerWrapWinGet.ps1'
[xml]$versionXml = Get-Content -LiteralPath (Join-Path $repositoryRoot 'Version.props')
$version = [string]$versionXml.Project.PropertyGroup.Version
$filenameVersion = $version -replace '\.', '_'
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("TigerWrapWinGet-tests-" + [Guid]::NewGuid().ToString('N'))
$installerDirectory = Join-Path $testRoot 'installer'
$installerPath = Join-Path $installerDirectory "TigerWrapSetup_${filenameVersion}.exe"
$installerUrl = "https://github.com/rkozlowski/TigerWrap/releases/download/v$version/TigerWrapSetup_${filenameVersion}.exe"

function Assert-True {
    param(
        [Parameter(Mandatory)]
        [bool]$Condition,

        [Parameter(Mandatory)]
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

try {
    New-Item -ItemType Directory -Path $installerDirectory -Force | Out-Null
    [System.IO.File]::WriteAllBytes($installerPath, [byte[]](0..31))

    $sameOutput = Join-Path $testRoot 'same'
    & $prepareScript `
        -InstallerPath $installerPath `
        -OutputRoot $sameOutput `
        -ExpectedVersion $version `
        -InstallerUrl $installerUrl
    $sameManifest = Get-Content -LiteralPath (
        Join-Path $sameOutput "manifests\i\ItTiger\TigerWrap\$version\ItTiger.TigerWrap.installer.yaml") -Raw
    Assert-True ($sameManifest -cnotmatch '(?m)^\s+DisplayVersion:') `
        'DisplayVersion must be omitted when the installed version equals PackageVersion.'
    Write-Host 'PASS: equal DisplayVersion is omitted'

    $differentOutput = Join-Path $testRoot 'different'
    $differentVersion = "$version.0"
    & $prepareScript `
        -InstallerPath $installerPath `
        -OutputRoot $differentOutput `
        -ExpectedVersion $version `
        -InstallerUrl $installerUrl `
        -InstalledDisplayVersion $differentVersion
    $differentManifest = Get-Content -LiteralPath (
        Join-Path $differentOutput "manifests\i\ItTiger\TigerWrap\$version\ItTiger.TigerWrap.installer.yaml") -Raw
    Assert-True ($differentManifest -cmatch "(?m)^  DisplayVersion: $([regex]::Escape($differentVersion))\r?$") `
        'DisplayVersion must be emitted when the installed version differs from PackageVersion.'
    Write-Host 'PASS: differing DisplayVersion is preserved'
}
finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
