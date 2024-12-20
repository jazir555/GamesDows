@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion

:: Define paths and names
SET "STEAM_FOLDER=C:\Program Files (x86)\Steam"
SET "SCRIPT_NAME=DelayedExplorerStart.bat"
SET "SCRIPT_PATH=%STEAM_FOLDER%\%SCRIPT_NAME%"
SET "VBS_NAME=RunBatchSilently.vbs"
SET "VBS_PATH=%STEAM_FOLDER%\%VBS_NAME%"
SET "XML_NAME=DelayedExplorerStartTask.xml"
SET "XML_PATH=%STEAM_FOLDER%\%XML_NAME%"

echo ================================
echo Disabling GamesDows
echo ================================

:: Reset the default shell to Explorer
echo [1/5] Resetting default shell to Explorer...
REG ADD "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "C:\Windows\explorer.exe" /f
if ERRORLEVEL 1 (
    echo [ERROR] Failed to reset the default shell.
    goto end
) else (
    echo [SUCCESS] Default shell reset to Explorer.
)

:: Terminate Steam processes to ensure changes take effect
echo [2/5] Terminating Steam processes...
taskkill /IM "Steam.exe" /F >nul 2>&1
taskkill /IM "SteamService.exe" /F >nul 2>&1
echo [INFO] Steam processes terminated.

:: Delete the DelayedExplorerStart.bat script
echo [3/5] Deleting DelayedExplorerStart.bat...
IF EXIST "%SCRIPT_PATH%" (
    DEL /F /Q "%SCRIPT_PATH%"
    if ERRORLEVEL 1 (
        echo [WARNING] Could not delete %SCRIPT_NAME%.
    ) else (
        echo [SUCCESS] %SCRIPT_NAME% deleted.
    )
) else (
    echo [INFO] %SCRIPT_NAME% does not exist.
)

:: Delete the RunBatchSilently.vbs script
echo [4/5] Deleting RunBatchSilently.vbs...
IF EXIST "%VBS_PATH%" (
    DEL /F /Q "%VBS_PATH%"
    if ERRORLEVEL 1 (
        echo [WARNING] Could not delete %VBS_NAME%.
    ) else (
        echo [SUCCESS] %VBS_NAME% deleted.
    )
) else (
    echo [INFO] %VBS_NAME% does not exist.
)

:: Delete the DelayedExplorerStartTask.xml file
echo [5/5] Deleting DelayedExplorerStartTask.xml...
IF EXIST "%XML_PATH%" (
    DEL /F /Q "%XML_PATH%"
    if ERRORLEVEL 1 (
        echo [WARNING] Could not delete %XML_NAME%.
    ) else (
        echo [SUCCESS] %XML_NAME% deleted.
    )
) else (
    echo [INFO] %XML_NAME% does not exist.
)

:: Delete the scheduled task
echo [6/6] Deleting scheduled task 'RunDelayedExplorerStart'...
schtasks /delete /tn "RunDelayedExplorerStart" /f >nul 2>&1
if ERRORLEVEL 1 (
    echo [WARNING] Could not delete the scheduled task 'RunDelayedExplorerStart'.
) else (
    echo [SUCCESS] Scheduled task 'RunDelayedExplorerStart' deleted.
)

echo.
echo ================================
echo GamesDows has been disabled successfully.
echo A system restart is recommended for all changes to take effect.
echo ================================

:end
ENDLOCAL
pause
