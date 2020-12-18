; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName             "Wise components for ACP"
#define MyAppVersion          "1.0"
#define MyAppPublisher        "Wise Observatory Software"
#define AcpDest               "C:\Program Files (x86)\ACP Obs Control\"
#define ScriptsDest           "C:\Program Files (x86)\ACP Obs Control\Scripts\"
#define WiseScriptsDest       "C:\Program Files (x86)\ACP Obs Control\Scripts\Wise\"
#define WeatherComponentsDest "C:\Program Files (x86)\ACP Obs Control\WeatherComponents\"
#define WeatherSetupDest      "C:\Program Files (x86)\ACP Obs Control\WeatherComponents\WiseWeatherSetup\"
#define SchedulerDest         "C:\Users\Public\Documents\ACP Config\Scheduler\"
#define AcpSrc                "C:\Users\mizpe\source\repos\blumzi\ACP"
#define Regasm                "{dotnet4032}\RegAsm.exe"

#pragma option -v+
#pragma verboselevel 9

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{803CE1E3-9907-48A3-894B-A533D1F031C4}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
CreateAppDir=no
; Uncomment the following line to run in non administrative install mode (install for current user only.)
;PrivilegesRequired=lowest
OutputDir=C:\Users\Blumzi\Source\Repos\ACP
OutputBaseFilename=Wise4ACP
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "{#AcpSrc}\Scripts\Wise\*";                                 DestDir: "{#WiseScriptsDest}";       Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#AcpSrc}\WeatherComponents\WiseWeatherSetup\bin\Debug\*"; DestDir: "{#WeatherSetupDest}";      Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#AcpSrc}\WeatherComponents\WiseWeather.wsc";              DestDir: "{#WeatherComponentsDest}"; Flags: ignoreversion regserver 32bit
Source: "{#AcpSrc}\Scripts\StartupObs-Wise.vbs";                    DestDir: "{#SchedulerDest}";         Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#AcpSrc}\Scripts\ShutdownObs-Wise.vbs";                   DestDir: "{#SchedulerDest}";         Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#AcpSrc}\Scripts\FS2_Sync.vbs";                           DestDir: "{#ScriptsDest}";           Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#AcpSrc}\UserActions-Wise.wsc";                           DestDir: "{#AcpDest}";               Flags: ignoreversion

[Run]
Filename: "{sys}\regsvr32";      WorkingDir: "{#AcpDest}";               Flags: runascurrentuser; Parameters: "/s UserActions-Wise.wsc"
Filename: "{sys}\regsvr32";      WorkingDir: "{#WiseScriptsDest}";       Flags: runascurrentuser; Parameters: "/s Wise.ASCOM.wsc"
Filename: "{sys}\regsvr32";      WorkingDir: "{#WiseScriptsDest}";       Flags: runascurrentuser; Parameters: "/s Wise.Camera.wsc"
Filename: "{sys}\regsvr32";      WorkingDir: "{#WiseScriptsDest}";       Flags: runascurrentuser; Parameters: "/s Wise.Dli.wsc"
Filename: "{sys}\regsvr32";      WorkingDir: "{#WiseScriptsDest}";       Flags: runascurrentuser; Parameters: "/s Wise.Dome.wsc"
Filename: "{sys}\regsvr32";      WorkingDir: "{#WiseScriptsDest}";       Flags: runascurrentuser; Parameters: "/s Wise.HTTP.wsc"
Filename: "{sys}\regsvr32";      WorkingDir: "{#WiseScriptsDest}";       Flags: runascurrentuser; Parameters: "/s Wise.Util.wsc"
Filename: "{sys}\regsvr32";      WorkingDir: "{#WiseScriptsDest}";       Flags: runascurrentuser; Parameters: "/s Wise.Tele.wsc"
Filename: "{#Regasm}";           WorkingDir: "{#WeatherSetupDest}";      Flags: runascurrentuser runminimized; Parameters: "/codebase /tlb WiseWeatherSetup.dll"
Filename: "{sys}\regsvr32";      WorkingDir: "{#WeatherComponentsDest}"; Flags: runascurrentuser; Parameters: "/s WiseWeather.wsc"

[UninstallRun]
Filename: "{sys}\regsvr32";      WorkingDir: "{#AcpDest}";               Flags: runascurrentuser; Parameters: "/s /u UserActions-Wise.wsc"
Filename: "{sys}\regsvr32";      WorkingDir: "{#WiseScriptsDest}";       Flags: runascurrentuser; Parameters: "/s /u Wise.ASCOM.wsc"
Filename: "{sys}\regsvr32";      WorkingDir: "{#WiseScriptsDest}";       Flags: runascurrentuser; Parameters: "/s /u Wise.Camera.wsc"
Filename: "{sys}\regsvr32";      WorkingDir: "{#WiseScriptsDest}";       Flags: runascurrentuser; Parameters: "/s /u Wise.Dli.wsc"
Filename: "{sys}\regsvr32";      WorkingDir: "{#WiseScriptsDest}";       Flags: runascurrentuser; Parameters: "/s /u Wise.Dome.wsc"
Filename: "{sys}\regsvr32";      WorkingDir: "{#WiseScriptsDest}";       Flags: runascurrentuser; Parameters: "/s /u Wise.HTTP.wsc"
Filename: "{sys}\regsvr32";      WorkingDir: "{#WiseScriptsDest}";       Flags: runascurrentuser; Parameters: "/s /u Wise.Util.wsc"
Filename: "{sys}\regsvr32";      WorkingDir: "{#WiseScriptsDest}";       Flags: runascurrentuser; Parameters: "/s /u Wise.Tele.wsc"
Filename: "{#Regasm}";           WorkingDir: "{#WeatherSetupDest}";      Flags: runascurrentuser runminimized; Parameters: "/unregister WiseWeatherSetup.dll"
Filename: "{sys}\regsvr32";      WorkingDir: "{#WeatherComponentsDest}"; Flags: runascurrentuser; Parameters: "/s /u WiseWeather.wsc"


