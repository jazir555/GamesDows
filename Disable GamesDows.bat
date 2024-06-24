@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion

echo Reverting changes and setting default shell back to Explorer

:: Reset the default shell to Explorer
SET "EXPLORER_PATH=C:\Windows\explorer.exe"
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "C:\Windows\explorer.exe" /f

:: Define the default Steam folder path
SET "STEAM_FOLDER=C:\Program Files (x86)\Steam"

:: Delete the DelayedExplorerStart.bat script and related files
SET "SCRIPT_NAME=DelayedExplorerStart.bat"
SET "SCRIPT_PATH=%STEAM_FOLDER%\%SCRIPT_NAME%"
IF EXIST "%SCRIPT_PATH%" DEL "%SCRIPT_PATH%"

SET "VBS_NAME=RunBatchSilently.vbs"
SET "VBS_PATH=%STEAM_FOLDER%\%VBS_NAME%"
IF EXIST "%VBS_PATH%" DEL "%VBS_PATH%"

SET "XML_NAME=DelayedExplorerStartTask.xml"
SET "XML_PATH=%STEAM_FOLDER%\%XML_NAME%"
IF EXIST "%XML_PATH%" DEL "%XML_PATH%"

:: Delete the scheduled task
schtasks /delete /tn "RunDelayedExplorerStart" /f

:: Enable the boot UI
bcdedit.exe -set {globalsettings} bootuxdisabled off

echo Reversion complete. Default settings restored.

pause
