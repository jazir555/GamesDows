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

:: Step 5: Create the C++ source file using PowerShell
echo Creating C++ source file using PowerShell... >> %log_file%
powershell -command "Add-Content -Path '%cpp_code%' -Value '#include <windows.h>'; Add-Content -Path '%cpp_code%' -Value 'int APIENTRY wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPWSTR lpCmdLine, int nCmdShow)'; Add-Content -Path '%cpp_code%' -Value '{'; Add-Content -Path '%cpp_code%' -Value '    return 0;'; Add-Content -Path '%cpp_code%' -Value '}';"
if %errorlevel% neq 0 (
    echo Failed to create the C++ source file using PowerShell. >> %log_file%
    echo Failed to create the C++ source file using PowerShell.
    pause
    exit /b
)
echo C++ source file created successfully using PowerShell. >> %log_file%

:: Step 6: Compile the C++ code to create the custom executable
echo Compiling the C++ source file... >> %log_file%
call "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x86 >> %log_file% 2>&1
if %errorlevel% neq 0 (
    echo Failed to set up Visual Studio environment. >> %log_file%
    echo Failed to set up Visual Studio environment.
    pause
    exit /b
)
cl %cpp_code% /Fe:%exe_name% /link /SUBSYSTEM:WINDOWS > %compile_log% 2>&1
if %errorlevel% neq 0 (
    echo Compilation failed. >> %log_file%
    echo Compilation failed. Check the compile.log for details. >> %log_file%
    pause
    exit /b
)
echo C++ source file compiled successfully. >> %log_file%

:: Step 7: Ensure the custom executable was created
if not exist "%src_path%%exe_name%" (
    echo Custom executable %exe_name% not found in %src_path%. >> %log_file%
    echo Custom executable %exe_name% not found in %src_path%.
    pause
    exit /b
)
echo Custom executable found. >> %log_file%
pause

:: Step 8: Backup the original logonui.exe
echo Backing up the original logonui.exe... >> %log_file%
copy "%dst_path%\logonui.exe" "%dst_path%\%backup_logonui%" >> %log_file% 2>&1
if %errorlevel% neq 0 (
    echo Failed to backup the original logonui.exe. >> %log_file%
    echo Failed to backup the original logonui.exe.
    pause
    exit /b
)
echo Original logonui.exe backed up successfully. >> %log_file%
pause

:: Step 9: Replace the original logonui.exe with the custom executable
echo Replacing the original logonui.exe with the custom executable... >> %log_file%
copy "%src_path%%exe_name%" "%dst_path%\logonui.exe" >> %log_file% 2>&1
if %errorlevel% neq 0 (
    echo Failed to replace logonui.exe. >> %log_file%
    echo Failed to replace logonui.exe.
    pause
    exit /b
)
echo logonui.exe replaced successfully. >> %log_file%
pause

echo All changes applied successfully. Please restart your computer. >> %log_file%
echo All changes applied successfully. Please restart your computer.
pause
