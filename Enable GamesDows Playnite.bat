@echo off
:: Self-elevating Admin script
:: This script will automatically request admin rights if not running as admin

:: Check for admin rights and self-elevate if needed
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else (
    goto GotAdmin
)

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:GotAdmin
    if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs"
    pushd "%CD%"
    CD /D "%~dp0"

SETLOCAL EnableExtensions EnableDelayedExpansion

echo ---------------------------------------------------
echo Setting Playnite as default shell
echo ---------------------------------------------------

:: 1. Define Paths
SET "KEY_NAME=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
SET "VALUE_NAME=Shell"
SET "PLAYNITE_FOLDER=%LOCALAPPDATA%\Playnite"
SET "PLAYNITE_PATH=%PLAYNITE_FOLDER%\Playnite.FullscreenApp.exe"
SET "EXPLORER_PATH=C:\Windows\explorer.exe"
SET "SCRIPT_NAME=DelayedExplorerStart.bat"
SET "SCRIPT_PATH=%PLAYNITE_FOLDER%\%SCRIPT_NAME%"
SET "VBS_NAME=RunBatchSilently.vbs"
SET "VBS_PATH=%PLAYNITE_FOLDER%\%VBS_NAME%"

:: 2. Verify Playnite Exists
IF NOT EXIST "%PLAYNITE_PATH%" (
    echo.
    echo ERROR: Could not find Playnite at:
    echo "%PLAYNITE_PATH%"
    echo.
    echo If you are running this as a different Admin user, %%LOCALAPPDATA%% may be wrong.
    echo Please edit the script and hardcode the path if necessary.
    pause
    exit /b
)

echo Setting Registry Shell key...
REG ADD "%KEY_NAME%" /v %VALUE_NAME% /t REG_SZ /d "%PLAYNITE_PATH%" /f

:: 3. Create the DelayedExplorerStart.bat
echo Creating DelayedExplorerStart.bat script...
(
echo @echo off
echo :: Wait for Playnite to initialize first
echo timeout /t 20 /nobreak ^>nul
echo.
echo :: Set Shell to Explorer BEFORE launching it (critical for Taskbar)
echo REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "%EXPLORER_PATH%" /f
echo.
echo :: Launch Windows Explorer
echo echo Starting Windows Explorer...
echo start "" "%EXPLORER_PATH%"
echo.
echo :: Give Explorer time to initialize fully, then restore Playnite shell
echo timeout /t 10 /nobreak ^>nul
echo REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "%PLAYNITE_PATH%" /f
) > "%SCRIPT_PATH%"

:: 4. Create the VBS Runner
echo Creating RunBatchSilently.vbs script...
(
echo Set WshShell = CreateObject^("WScript.Shell"^)
echo WshShell.Run chr^(34^) ^& "%SCRIPT_PATH%" ^& chr^(34^), 0, True
echo Set WshShell = Nothing
) > "%VBS_PATH%"

echo ---------------------------------------------------
echo Creating Scheduled Task (Native Method)
echo ---------------------------------------------------

:: Delete existing task to prevent conflicts
schtasks /delete /tn "RunDelayedExplorerStart" /f >nul 2>&1

:: Create Task
:: /sc onlogon : Runs every time a user logs in
:: /rl highest : Runs with highest privileges (Required to edit Registry in background)
:: /tr : Targets the VBS script (escaped quotes handle spaces in path)
schtasks /create /tn "RunDelayedExplorerStart" /tr "wscript.exe \"%VBS_PATH%\"" /sc onlogon /rl highest /f

if %ERRORLEVEL% EQU 0 (
    echo SUCCESS: Scheduled Task created successfully.
) else (
    echo ERROR: Failed to create Scheduled Task.
)

echo ---------------------------------------------------
echo Applying Registry Optimizations...

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
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f

echo Improve Windows Explorer Process Priority
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\explorer.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 3 /f

echo Adjust Large System Cache
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 1 /f

echo Enabling No GUI Boot
bcdedit /set {current} quietboot on

echo.
echo ===================================================
echo  INSTALLATION COMPLETE
echo ===================================================
echo  Playnite Fullscreen is now the default shell.
echo  Explorer will launch in the background 20s after login.
echo.
echo  NOTE: Ensure you are logged into the User Account
echo  you intend to game on when you restart.
echo.
pause
