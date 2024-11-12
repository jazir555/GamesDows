@echo off
SETLOCAL EnableExtensions

echo Setting Playnite as default shell

SET "KEY_NAME=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
SET "VALUE_NAME=Shell"
SET "PLAYNITE_FOLDER=%LOCALAPPDATA%\Playnite"
SET "PLAYNITE_PATH=%PLAYNITE_FOLDER%\Playnite.FullscreenApp.exe --hidesplashscreen"
REG ADD "%KEY_NAME%" /v %VALUE_NAME% /t REG_SZ /d "%PLAYNITE_PATH%" /f

powercfg -h off

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableFirstLogonAnimation /t REG_DWORD /d 0 /f

@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion

echo Define the default Playnite folder path and script names

SET "SCRIPT_NAME=DelayedExplorerStart.bat"
SET "SCRIPT_PATH=%PLAYNITE_FOLDER%\%SCRIPT_NAME%"
SET "EXPLORER_PATH=C:\Windows\explorer.exe"

echo Creating DelayedExplorerStart.bat script

echo Create the DelayedExplorerStart.bat script in the Playnite folder
(
echo @echo off
echo rem Check if user is logged on
echo whoami ^| find /i "%USERNAME%" ^>nul
echo if ERRORLEVEL 1 exit
echo rem Set Shell back to Explorer
echo REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "%EXPLORER_PATH%" /f
echo timeout /t 5 /nobreak ^>nul
echo start C:\Windows\explorer.exe
echo timeout /t 5 /nobreak ^>nul
echo REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "%PLAYNITE_PATH%" /f
) > "%SCRIPT_PATH%"

echo Creating RunBatchSilently.vbs script

:: Create VBScript to run the batch file silently
SET "VBS_NAME=RunBatchSilently.vbs"
SET "VBS_PATH=%PLAYNITE_FOLDER%\%VBS_NAME%"
echo %VBS_PATH%
echo Set WshShell = CreateObject("WScript.Shell") > "%VBS_PATH%"
echo WshShell.Run chr(34^) ^& "%SCRIPT_PATH%" ^& chr(34^), 0, True >> "%VBS_PATH%"
echo Set WshShell = Nothing >> "%VBS_PATH%"

echo Create XML file for the scheduled task
SET XML_PATH=%PLAYNITE_FOLDER%\DelayedExplorerStartTask.xml

echo Delete the existing XML file if it exists
IF EXIST "%XML_PATH%" DEL "%XML_PATH%"

(
echo ^<?xml version="1.0" encoding="UTF-16"?^>
echo ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^>
echo   ^<RegistrationInfo^>
echo     ^<Date^>2020-01-01T00:00:00^</Date^>
echo     ^<Author^>"%USERNAME%"^</Author^>
echo     ^<Description^>Run DelayedExplorerStart.bat at logon.^</Description^>
echo   ^</RegistrationInfo^>
echo   ^<Triggers^>
echo     ^<LogonTrigger^>
echo       ^<Enabled^>true^</Enabled^>
echo     ^</LogonTrigger^>
echo   ^</Triggers^>
echo   ^<Principals^>
echo     ^<Principal id="Author"^>
echo       ^<UserId^>%USERNAME%</UserId^>
echo       ^<LogonType^>InteractiveToken^</LogonType^>
echo       ^<RunLevel^>HighestAvailable^</RunLevel^>
echo     ^</Principal^>
echo   ^</Principals^>
echo   ^<Settings^>
echo       ^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^>
echo       ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^>
echo       ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^>
echo       ^<AllowHardTerminate^>true^</AllowHardTerminate^>
echo       ^<StartWhenAvailable^>true^</StartWhenAvailable^>
echo       ^<RunOnlyIfNetworkAvailable^>false^</RunOnlyIfNetworkAvailable^>
echo       ^<IdleSettings^>
echo         ^<StopOnIdleEnd^>true^</StopOnIdleEnd^>
echo         ^<RestartOnIdle^>false^</RestartOnIdle^>
echo       ^</IdleSettings^>
echo       ^<Enabled^>true^</Enabled^>
echo       ^<Hidden^>false^</Hidden^>
echo       ^<WakeToRun^>false^</WakeToRun^>
echo       ^<ExecutionTimeLimit^>PT72H^</ExecutionTimeLimit^>
echo       ^<Priority^>7^</Priority^>
echo   ^</Settings^>
echo   ^<Actions Context="Author"^>
echo     ^<Exec^>
echo       ^<Command^>wscript.exe^</Command^>
echo       ^<Arguments^>"%VBS_PATH%"^</Arguments^>
echo     ^</Exec^>
echo   ^</Actions^>
echo ^</Task^>
) > "%XML_PATH%"

echo Delete the existing scheduled task if it exists
schtasks /delete /tn "RunDelayedExplorerStart" /f

echo Create the scheduled task using the XML file
schtasks /create /tn "RunDelayedExplorerStart" /xml "%XML_PATH%"

echo Delayed Explorer start script and VBScript created in Playnite folder.
echo Scheduled Task added to run the script at logon.
echo XML file for Scheduled Task created.

:: Begin new code to create startup task for SetDisableLogonUI

echo Creating SetDisableLogonUI.bat script

