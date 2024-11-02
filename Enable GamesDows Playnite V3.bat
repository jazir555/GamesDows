@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion

echo Setting Playnite as default shell

SET "KEY_NAME=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
SET "VALUE_NAME=Shell"
SET "PLAYNITE_FOLDER=%LOCALAPPDATA%\Playnite"
SET "PLAYNITE_PATH=%PLAYNITE_FOLDER%\Playnite.FullscreenApp.exe"
REG ADD "%KEY_NAME%" /v %VALUE_NAME% /t REG_SZ /d "%PLAYNITE_PATH%" /f
SET "SCRIPT_NAME=DelayedExplorerStart.bat"
SET "SCRIPT_PATH=%PLAYNITE_FOLDER%\%SCRIPT_NAME%"
SET "EXPLORER_PATH=%SystemRoot%\explorer.exe"
SET "VBS_NAME=RunBatchSilently.vbs"
SET "VBS_PATH=%PLAYNITE_FOLDER%\%VBS_NAME%"

echo Creating DelayedExplorerStart.bat script

(
echo @echo off
echo rem Check if user is logged on
echo whoami ^| find /i "%%USERNAME%%" ^>nul
echo if ERRORLEVEL 1 exit

echo rem Set taskbar to autohide
echo powershell -command ^^
    "^$settingsPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3';" ^^
    "^$settings = (Get-ItemProperty -Path ^$settingsPath -Name 'Settings').Settings;" ^^
    "^$settings[8] = ^$settings[8] -bor 0x08;" ^^
    "Set-ItemProperty -Path ^$settingsPath -Name 'Settings' -Value ^$settings"

echo rem Start Explorer
echo start "" "%EXPLORER_PATH%"

echo rem Wait for Explorer to start
echo timeout /t 2 /nobreak ^>nul

echo rem Wait for a specific delay before unsetting autohide
echo timeout /t 5 /nobreak ^>nul

echo rem Unset taskbar autohide and refresh taskbar without restarting explorer.exe
echo powershell -command ^^
    "^$settingsPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3';" ^^
    "^$settings = (Get-ItemProperty -Path ^$settingsPath -Name 'Settings').Settings;" ^^
    "^$settings[8] = ^$settings[8] -band 0xF7;" ^^
    "Set-ItemProperty -Path ^$settingsPath -Name 'Settings' -Value ^$settings;" ^^
    "^$sig = '[DllImport(\"user32.dll\")] public static extern int SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);';" ^^
    "Add-Type -MemberDefinition ^$sig -Name 'Win32SendMessageTimeout' -Namespace 'Win32Functions';" ^^
    "[Win32Functions.Win32SendMessageTimeout]::SendMessageTimeout([IntPtr]::Zero, 0x1A, [IntPtr]::Zero, [IntPtr]::Zero, 0x0002, 1000, [ref]([IntPtr]::Zero));"
) > "%SCRIPT_PATH%"

echo Creating RunBatchSilently.vbs script

REM Create VBScript to run the batch file silently
echo Set WshShell = CreateObject("WScript.Shell") > "%VBS_PATH%"
echo WshShell.Run chr(34^) ^& "%SCRIPT_PATH%" ^& chr(34^), 0, True >> "%VBS_PATH%"
echo Set WshShell = Nothing >> "%VBS_PATH%"

echo Create XML file for the scheduled task
SET "XML_PATH=%PLAYNITE_FOLDER%\DelayedExplorerStartTask.xml"

echo Delete the existing XML file if it exists
IF EXIST "%XML_PATH%" DEL "%XML_PATH%"

(
echo ^<?xml version="1.0" encoding="UTF-16"?^>
echo ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^>
echo   ^<RegistrationInfo^>
echo     ^<Date^>2020-01-01T00:00:00^</Date^>
echo     ^<Author^>%USERNAME%^</Author^>
echo     ^<Description^>Run DelayedExplorerStart.bat at logon.^</Description^>
echo   ^</RegistrationInfo^>
echo   ^<Triggers^>
echo     ^<LogonTrigger^>
echo       ^<Enabled^>true^</Enabled^>
echo     ^</LogonTrigger^>
echo   ^</Triggers^>
echo   ^<Principals^>
echo     ^<Principal id="Author"^>
echo       ^<UserId^>%USERNAME%^</UserId^>
echo       ^<LogonType^>InteractiveToken^</LogonType^>
echo       ^<RunLevel^>HighestAvailable^</RunLevel^>
echo     ^</Principal^>
echo   ^</Principals^>
echo   ^<Settings^>
echo     ^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^>
echo     ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^>
echo     ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^>
echo     ^<AllowHardTerminate^>true^</AllowHardTerminate^>
echo     ^<StartWhenAvailable^>true^</StartWhenAvailable^>
echo     ^<RunOnlyIfNetworkAvailable^>false^</RunOnlyIfNetworkAvailable^>
echo     ^<IdleSettings^>
echo       ^<StopOnIdleEnd^>true^</StopOnIdleEnd^>
echo       ^<RestartOnIdle^>false^</RestartOnIdle^>
echo     ^</IdleSettings^>
echo     ^<Enabled^>true^</Enabled^>
echo     ^<Hidden^>false^</Hidden^>
echo     ^<WakeToRun^>false^</WakeToRun^>
echo     ^<ExecutionTimeLimit^>PT72H^</ExecutionTimeLimit^>
echo     ^<Priority^>7^</Priority^>
echo   ^</Settings^>
echo   ^<Actions Context="Author"^>
echo     ^<Exec^>
echo       ^<Command^>wscript.exe^</Command^>
echo       ^<Arguments^>"%VBS_PATH%"^</Arguments^>
echo     ^</Exec^>
echo   ^</Actions^>
echo ^</Task^>
) > "%XML_PATH%"

echo Deleting the existing scheduled task if it exists
schtasks /delete /tn "RunDelayedExplorerStart" /f

echo Creating the scheduled task using the XML file
schtasks /create /tn "RunDelayedExplorerStart" /xml "%XML_PATH%"
IF ERRORLEVEL 1 (
    echo Failed to create scheduled task.
    EXIT /B 1
)

echo Delayed Explorer start script and VBScript created in Playnite folder.
echo Scheduled Task added to run the script at logon.
echo XML file for Scheduled Task created.

echo Applying system optimizations

REM Disable the boot UI
bcdedit.exe -set {globalsettings} bootuxdisabled on

REM Disable Logon UI
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DisableLogonUI /t REG_DWORD /d 1 /f

REM Disable Visual Effects
reg add "HKCU\Control Panel\Desktop" /v VisualFXSetting /t REG_DWORD /d 2 /f

REM Increase File System Performance
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisableLastAccessUpdate /t REG_DWORD /d 1 /f

REM Optimize Paging File Performance
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 1 /f

REM Disable Startup Delay
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f

REM Improve Windows Explorer Process Priority
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\explorer.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 3 /f

REM Adjust Large System Cache
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 1 /f

REM Enabling No GUI Boot
bcdedit /set {current} quietboot on

echo Registry modifications are complete.
echo Playnite set as default shell.
echo Automatic logon enabled.
echo Boot UI disabled.

pause
