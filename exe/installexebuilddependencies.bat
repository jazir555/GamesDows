@echo off
SETLOCAL EnableDelayedExpansion

:: ==========================================================================
:: Script to Install C++ Build Dependencies (MinGW-w64 via Chocolatey)
:: Requires Administrator privileges and Internet connection.
:: Handles potential non-fatal warnings from choco install for mingw.
:: ==========================================================================

:: Check for Admin privileges
echo Checking for administrative privileges...
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo ERROR: This script requires administrative privileges.
    echo Please right-click and select "Run as administrator".
    pause
    goto :EOF
) else (
    echo Running with administrative privileges.
)
echo.

:: Define Variables
SET "CHOCO_INSTALL_CMD=Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
SET "MINGW_PACKAGE=mingw"
SET "INSTALL_ATTEMPTED=0"

:: --- Step 1: Check/Install Chocolatey ---
echo Checking for Chocolatey installation...
choco -? >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Chocolatey not found. Attempting to install...
    echo This requires PowerShell and an internet connection.
    powershell -NoProfile -ExecutionPolicy Bypass -Command "%CHOCO_INSTALL_CMD%"
    IF %ERRORLEVEL% NEQ 0 (
        echo ERROR: Chocolatey installation failed. Please check your internet connection
        echo and PowerShell execution policy settings. Manual installation may be required.
        echo Visit https://chocolatey.org/install for instructions.
        pause
        goto :EOF
    ) ELSE (
        echo Chocolatey installation appears successful.
        echo NOTE: You might need to open a NEW command prompt for choco to be fully available in PATH.
        echo Running 'refreshenv' command now to attempt immediate PATH refresh...
        refreshenv
        REM Small delay to allow environment refresh
        timeout /t 3 /nobreak >nul
    )
) ELSE (
    echo Chocolatey is already installed.
)
echo.

:: Verify Choco again after potential install/refresh
choco -? >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Chocolatey command is still not available after installation attempt.
    echo Please open a new Administrator command prompt and try running this script again,
    echo or install MinGW manually.
    pause
    goto :EOF
)

:: --- Step 2: Check/Install MinGW-w64 ---
echo Checking if '%MINGW_PACKAGE%' package is installed via Chocolatey...
choco list --local-only --exact "%MINGW_PACKAGE%" | findstr /B /C:"%MINGW_PACKAGE%" >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo '%MINGW_PACKAGE%' package not found or check failed. Attempting to install/ensure...
    SET "INSTALL_ATTEMPTED=1"
    choco install %MINGW_PACKAGE% --yes --force --no-progress
    IF %ERRORLEVEL% NEQ 0 (
        echo WARNING: 'choco install %MINGW_PACKAGE%' finished with a non-zero exit code.
        echo This might be due to non-fatal warnings (like missing old paths).
        echo Continuing to verification step, but check output above carefully.
        REM Do not exit here, let the g++ check be the final arbiter
    ) ELSE (
        echo 'choco install %MINGW_PACKAGE%' command completed successfully (Exit Code 0).
    )
    echo Running 'refreshenv' command to attempt PATH update...
    refreshenv
    REM Small delay to allow environment refresh
    timeout /t 3 /nobreak >nul
) ELSE (
    echo '%MINGW_PACKAGE%' package appears to be already installed.
)
echo.

:: --- Step 3: Verify g++ availability ---
echo Verifying g++ command availability...
where g++ >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: 'g++' command was not found in the current PATH even after installation attempt/check.
    IF "!INSTALL_ATTEMPTED!"=="1" (
         echo Possible causes:
         echo   - The 'mingw' package installation truly failed despite reporting success internally. Check logs.
         echo   - The PATH environment variable hasn't updated in this session yet.
    ) ELSE (
         echo Possible cause: The PATH environment variable hasn't updated in this session yet.
    )
    echo.
    echo IMPORTANT: Please CLOSE this window and open a NEW Administrator
    echo command prompt. Then try running the build script.
    pause
    goto :EOF
) ELSE (
    echo Verification successful: 'g++' command found in PATH:
    where g++
    echo.
    echo ==========================================================================
    echo Build Dependency Installation/Verification Complete!
    echo ==========================================================================
    echo MinGW-w64 (containing g++) should be ready.
    IF "!INSTALL_ATTEMPTED!"=="1" (
        echo NOTE: If the build script still fails, ensure you run it from a NEW command prompt.
    )
    echo.
)

pause
ENDLOCAL
goto :EOF