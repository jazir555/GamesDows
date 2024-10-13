@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion

echo ================================
echo Disabling GamesDows
echo ================================

:: Check for administrative privileges
echo Checking for administrative privileges...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires administrative privileges.
    echo Please run it as an administrator.
    pause
    exit /b 1
)

:: Define paths and names
SET "STEAM_FOLDER=C:\Program Files (x86)\Steam"
SET "SCRIPT_NAME=DelayedExplorerStart.bat"
SET "SCRIPT_PATH=%STEAM_FOLDER%\%SCRIPT_NAME%"
SET "VBS_NAME=RunBatchSilently.vbs"
SET "VBS_PATH=%STEAM_FOLDER%\%VBS_NAME%"
SET "ADMIN_VBS_NAME=LaunchSteamAsAdmin.vbs"
SET "ADMIN_VBS_PATH=%STEAM_FOLDER%\%ADMIN_VBS_NAME%"
SET "XML_NAME=DelayedExplorerStartTask.xml"
SET "XML_PATH=%STEAM_FOLDER%\%XML_NAME%"

:: Terminate Steam processes to ensure changes can be applied
echo [1/7] Terminating Steam processes...
taskkill /IM "Steam.exe" /F >nul 2>&1
taskkill /IM "SteamService.exe" /F >nul 2>&1
echo [INFO] Steam processes terminated.

:: Reset the default shell to Explorer
echo [2/7] Resetting default shell to Explorer...
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "C:\Windows\explorer.exe" /f
if %errorlevel% neq 0 (
    echo [ERROR] Failed to reset the default shell.
) else (
    echo [SUCCESS] Default shell reset to Explorer.
)

:: Delete DelayedExplorerStart.bat
echo [3/7] Deleting DelayedExplorerStart.bat...
IF EXIST "%SCRIPT_PATH%" (
    DEL /F /Q "%SCRIPT_PATH%"
    if %errorlevel% neq 0 (
        echo [WARNING] Could not delete %SCRIPT_NAME%.
    ) else (
        echo [SUCCESS] %SCRIPT_NAME% deleted.
    )
) else (
    echo [INFO] %SCRIPT_NAME% does not exist.
)

:: Delete RunBatchSilently.vbs
echo [4/7] Deleting RunBatchSilently.vbs...
IF EXIST "%VBS_PATH%" (
    DEL /F /Q "%VBS_PATH%"
    if %errorlevel% neq 0 (
        echo [WARNING] Could not delete %VBS_NAME%.
    ) else (
        echo [SUCCESS] %VBS_NAME% deleted.
    )
) else (
    echo [INFO] %VBS_NAME% does not exist.
)

:: Delete LaunchSteamAsAdmin.vbs
echo [5/7] Deleting LaunchSteamAsAdmin.vbs...
IF EXIST "%ADMIN_VBS_PATH%" (
    DEL /F /Q "%ADMIN_VBS_PATH%"
    if %errorlevel% neq 0 (
        echo [WARNING] Could not delete %ADMIN_VBS_NAME%.
    ) else (
        echo [SUCCESS] %ADMIN_VBS_NAME% deleted.
    )
) else (
    echo [INFO] %ADMIN_VBS_NAME% does not exist.
)

:: Delete the scheduled task
echo [6/7] Deleting scheduled task 'RunDelayedExplorerStart'...
schtasks /delete /tn "RunDelayedExplorerStart" /f >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Could not delete the scheduled task 'RunDelayedExplorerStart'.
) else (
    echo [SUCCESS] Scheduled task 'RunDelayedExplorerStart' deleted.
)

:: Delete the XML file
echo [7/7] Deleting DelayedExplorerStartTask.xml...
IF EXIST "%XML_PATH%" (
    DEL /F /Q "%XML_PATH%"
    if %errorlevel% neq 0 (
        echo [WARNING] Could not delete %XML_NAME%.
    ) else (
        echo [SUCCESS] %XML_NAME% deleted.
    )
) else (
    echo [INFO] %XML_NAME% does not exist.
)

:: Revert registry modifications
echo Reverting registry modifications...

echo [INFO] Enabling Boot UI...
bcdedit.exe -set {globalsettings} bootuxdisabled off
if %errorlevel% neq 0 (
    echo [WARNING] Failed to enable Boot UI.
) else (
    echo [SUCCESS] Boot UI enabled.
)

echo [INFO] Enabling Visual Effects...
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v VisualEffects /t REG_DWORD /d 0 /f
if %errorlevel% neq 0 (
    echo [WARNING] Failed to enable Visual Effects.
) else (
    echo [SUCCESS] Visual Effects enabled.
)

echo [INFO] Re-enabling Last Access Update...
reg delete "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisableLastAccessUpdate /f
if %errorlevel% neq 0 (
    echo [WARNING] Failed to re-enable Last Access Update.
) else (
    echo [SUCCESS] Last Access Update re-enabled.
)

echo [INFO] Reverting Paging Executive...
reg delete "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /f
if %errorlevel% neq 0 (
    echo [WARNING] Failed to revert Paging Executive.
) else (
    echo [SUCCESS] Paging Executive reverted.
)

echo [INFO] Reverting Startup Delay...
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /f
if %errorlevel% neq 0 (
    echo [WARNING] Failed to revert Startup Delay.
) else (
    echo [SUCCESS] Startup Delay reverted.
)

echo [INFO] Reverting Explorer Process Priority...
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\explorer.exe\PerfOptions" /v CpuPriorityClass /f
if %errorlevel% neq 0 (
    echo [WARNING] Failed to revert Explorer Process Priority.
) else (
    echo [SUCCESS] Explorer Process Priority reverted.
)

echo [INFO] Reverting Large System Cache...
reg delete "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /f
if %errorlevel% neq 0 (
    echo [WARNING] Failed to revert Large System Cache.
) else (
    echo [SUCCESS] Large System Cache reverted.
)

echo [INFO] Disabling Quiet Boot...
bcdedit /set {current} quietboot off
if %errorlevel% neq 0 (
    echo [WARNING] Failed to disable Quiet Boot.
) else (
    echo [SUCCESS] Quiet Boot disabled.
)

echo.
echo ================================
echo GamesDows has been disabled successfully.
echo A system restart is recommended for all changes to take effect.
echo ================================

ENDLOCAL
pause
