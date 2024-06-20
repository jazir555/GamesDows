@echo off
setlocal enabledelayedexpansion

:: Log file
set log_file=%~dp0modify_winlogon.log
set compile_log=%~dp0compile.log

echo Script started at %date% %time% > %log_file%

:: Ensure running as administrator
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo This script must be run as administrator! >> %log_file%
    echo This script must be run as administrator!
    pause
    exit /b
)

:: Paths and filenames
set exe_name=CustomLogonUI.exe
set cpp_code=CustomLogonUI.cpp
set src_path=%~dp0
set dst_path=C:\Windows\System32
set backup_logonui=logonui_backup.exe
set temp_dir=C:\Temp
set installer=%temp_dir%\vs_buildtools.exe

:: Step 1: Ensure Temp Directory Exists and has Correct Permissions
echo Ensuring temp directory exists and has correct permissions... >> %log_file%
if not exist "%temp_dir%" (
    mkdir "%temp_dir%"
)
icacls "%temp_dir%" /grant Everyone:(F) >> %log_file% 2>&1
echo Temp directory permissions set. >> %log_file%

:: Step 4: Install Windows SDK
echo Downloading Windows SDK... >> %log_file%
echo Downloading Windows SDK...
powershell -command "Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/?linkid=2120843' -OutFile '%sdk_installer%'" >> %log_file% 2>&1
if %errorlevel% neq 0 (
    echo Failed to download Windows SDK installer. >> %log_file%
    echo Failed to download Windows SDK installer.
    exit /b
)
echo Windows SDK installer downloaded successfully. >> %log_file%
echo Windows SDK installer downloaded successfully.

echo Installing Windows SDK... >> %log_file%
echo Installing Windows SDK...
start /wait "" "%sdk_installer%" /Quiet /NoRestart /Features + /InstallPath "%ProgramFiles%\Windows Kits\10" >> %log_file% 2>&1
if %errorlevel% neq 0 (
    echo Failed to install Windows SDK. >> %log_file%
    echo Failed to install Windows SDK.
    exit /b
)
echo Windows SDK installed successfully. >> %log_file%
echo Windows SDK installed successfully.

@echo off

:: Install Visual C++ Redist
echo Downloading Visual C++ Redistributable installers...

:: Create a temporary directory to store the installers
set "TMP_DIR=%TEMP%\vcredist_installers"
mkdir "%TMP_DIR%"

:: Download the latest Visual C++ Redistributable installers
bitsadmin /transfer "VC2015-2022 x64" https://aka.ms/vs/17/release/vc_redist.x64.exe "%TMP_DIR%\VC_redist.x64.exe"
bitsadmin /transfer "VC2015-2022 x86" https://aka.ms/vs/17/release/vc_redist.x86.exe "%TMP_DIR%\VC_redist.x86.exe"

echo Installing Visual C++ Redistributable packages...

:: Install Visual C++ 2015-2022 Redistributable
start /wait "%TMP_DIR%\VC_redist.x64.exe" /install /quiet /norestart
start /wait "%TMP_DIR%\VC_redist.x86.exe" /install /quiet /norestart

echo Visual C++ Redistributable packages installed successfully!

:: Clean up the temporary directory
rmdir /s /q "%TMP_DIR%"

pause

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

:: Step 2: Install .NET Framework 4.8 (NetFx4-AdvSrvs)
echo Installing .NET Framework 4.8 (NetFx4-AdvSrvs)... >> %log_file%
echo Installing .NET Framework 4.8 (NetFx4-AdvSrvs)...
dism /online /enable-feature /featurename:NetFx4-AdvSrvs /All /NoRestart >> %log_file% 2>&1
echo DISM command exit code: %errorlevel% >> %log_file%
if %errorlevel% neq 0 (
    echo Failed to install .NET Framework 4.8 (NetFx4-AdvSrvs). >> %log_file%
    echo Failed to install .NET Framework 4.8 (NetFx4-AdvSrvs). Check the log for details: %log_file%
    exit /b
)
echo .NET Framework 4.8 (NetFx4-AdvSrvs) installed successfully. >> %log_file%
echo .NET Framework 4.8 (NetFx4-AdvSrvs) installed successfully.

:: Step 3: Check for Visual Studio Build Tools
echo Checking for Visual Studio Build Tools... >> %log_file%
reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\SxS\VS7" >nul 2>&1
if %errorlevel% neq 0 (
    echo Visual Studio Build Tools not found. Downloading... >> %log_file%
    powershell -command "Invoke-WebRequest -Uri https://aka.ms/vs/16/release/vs_buildtools.exe -OutFile %installer%" >> %log_file% 2>&1
    if %errorlevel% neq 0 (
        echo Failed to download Visual Studio Build Tools installer. >> %log_file%
        echo Failed to download Visual Studio Build Tools installer.
        pause
        exit /b
    )
    echo Running Visual Studio Build Tools installer... >> %log_file%
    start /wait "" "%installer%" --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --passive --norestart >> %log_file% 2>&1
    if %errorlevel% neq 0 (
        echo Failed to install Visual Studio Build Tools. >> %log_file%
        echo Failed to install Visual Studio Build Tools.
        pause
        exit /b
    )
    echo Visual Studio Build Tools installed successfully. >> %log_file%
) else (
    echo Visual Studio Build Tools are already installed. >> %log_file%
)
