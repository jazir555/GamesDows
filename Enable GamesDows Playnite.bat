@echo off
SETLOCAL EnableExtensions

echo Setting Playnite as default shell

SET "KEY_NAME=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
SET "VALUE_NAME=Shell"
SET "PLAYNITE_FOLDER=%LOCALAPPDATA%\Playnite"
SET "PLAYNITE_PATH=%LOCALAPPDATA%\Playnite\Playnite.FullscreenApp.exe"
REG ADD "%KEY_NAME%" /v %VALUE_NAME% /t REG_SZ /d "%PLAYNITE_PATH%" /f
SET "SCRIPT_NAME=DelayedExplorerStart.bat"
SET "SCRIPT_PATH=%PLAYNITE_FOLDER%\%SCRIPT_NAME%"
SET "EXPLORER_PATH=C:\Windows\explorer.exe"
SET "VBS_NAME=RunBatchSilently.vbs"
SET "VBS_PATH=%PLAYNITE_FOLDER%\%VBS_NAME%"

@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion

echo Creating DelayedExplorerStart.bat script

echo Create the DelayedExplorerStart.bat script in the Playnite folder
(
echo @echo off
echo rem Check if user is logged on
echo whoami ^| find /i "%USERNAME%" ^>nul
echo if ERRORLEVEL 1 exit
echo rem Set Shell back to Explorer
echo REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "%EXPLORER_PATH%" /f
echo timeout /t 20 /nobreak ^>nul
echo start C:\Windows\explorer.exe
echo timeout /t 10 /nobreak ^>nul
echo REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "%PLAYNITE_PATH%" /f
) > "%SCRIPT_PATH%"


echo %VBS_PATH% 

echo Creating RunBatchSilently.vbs script

rem Create VBScript to run the batch file silently
echo Set WshShell = CreateObject("WScript.Shell") > "%VBS_PATH%"
echo WshShell.Run chr(34)^&"%SCRIPT_PATH%"^&chr(34), 0, True >> "%VBS_PATH%"
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

echo Disable the boot UI
bcdedit.exe -set {globalsettings} bootuxdisabled on

echo Disable Logon UI

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DisableLogonUI /t REG_DWORD /d 1 /f

echo Disable Visual Effects
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v VisualEffects /t REG_DWORD /d 3 /f

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
