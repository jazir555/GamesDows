@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion
SET "STEAM_FOLDER=C:\Program Files (x86)\Steam"
SET "SCRIPT_NAME=DelayedExplorerStart.bat"
SET "SCRIPT_PATH=%STEAM_FOLDER%\%SCRIPT_NAME%"
SET "EXPLORER_PATH=C:\Windows\explorer.exe"
SET "VBS_NAME=RunBatchSilently.vbs"
SET "VBS_PATH=%STEAM_FOLDER%\%VBS_NAME%"
SET "ADMIN_VBS_NAME=LaunchSteamAsAdmin.vbs"
SET "ADMIN_VBS_PATH=%STEAM_FOLDER%\%ADMIN_VBS_NAME%"
SET "STEAM_PATH=C:\Program Files (x86)\Steam\Steam.exe -bigpicture -nobootstrapupdate -skipinitialbootstrap -skipverifyfiles"
SET "XML_NAME=DelayedExplorerStartTask.xml"
SET "XML_PATH=%STEAM_FOLDER%\DelayedExplorerStartTask.xml"

echo Reverting changes and setting default shell back to Explorer

:: Reset the default shell to Explorer
SET "EXPLORER_PATH=C:\Windows\explorer.exe"
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "C:\Windows\explorer.exe" /f

:: Define the default Steam folder path
SET "STEAM_FOLDER=C:\Program Files (x86)\Steam"

:: Delete the DelayedExplorerStart.bat script and related files
IF EXIST "%SCRIPT_PATH%" DEL "%SCRIPT_PATH%"

IF EXIST "%VBS_PATH%" DEL "%VBS_PATH%"

IF EXIST "%XML_PATH%" DEL "%XML_PATH%"

:: Delete the scheduled task
schtasks /delete /tn "RunDelayedExplorerStart" /f

:: Enable the boot UI
bcdedit.exe -set {globalsettings} bootuxdisabled off

echo Reversion complete. Default settings restored.

pause
