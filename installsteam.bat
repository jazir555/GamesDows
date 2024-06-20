@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion

:: Define Steam folder path
SET "STEAM_FOLDER=C:\Program Files (x86)\Steam"

:: Check if Steam is installed
IF NOT EXIST "%STEAM_FOLDER%\Steam.exe" (
    echo Steam is not installed. Downloading and installing Steam...

    :: Define download URL
    SET "STEAM_INSTALLER_URL=https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe"

    :: Download Steam installer
    echo Downloading Steam installer...
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $url='https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe'; $path='%TEMP%\SteamSetup.exe'; Invoke-WebRequest $url -OutFile $path; Start-Process -FilePath $path -ArgumentList '/S' -Wait"

    :: Check if Steam was installed
    IF NOT EXIST "%STEAM_FOLDER%\Steam.exe" (
        echo Steam installation failed. Please install Steam manually.
        pause
        exit /b 1
    )
)

echo Steam installed successfully!
pause
