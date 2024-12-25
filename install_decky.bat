@echo off
setlocal EnableDelayedExpansion

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please run this script as administrator.
    pause
    exit /b 1
)

:: Check Python version
echo Checking Python version...
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo Python is not installed or not in PATH
    echo Please install Python and try again
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('python -c "import sys; print(sys.executable)"') do set PYTHON_PATH=%%i

:: Check dependencies
echo Checking dependencies...

:: Check Node.js and npm
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo Node.js is not installed or not in PATH
    echo Please install Node.js and try again
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('node -v') do set NODE_VERSION=%%i
for /f "tokens=*" %%i in ('npm -v') do set NPM_VERSION=%%i
echo Node.js !NODE_VERSION! with npm !NPM_VERSION! is installed

:: Add npm global path to PATH
for /f "tokens=*" %%i in ('npm config get prefix') do set NPM_PREFIX=%%i
set "PATH=%NPM_PREFIX%;%PATH%"

:: Ensure pnpm is installed globally
where pnpm >nul 2>nul
if %errorlevel% neq 0 (
    echo Installing pnpm globally...
    npm install -g pnpm
)

:: Get pnpm version
for /f "tokens=*" %%i in ('pnpm -v') do set PNPM_VERSION=%%i
echo pnpm version !PNPM_VERSION! is installed

:: Check git
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo git is not installed or not in PATH
    echo Please install git and try again
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('git --version') do set GIT_VERSION=%%i
echo !GIT_VERSION! is installed

echo All dependencies are satisfied

:: Get the directory of this batch file
set "SCRIPT_DIR=%~dp0"

:: Run the Python script with full environment
echo Running Decky Loader installer...
"%PYTHON_PATH%" "%SCRIPT_DIR%decky_builder.py"

if errorlevel 1 (
    echo Error during build process: %ERRORLEVEL%
    :: Clean up any remaining processes
    taskkill /F /IM python.exe /T >nul 2>&1
    taskkill /F /IM node.exe /T >nul 2>&1
    exit /b %ERRORLEVEL%
)

:: Clean up any remaining processes
taskkill /F /IM python.exe /T >nul 2>&1
taskkill /F /IM node.exe /T >nul 2>&1

echo Build completed successfully.
pause
