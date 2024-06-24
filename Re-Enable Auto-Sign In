@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion

:: Set your username and password
SET "USERNAME=your_username"
SET "PASSWORD=your_password"

:: Enable AutoAdminLogon
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f

:: Set DefaultUserName
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d "%USERNAME%" /f

:: Set DefaultPassword
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d "%PASSWORD%" /f

echo Automatic login enabled with the specified username and password.
pause
