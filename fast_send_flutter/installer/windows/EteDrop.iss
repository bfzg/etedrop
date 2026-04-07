#define AppName "EteDrop"
#define AppPublisher "EteDrop"
#define AppURL "https://github.com/"
#define AppExeName "EteDrop.exe"

; 脚本目录：fast_send_flutter\installer\windows
; 项目根目录：fast_send_flutter
#define RootDir "..\.."

; Inno Setup 的“可选语言包”在不同安装方式下可能未包含。
; 若缺少 ChineseSimplified.isl，则自动仅启用英文，避免编译失败。
#if FileExists(CompilerPath + "Languages\ChineseSimplified.isl")
  #define HasZhLang 1
#else
  #define HasZhLang 0
#endif

; 编译时建议通过 ISCC 传入：
;   /DMyAppVersion=1.0.1
;   /DReleaseDir={#RootDir}\build\windows\x64\runner\Release
; 如果没传，则使用下面默认值（适配本仓库 Flutter 输出目录）
#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif

#ifndef ReleaseDir
  #define ReleaseDir RootDir + "\build\windows\x64\runner\Release"
#endif

; 固定 AppId（升级识别关键）：只要保持不变，后续新版安装包即可覆盖升级
#define AppId "{{B6FDE13B-4A67-4F4E-9D9C-9C5C7D4C6F0A}"

[Setup]
AppId={#AppId}
AppName={#AppName}
AppVersion={#MyAppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}

DefaultDirName={localappdata}\{#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

OutputBaseFilename={#AppName}-Setup-{#MyAppVersion}-win-x64
OutputDir=dist
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

SetupIconFile={#RootDir}\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}

[Languages]
#if HasZhLang
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
#endif
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Flutter Windows 必须分发完整目录结构，不能只拷贝一个 exe
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

; 可选：不打包调试符号（通常 Release 目录也不会有）
; Source: "{#ReleaseDir}\*.pdb"; DestDir: "{app}"; Flags: deleteafterinstall; Check: False

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
; 安装完成后可直接启动（在线升级场景一般用 /VERYSILENT + /NORESTART，不会走到这里）
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

