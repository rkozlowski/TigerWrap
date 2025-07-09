# =============================================
# BuildInstaller.ps1 — TigerWrap Installer Builder
# Author: IT Tiger
# =============================================

$ErrorActionPreference = "Stop"

# Paths
$projectRoot       = Resolve-Path ".."
$cliProject        = "$projectRoot\ItTiger.TigerWrap.Cli\ItTiger.TigerWrap.Cli.csproj"
$versionFile       = "$projectRoot\Version.props"
$issFile           = "$PSScriptRoot\Installer.iss"
$workingDir        = "$PSScriptRoot\WorkingDir"
$cliOutputDir      = "$workingDir\cli"
$sqlOutputDir      = "$workingDir\sql"
$deploymentScripts = "$projectRoot\TigerWrapDb\DeploymentScripts"

# Step 1: Read version from Version.props
[xml]$xml = Get-Content $versionFile
$version = $xml.Project.PropertyGroup.Version
$versionInfo = "$version.0"  # Inno Setup wants 4-part version

Write-Host "`nBuilding TigerWrap Installer v$version..." -ForegroundColor Cyan

# Step 2: Clean working directory
Write-Host "Cleaning WorkingDir..."
Remove-Item "$workingDir\*" -Recurse -Force -ErrorAction SilentlyContinue

# Step 3: Publish CLI
Write-Host "Publishing CLI to $cliOutputDir..."
dotnet publish $cliProject -c Release -o $cliOutputDir

# Step 4: Copy SQL scripts
Write-Host "Copying SQL scripts..."
New-Item -ItemType Directory -Path $sqlOutputDir -Force | Out-Null

# Copy all upgrade scripts
Get-ChildItem "$deploymentScripts\TigerWrapDb_Upgrade_*.sql" |
    Copy-Item -Destination $sqlOutputDir

# Copy full deploy script for current version
$fullDeploy = "$deploymentScripts\TigerWrapDb_FullDeploy_v_$version.sql"
if (Test-Path $fullDeploy) {
    Copy-Item $fullDeploy -Destination $sqlOutputDir
} else {
    Write-Warning "Full deploy script not found: $fullDeploy"
}

# Step 5: Generate VERSION.txt
Write-Host "Generating VERSION.txt..."
Set-Content -Path "$workingDir\VERSION.txt" -Value $version

# Step 6: Update Installer.iss with version info
Write-Host "Updating Installer.iss..."
(Get-Content $issFile) `
    -replace '^; Version:\s*.*$', "; Version:     $version" `
    -replace '^AppVersion=.*$', "AppVersion=$version" `
    -replace '^VersionInfoVersion=.*$', "VersionInfoVersion=$versionInfo" `
    -replace '^OutputBaseFilename=.*$', "OutputBaseFilename=TigerWrapSetup_$($version -replace '\.', '_')" |
    Set-Content $issFile


# Step 7: Locate ISCC.exe from registry
Write-Host "Resolving Inno Setup Compiler (ISCC.exe)..."
$innoKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 6_is1"
$innoPath = (Get-ItemProperty -Path $innoKey -ErrorAction SilentlyContinue).InstallLocation

if (-not $innoPath) {
    $innoKey32 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 6_is1"
    $innoPath = (Get-ItemProperty -Path $innoKey32 -ErrorAction SilentlyContinue).InstallLocation
}

if (-not $innoPath -or !(Test-Path "$innoPath\ISCC.exe")) {
    throw "Inno Setup Compiler (ISCC.exe) not found. Please install Inno Setup 6."
}

$innoSetupExe = Join-Path $innoPath "ISCC.exe"

# Step 8: Compile installer
Write-Host "Compiling installer with ISCC..."
& "$innoSetupExe" "$issFile"

Write-Host "`nTigerWrap installer built successfully." -ForegroundColor Green

