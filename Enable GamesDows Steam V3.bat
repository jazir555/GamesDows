:: Self-elevating Admin script
:: This script will automatically request admin rights if not running as admin

rem Check for admin rights and self-elevate if needed
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
echo Running with administrative privileges...
echo Setting Steam Big Picture as default shell

echo Set Steam Big Picture as the default shell
SET "KEY_NAME=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
SET "VALUE_NAME=Shell"
:: Added -silent to Steam args to prevent popups if possible, though BigPicture overrides it often
SET "STEAM_PATH=C:\Program Files (x86)\Steam\Steam.exe -bigpicture -nobootstrapupdate -skipinitialbootstrap -skipverifyfiles"
REG ADD "%KEY_NAME%" /v %VALUE_NAME% /t REG_SZ /d "%STEAM_PATH%" /f

echo Define the default Steam folder path and script names
SET "STEAM_FOLDER=C:\Program Files (x86)\Steam"
SET "SCRIPT_NAME=DelayedExplorerStart.bat"
SET "SCRIPT_PATH=%STEAM_FOLDER%\%SCRIPT_NAME%"
SET "EXPLORER_PATH=C:\Windows\explorer.exe"
SET "STEAM_EXE=C:\Program Files (x86)\Steam\Steam.exe"
SET "MANIFEST_PATH=%STEAM_EXE%.manifest"

echo Copying pre-created manifest file...
:: Ensure steam.manifest exists in the same folder as this script, otherwise skip
if exist "%~dp0steam.manifest" copy "%~dp0steam.manifest" "%MANIFEST_PATH%" >nul 2>&1

echo Creating DelayedExplorerStart.bat script
echo Create the DelayedExplorerStart.bat script in the Steam folder
(
echo @echo off
echo :: Ensure Explorer will load as full shell
echo REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "%EXPLORER_PATH%" /f

echo :: Wait for Steam Big Picture to initialize
echo timeout /t 20 /nobreak ^>nul

echo :: Launch the full Windows Explorer shell
echo start "" "%EXPLORER_PATH%"

echo :: Allow Explorer to settle
echo timeout /t 10 /nobreak ^>nul

echo :: Restore Steam as shell for next boot
echo REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "%STEAM_PATH%" /f
) > "%SCRIPT_PATH%"

echo Creating RunBatchSilently.vbs script

:: Create VBScript to run the batch file silently
@echo off
SET "VBS_NAME=RunBatchSilently.vbs"
SET "VBS_PATH=%STEAM_FOLDER%\%VBS_NAME%"
(
echo Set WshShell = CreateObject^("WScript.Shell"^)
echo WshShell.Run chr^(34^) ^& "%SCRIPT_PATH%" ^& chr^(34^), 0, True
echo Set WshShell = Nothing
) > "%VBS_PATH%"

echo ---------------------------------------------------
echo Creating Scheduled Task (Native Method)
echo ---------------------------------------------------

:: Delete the existing scheduled task if it exists
schtasks /delete /tn "RunDelayedExplorerStart" /f >nul 2>&1

:: Create the task using standard flags instead of XML
:: /sc onlogon : Runs when user logs in
:: /rl highest : Runs with highest privileges (needed for reg edits in the bat)
:: /tr : The command to run (The VBS script)
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
echo  Steam Big Picture is now the default shell.
echo  A background task will launch Explorer 20s after login.
echo  Please Restart your PC to take effect.
pause
