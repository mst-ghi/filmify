; Filmify Windows installer - built by ISCC in the release workflow.
; AppVersion is injected via /DAppVersion=x.y.z
#ifndef AppVersion
#define AppVersion "0.0.0"
#endif

[Setup]
AppId={{7E1A2C4B-9D3F-4E68-A5C1-F2B04D6E9A17}
AppName=Filmify
AppVersion={#AppVersion}
AppPublisher=mst-ghi
DefaultDirName={autopf}\Filmify
DefaultGroupName=Filmify
DisableProgramGroupPage=yes
OutputDir=..\..\dist
OutputBaseFilename=Filmify-{#AppVersion}-windows-x64-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\filmify.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Filmify"; Filename: "{app}\filmify.exe"
Name: "{autodesktop}\Filmify"; Filename: "{app}\filmify.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\filmify.exe"; Description: "{cm:LaunchProgram,Filmify}"; Flags: nowait postinstall skipifsilent
