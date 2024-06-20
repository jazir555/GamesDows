@echo off
setlocal enabledelayedexpansion

:: Log file
set log_file=%~dp0modify_winlogon.log
set temp_dir=C:\Temp
set vs_install_log=%temp_dir%\vs_buildtools_install.log
set vs_install_error_log=%temp_dir%\vs_buildtools_install_error.log

echo Script started at %date% %time% > %log_file%
echo Script started at %date% %time%

:: Ensure running as administrator
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo This script must be run as administrator! >> %log_file%
    echo This script must be run as administrator!
    pause
    exit /b
)

:: Ensure Temp Directory Exists and has Correct Permissions
echo Ensuring temp directory exists and has correct permissions... >> %log_file%
if not exist "%temp_dir%" (
    mkdir "%temp_dir%"
)
icacls "%temp_dir%" /grant Everyone:(F) >> %log_file% 2>&1
if %errorlevel% neq 0 (
    echo Failed to set permissions for the temp directory. >> %log_file%
    pause
    exit /b
)
echo Temp directory permissions set. >> %log_file%

:: Download Visual Studio Build Tools Installer
set installer=%temp_dir%\vs_buildtools.exe
echo Downloading Visual Studio Build Tools... >> %log_file%
powershell -Command "Invoke-WebRequest -Uri 'https://aka.ms/vs/16/release/vs_buildtools.exe' -OutFile '%installer%'" >> %log_file% 2>&1
if %errorlevel% neq 0 (
    echo Failed to download Visual Studio Build Tools installer. >> %log_file%
    pause
    exit /b
)
echo Visual Studio Build Tools installer downloaded successfully. >> %log_file%

:: Run Visual Studio Build Tools Installer
echo Running Visual Studio Build Tools installer... >> %log_file%
powershell -Command "Start-Process -Wait -FilePath '%installer%' -ArgumentList '--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --passive --norestart' -RedirectStandardOutput '%vs_install_log%' -RedirectStandardError '%vs_install_error_log%' -NoNewWindow" >> %log_file% 2>&1
if %errorlevel% neq 0 (
    echo Failed to install Visual Studio Build Tools. >> %log_file%
    echo Check the install log for details: %vs_install_log% and %vs_install_error_log% >> %log_file%
    pause
    exit /b
)
echo Visual Studio Build Tools installed successfully. >> %log_file%

:: Indicate end of script
echo Script completed successfully. >> %log_file%
pause
