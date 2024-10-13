@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion

echo Checking for administrative privileges...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrative privileges.
    echo Please run it as an administrator.
    pause
    exit /b 1
)

echo Define the default Steam folder path and script names
SET "STEAM_FOLDER=C:\Program Files (x86)\Steam"
SET "SCRIPT_NAME=DelayedExplorerStart.bat"
SET "SCRIPT_PATH=%STEAM_FOLDER%\%SCRIPT_NAME%"
SET "EXPLORER_PATH=C:\Windows\explorer.exe"
SET "VBS_NAME=RunBatchSilently.vbs"
SET "VBS_PATH=%STEAM_FOLDER%\%VBS_NAME%"
SET "ADMIN_VBS_NAME=LaunchSteamAsAdmin.vbs"
SET "ADMIN_VBS_PATH=%STEAM_FOLDER%\%ADMIN_VBS_NAME%"
SET "STEAM_PATH=C:\Program Files (x86)\Steam\Steam.exe -bigpicture -nobootstrapupdate -skipinitialbootstrap -skipverifyfiles"

echo Creating LaunchSteamAsAdmin.vbs script

echo Creating LaunchSteamAsAdmin.vbs script

:: Create VBScript to launch Steam as admin and set the shell to Steam
(
    echo Set WshShell = CreateObject("WScript.Shell")
    echo ' Run REG ADD command to set the shell to Steam
    echo WshShell.Run "cmd /c REG ADD ""HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"" /v Shell /t REG_SZ /d ""%STEAM_PATH%"" /f", 0, True
    echo ' Launch Steam with elevated privileges
    echo Set objShell = CreateObject("Shell.Application")
    echo objShell.ShellExecute "%STEAM_PATH%", "", "", "runas", 1
    echo Set WshShell = Nothing
    echo Set objShell = Nothing
) > "%ADMIN_VBS_PATH%"
if %errorlevel% neq 0 (
    echo Error creating LaunchSteamAsAdmin.vbs
    pause
    exit /b 1
)

echo Creating RunBatchSilently.vbs script

:: Create VBScript to run the batch file silently
(
    echo Set WshShell = CreateObject("WScript.Shell")
    echo WshShell.Run chr(34) & "%SCRIPT_PATH%" & chr(34), 0, True
    echo Set WshShell = Nothing
) > "%VBS_PATH%"
if %errorlevel% neq 0 (
    echo Error creating RunBatchSilently.vbs
    pause
    exit /b 1
)

echo Creating DelayedExplorerStart.bat script

echo Create the DelayedExplorerStart.bat script in the Steam folder
(
    echo @echo off
    echo REM Check if user is logged on
    echo whoami ^| find /i "%USERNAME%" ^>nul
    echo if ERRORLEVEL 1 exit
    echo REM Set Shell back to Explorer
    echo REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "%EXPLORER_PATH%" /f
    echo timeout /t 20 /nobreak ^>nul
    echo start "" "%EXPLORER_PATH%"
    echo timeout /t 10 /nobreak ^>nul
    echo REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "%STEAM_PATH%" /f
) > "%SCRIPT_PATH%"

echo Create XML file for the scheduled task
SET XML_PATH=%STEAM_FOLDER%\DelayedExplorerStartTask.xml

echo Delete the existing XML file if it exists
IF EXIST "%XML_PATH%" DEL "%XML_PATH%"

(
echo ^<?xml version="1.0" encoding="UTF-8"?^>
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
IF EXIST "%XML_PATH%" (
    schtasks /create /tn "RunDelayedExplorerStart" /xml "%XML_PATH%" >nul 2>&1
    if %errorlevel% neq 0 (
        echo Error creating scheduled task
        pause
        exit /b 1
    ) else (
        echo [SUCCESS] Scheduled task 'RunDelayedExplorerStart' created.
    )
) else (
    echo [ERROR] XML file for scheduled task does not exist.
    pause
    exit /b 1
)

echo Delayed Explorer start script and VBScript created in Steam folder.
echo Scheduled Task added to run the script at logon.
echo XML file for Scheduled Task created.

echo Disable the boot UI
bcdedit.exe -set {globalsettings} bootuxdisabled on

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
echo Steam Big Picture set as default shell.
echo Automatic logon enabled.
echo Boot UI disabled.

pause

echo Script completed successfully.
pause
