@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion

echo Reverting automatic logon settings

:: Check if AutoAdminLogon is set to 1 and revert it to 0 if necessary
REG QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon | findstr /i "1" >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo Disabling AutoAdminLogon
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 0 /f
) ELSE (
    echo AutoAdminLogon is not set to 1, no change needed
)

:: Check if DefaultUserName is set and remove it if necessary
REG QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo Removing DefaultUserName
    reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /f
) ELSE (
    echo DefaultUserName is not set, no change needed
)

:: Check if DefaultPassword is set and remove it if necessary
REG QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo Removing DefaultPassword
    reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /f
) ELSE (
    echo DefaultPassword is not set, no change needed
)

echo Automatic logon settings have been reverted.