SET "SET_DISABLE_LOGON_UI_BAT_NAME=SetDisableLogonUI.bat"
SET "SET_DISABLE_LOGON_UI_BAT_PATH=%PLAYNITE_FOLDER%\%SET_DISABLE_LOGON_UI_BAT_NAME%"

(
echo @echo off
echo reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DisableLogonUI /t REG_DWORD /d 1 /f
) > "%SET_DISABLE_LOGON_UI_BAT_PATH%"

echo Creating RunSetDisableLogonUI.vbs script

SET "VBS_DISABLE_LOGON_UI_NAME=RunSetDisableLogonUI.vbs"
SET "VBS_DISABLE_LOGON_UI_PATH=%PLAYNITE_FOLDER%\%VBS_DISABLE_LOGON_UI_NAME%"

echo Set WshShell = CreateObject("WScript.Shell") > "%VBS_DISABLE_LOGON_UI_PATH%"
echo WshShell.Run chr(34^) ^& "%SET_DISABLE_LOGON_UI_BAT_PATH%" ^& chr(34^), 0, True >> "%VBS_DISABLE_LOGON_UI_PATH%"
echo Set WshShell = Nothing >> "%VBS_DISABLE_LOGON_UI_PATH%"

echo Create XML file for the startup scheduled task
SET "XML_STARTUP_TASK_PATH=%PLAYNITE_FOLDER%\SetDisableLogonUITask.xml"

echo Delete the existing startup task XML file if it exists
IF EXIST "%XML_STARTUP_TASK_PATH%" DEL "%XML_STARTUP_TASK_PATH%"

(
echo ^<?xml version="1.0" encoding="UTF-16"?^>
echo ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^>
echo   ^<RegistrationInfo^>
echo     ^<Date^>2020-01-01T00:00:00^</Date^>
echo     ^<Author^>SYSTEM^</Author^>
echo     ^<Description^>Run SetDisableLogonUI.bat at startup.^</Description^>
echo   ^</RegistrationInfo^>
echo   ^<Triggers^>
echo     ^<BootTrigger^>
echo       ^<Enabled^>true^</Enabled^>
echo	     ^<Delay^>PT0S^</Delay^>
echo     ^</BootTrigger^>
echo   ^</Triggers^>
echo   ^<Principals^>
echo     ^<Principal id="LocalSystem"^>
echo       ^<UserId^>SYSTEM^</UserId^>
echo       ^<RunLevel^>HighestAvailable^</RunLevel^>
echo     ^</Principal^>
echo   ^</Principals^>
echo   ^<Settings^>
echo       ^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^>
echo       ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^>
echo       ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^>
echo       ^<AllowHardTerminate^>true^</AllowHardTerminate^>
echo       ^<StartWhenAvailable^>true^</StartWhenAvailable^>
echo       ^<RunOnlyIfNetworkAvailable^>false^</RunOnlyIfNetworkAvailable^>
echo       ^<IdleSettings^>
echo         ^<StopOnIdleEnd^>true^</StopOnIdleEnd^>
echo         ^<RestartOnIdle^>false^</RestartOnIdle^>
echo       ^</IdleSettings^>
echo       ^<Enabled^>true^</Enabled^>
echo       ^<Hidden^>false^</Hidden^>
echo       ^<WakeToRun^>false^</WakeToRun^>
echo       ^<ExecutionTimeLimit^>PT72H^</ExecutionTimeLimit^>
echo       ^<Priority^>7^</Priority^>
echo   ^</Settings^>
echo   ^<Actions Context="LocalSystem"^>
echo     ^<Exec^>
echo       ^<Command^>wscript.exe^</Command^>
echo       ^<Arguments^>"%VBS_DISABLE_LOGON_UI_PATH%"^</Arguments^>
echo     ^</Exec^>
echo   ^</Actions^>
echo ^</Task^>
) > "%XML_STARTUP_TASK_PATH%"

echo Delete the existing scheduled task if it exists
schtasks /delete /tn "SetDisableLogonUI" /f

echo Create the scheduled task using the XML file
schtasks /create /tn "SetDisableLogonUI" /xml "%XML_STARTUP_TASK_PATH%" /ru SYSTEM

:: End new code

echo Disable the boot UI
bcdedit.exe -set {globalsettings} bootuxdisabled on

echo Disable Logon UI

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DisableLogonUI /t REG_DWORD /d 1 /f

echo Enabling AutoAdminLogon
reg add "%KEY_NAME%" /v AutoAdminLogon /t REG_SZ /d "1" /f
reg add "%KEY_NAME%" /v DefaultUserName /t REG_SZ /d "%USERNAME%" /f
reg add "%KEY_NAME%" /v DefaultPassword /t REG_SZ /d "" /f

echo Disabling Automatic Restart Sign-On
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableAutomaticRestartSignOn /t REG_DWORD /d 1 /f

echo Disable Visual Effects
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v VisualEffects /t REG_DWORD /d 1 /f

echo Increase File System Performance
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisableLastAccessUpdate /t REG_DWORD /d 1 /f

echo Optimize Paging File Performance
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 1 /f

echo Disable Startup Delay
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f

echo Improve Windows Explorer Process Priority
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\explorer.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 3 /f
echo Adjust Large System Cache
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 1 /f
echo Enabling No GUI Boot
bcdedit /set {current} quietboot on

echo Registry modifications are complete.
echo Playnite set as default shell.
echo Automatic logon enabled.
echo Boot UI disabled.

pause
