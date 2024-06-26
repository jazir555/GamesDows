@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion

:: Set your username, password, and computer name
SET "USERNAME=your_username"
SET "PASSWORD=your_password"
SET "COMPUTER_NAME=%COMPUTERNAME%"

:: Enable AutoAdminLogon
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f

:: Set DefaultUserName
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d "%USERNAME%" /f

:: Set DefaultPassword
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d "%PASSWORD%" /f

:: Set DefaultDomainName to the computer name
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultDomainName /t REG_SZ /d "%COMPUTER_NAME%" /f

:: Create VBScript to handle netplwiz automation
echo Set WshShell = CreateObject("WScript.Shell") > ConfigureAutoLogin.vbs
echo WshShell.Run "netplwiz", 1, True >> ConfigureAutoLogin.vbs
echo WScript.Sleep 500 >> ConfigureAutoLogin.vbs
echo WshShell.SendKeys "{TAB}" >> ConfigureAutoLogin.vbs
echo WshShell.SendKeys "{TAB}" >> ConfigureAutoLogin.vbs
echo WshShell.SendKeys "{ENTER}" >> ConfigureAutoLogin.vbs
echo WScript.Sleep 500 >> ConfigureAutoLogin.vbs
echo WshShell.SendKeys "%USERNAME%" >> ConfigureAutoLogin.vbs
echo WshShell.SendKeys "{TAB}" >> ConfigureAutoLogin.vbs
echo WshShell.SendKeys "%PASSWORD%" >> ConfigureAutoLogin.vbs
echo WshShell.SendKeys "{TAB}" >> ConfigureAutoLogin.vbs
echo WshShell.SendKeys "%PASSWORD%" >> ConfigureAutoLogin.vbs
echo WshShell.SendKeys "{ENTER}" >> ConfigureAutoLogin.vbs
echo WScript.Sleep 500 >> ConfigureAutoLogin.vbs
echo WshShell.SendKeys "{ENTER}" >> ConfigureAutoLogin.vbs

:: Run the VBScript
cscript //nologo ConfigureAutoLogin.vbs

:: Clean up
del ConfigureAutoLogin.vbs

echo Automatic login enabled with the specified username and password.
