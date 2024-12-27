@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion

:: Paths for Steam
SET "STEAM_FOLDER=C:\Program Files (x86)\Steam"
SET "STEAM_SCRIPT_NAME=DelayedExplorerStart.bat"
SET "STEAM_SCRIPT_PATH=%STEAM_FOLDER%\%STEAM_SCRIPT_NAME%"
SET "STEAM_VBS_NAME=RunBatchSilently.vbs"
SET "STEAM_VBS_PATH=%STEAM_FOLDER%\%STEAM_VBS_NAME%"
SET "STEAM_XML_NAME=DelayedExplorerStartTask.xml"
SET "STEAM_XML_PATH=%STEAM_FOLDER%\%STEAM_XML_NAME%"

:: Paths for Playnite
SET "PLAYNITE_FOLDER=%LOCALAPPDATA%\Playnite"
SET "PLAYNITE_SCRIPT_NAME=DelayedExplorerStart.bat"
SET "PLAYNITE_SCRIPT_PATH=%PLAYNITE_FOLDER%\%PLAYNITE_SCRIPT_NAME%"
SET "PLAYNITE_VBS_NAME=RunBatchSilently.vbs"
SET "PLAYNITE_VBS_PATH=%PLAYNITE_FOLDER%\%PLAYNITE_VBS_NAME%"
SET "PLAYNITE_XML_NAME=DelayedExplorerStartTask.xml"
SET "PLAYNITE_XML_PATH=%PLAYNITE_FOLDER%\%PLAYNITE_XML_NAME%"

echo ================================
echo DISABLING GAMESDOWS / REMOVING CUSTOM SHELL
echo ================================

:: 1) Reset the default shell to Explorer
echo [1/7] Resetting default shell to Explorer...
REG ADD "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" ^
    /v "Shell" /t REG_SZ /d "C:\Windows\explorer.exe" /f
if ERRORLEVEL 1 (
    echo [ERROR] Failed to reset the default shell.
    goto end
) else (
    echo [SUCCESS] Default shell reset to Explorer.
)

:: 2) Delete any existing DelayedExplorerStart.bat in Steam folder
echo [4/7] Deleting DelayedExplorerStart.bat from Steam folder...
IF EXIST "%STEAM_SCRIPT_PATH%" (
    DEL /F /Q "%STEAM_SCRIPT_PATH%"
    if ERRORLEVEL 1 (
        echo [WARNING] Could not delete %STEAM_SCRIPT_NAME%.
    ) else (
        echo [SUCCESS] %STEAM_SCRIPT_NAME% deleted.
    )
) else (
    echo [INFO] %STEAM_SCRIPT_NAME% does not exist in Steam folder.
)

:: 2b) Delete any existing DelayedExplorerStart.bat in Playnite folder
echo [2b/7] Deleting DelayedExplorerStart.bat from Playnite folder...
IF EXIST "%PLAYNITE_SCRIPT_PATH%" (
    DEL /F /Q "%PLAYNITE_SCRIPT_PATH%"
    if ERRORLEVEL 1 (
        echo [WARNING] Could not delete %PLAYNITE_SCRIPT_NAME%.
    ) else (
        echo [SUCCESS] %PLAYNITE_SCRIPT_NAME% deleted.
    )
) else (
    echo [INFO] %PLAYNITE_SCRIPT_NAME% does not exist in Playnite folder.
)

:: 3) Delete any existing RunBatchSilently.vbs in Steam folder
echo [3/7] Deleting RunBatchSilently.vbs from Steam folder...
IF EXIST "%STEAM_VBS_PATH%" (
    DEL /F /Q "%STEAM_VBS_PATH%"
    if ERRORLEVEL 1 (
        echo [WARNING] Could not delete %STEAM_VBS_NAME%.
    ) else (
        echo [SUCCESS] %STEAM_VBS_NAME% deleted.
    )
) else (
    echo [INFO] %STEAM_VBS_NAME% does not exist in Steam folder.
)

:: 3b) Delete any existing RunBatchSilently.vbs in Playnite folder
echo [3b/7] Deleting RunBatchSilently.vbs from Playnite folder...
IF EXIST "%PLAYNITE_VBS_PATH%" (
    DEL /F /Q "%PLAYNITE_VBS_PATH%"
    if ERRORLEVEL 1 (
        echo [WARNING] Could not delete %PLAYNITE_VBS_NAME%.
    ) else (
        echo [SUCCESS] %PLAYNITE_VBS_NAME% deleted.
    )
) else (
    echo [INFO] %PLAYNITE_VBS_NAME% does not exist in Playnite folder.
)

:: 4) Delete any existing DelayedExplorerStartTask.xml in Steam folder
echo [4/7] Deleting DelayedExplorerStartTask.xml from Steam folder...
IF EXIST "%STEAM_XML_PATH%" (
    DEL /F /Q "%STEAM_XML_PATH%"
    if ERRORLEVEL 1 (
        echo [WARNING] Could not delete %STEAM_XML_NAME%.
    ) else (
        echo [SUCCESS] %STEAM_XML_NAME% deleted.
    )
) else (
    echo [INFO] %STEAM_XML_NAME% does not exist in Steam folder.
)

:: 4b) Delete any existing DelayedExplorerStartTask.xml in Playnite folder
echo [4b/7] Deleting DelayedExplorerStartTask.xml from Playnite folder...
IF EXIST "%PLAYNITE_XML_PATH%" (
    DEL /F /Q "%PLAYNITE_XML_PATH%"
    if ERRORLEVEL 1 (
        echo [WARNING] Could not delete %PLAYNITE_XML_NAME%.
    ) else (
        echo [SUCCESS] %PLAYNITE_XML_NAME% deleted.
    )
) else (
    echo [INFO] %PLAYNITE_XML_NAME% does not exist in Playnite folder.
)

:: 5) Delete the scheduled task (if it exists)
echo [5/7] Deleting scheduled task 'RunDelayedExplorerStart'...
schtasks /delete /tn "RunDelayedExplorerStart" /f >nul 2>&1
if ERRORLEVEL 1 (
    echo [WARNING] Could not delete the scheduled task 'RunDelayedExplorerStart'.
) else (
    echo [SUCCESS] Scheduled task 'RunDelayedExplorerStart' deleted.
)

echo.
echo ================================
echo GamesDows has been disabled successfully.
echo All Playnite/Steam scripts removed.
echo The default shell is now Explorer.
echo A system restart is recommended.
echo ================================

:end
ENDLOCAL
pause
