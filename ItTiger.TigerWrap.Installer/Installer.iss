; ============================================
; TigerWrap Installer Script
; Version:     0.9.0
; InstallType: Machine-wide (admin required)
; Author:      IT Tiger
; ============================================

#include "environment.iss"

[Setup]
AppName=TigerWrap CLI
AppVersion=0.9.0
DefaultDirName={autopf}\ItTiger\TigerWrap
DefaultGroupName=TigerWrap
OutputBaseFilename=TigerWrapSetup_0_9_0
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
DisableProgramGroupPage=yes
VersionInfoDescription=TigerWrap CLI installer
VersionInfoVersion=0.9.0.0
UninstallDisplayIcon={app}\cli\tiger-wrap.exe
AlwaysShowDirOnReadyPage=yes

; Publisher and URLs
AppPublisher=IT Tiger
AppPublisherURL=https://www.ittiger.net/
AppSupportURL=https://www.ittiger.net/projects/tigerwrap/
AppUpdatesURL=https://github.com/rkozlowski/TigerWrap/releases

ChangesEnvironment=yes

[Files]
; Install CLI output into subfolder
Source: "WorkingDir\cli\*"; DestDir: "{app}\cli"; Flags: recursesubdirs

; Include VERSION.txt in root folder
Source: "WorkingDir\VERSION.txt"; DestDir: "{app}"; Flags: ignoreversion

; Reserved: future GUI app
; Source: "WorkingDir\gui\*"; DestDir: "{app}\gui"; Flags: recursesubdirs

; Include SQL scripts
Source: "WorkingDir\sql\*"; DestDir: "{app}\sql"; Flags: recursesubdirs

[Icons]
; Start Menu shortcut that launches TigerWrap CLI in persistent cmd window
Name: "{group}\TigerWrap CLI"; Filename: "{cmd}"; Parameters: "/K ""{app}\cli\tiger-wrap.exe"""; WorkingDir: "{app}\cli"

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    EnvAddPath(ExpandConstant('{app}\cli'));
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    EnvRemovePath(ExpandConstant('{app}\cli'));
end;
