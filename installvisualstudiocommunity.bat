@echo off
setlocal enabledelayedexpansion

:: Log file
set log_file=%~dp0modify_winlogon.log
set compile_log=%~dp0compile.log
set temp_dir=C:\Temp
set vs_install_log=%temp_dir%\vs_buildtools_install.log
set vs_community_installer=%temp_dir%\vs_community.exe

echo Script started at %date% %time% > %log_file%
echo Script started at %date% %time%

:: Ensure running as administrator
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo This script must be run as administrator! >> %log_file%
    echo This script must be run as administrator!
    exit /b
)

:: Paths and filenames
set exe_name=CustomLogonUI.exe
set cpp_code=CustomLogonUI.cpp
set src_path=%~dp0
set dst_path=C:\Windows\System32
set backup_logonui=logonui_backup.exe
set installer=%temp_dir%\vs_buildtools.exe

:: Step 1: Ensure Temp Directory Exists and has Correct Permissions
echo Ensuring temp directory exists and has correct permissions... >> %log_file%
echo Ensuring temp directory exists and has correct permissions...
if not exist "%temp_dir%" (
    mkdir "%temp_dir%"
)
icacls "%temp_dir%" /grant Everyone:(F) >> %log_file% 2>&1
if %errorlevel% neq 0 (
    echo Failed to set permissions for the temp directory. >> %log_file%
    echo Failed to set permissions for the temp directory.
    exit /b
)
echo Temp directory permissions set. >> %log_file%
echo Temp directory permissions set.



:: Step 6: Download and Install Visual Studio Community Edition
echo Downloading Visual Studio Community Edition... >> %log_file%
echo Downloading Visual Studio Community Edition...
powershell -command "Invoke-WebRequest -Uri 'https://aka.ms/vs/16/release/vs_community.exe' -OutFile '%vs_community_installer%'" >> %log_file% 2>&1
if %errorlevel% neq 0 (
    echo Failed to download Visual Studio Community installer. >> %log_file%
    echo Failed to download Visual Studio Community installer.
    exit /b
)
echo Visual Studio Community installer downloaded successfully. >> %log_file%
echo Visual Studio Community installer downloaded successfully.

echo Installing Visual Studio Community Edition... >> %log_file%
echo Installing Visual Studio Community Edition...
start /wait "" "%vs_community_installer%" --add Microsoft.VisualStudio.Workload.CoreEditor --includeRecommended --passive --norestart --log %vs_install_log% --loglevel verbose
if %errorlevel% neq 0 (
    echo Failed to install Visual Studio Community. Check the install log for details: %vs_install_log% >> %log_file%
    echo Failed to install Visual Studio Community. Check the install log for details: %vs_install_log%
    exit /b
)
echo Visual Studio Community installed successfully. >> %log_file%
echo Visual Studio Community installed successfully.
