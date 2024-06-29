@echo off
SETLOCAL EnableExtensions

echo Setting Steam Big Picture as default shell

echo Set Steam Big Picture as the default shell
SET "KEY_NAME=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
SET "VALUE_NAME=Shell"
SET "STEAM_PATH=C:\Program Files (x86)\Steam\Steam.exe -bigpicture -nobootstrapupdate -skipinitialbootstrap -skipverifyfiles"
REG ADD "%KEY_NAME%" /v %VALUE_NAME% /t REG_SZ /d "%STEAM_PATH%" /f


@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion

echo Define the default Steam folder path and script names
SET "STEAM_FOLDER=C:\Program Files (x86)\Steam"
SET "SCRIPT_NAME=DelayedExplorerStart.bat"
SET "SCRIPT_FOLDER=C:\GamesDows"
SET "SCRIPT_PATH=%SCRIPT_FOLDER%\%SCRIPT_NAME%"
SET "EXPLORER_PATH=C:\Windows\explorer.exe"

echo Creating DelayedExplorerStart.bat script

echo Create the DelayedExplorerStart.bat script in the Script folder
(
echo @echo off
echo Check if user is logged on
echo query user ^| find /i "%USERNAME%" ^>nul
echo if ERRORLEVEL 1 exit
echo Set Shell back to Explorer
echo REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "%EXPLORER_PATH%" /f
echo timeout /t 15 /nobreak ^>nul
echo start C:\Windows\explorer.exe
echo timeout /t 10 /nobreak ^>nul
echo REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "%STEAM_PATH%" /f
) > "%SCRIPT_PATH%"


echo %VBS_PATH% 

echo Creating RunBatchSilently.vbs script

:: Create VBScript to run the batch file silently
@echo off
SET "VBS_NAME=RunBatchSilently.vbs"
SET "VBS_PATH=%SCRIPT_FOLDER%\%VBS_NAME%"
echo Set WshShell = CreateObject("WScript.Shell") > "%VBS_PATH%"
echo WshShell.Run chr(34)^&"%SCRIPT_FOLDER%"^&chr(34), 0, True >> "%VBS_PATH%"
echo Set WshShell = Nothing >> "%VBS_PATH%"

echo Create XML file for the scheduled task
SET XML_PATH="%SCRIPT_FOLDER%\DelayedExplorerStartTask.xml"

echo Delete the existing XML file if it exists
IF EXIST "%XML_PATH%" DEL "%XML_PATH%"

(
echo ^<?xml version="1.0" encoding="UTF-16"?^>
echo ^<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^>
echo   ^<RegistrationInfo^>
echo     ^<Date^>2020-01-01T00:00:00^</Date^>
echo     ^<Author^>"%USERNAME%"^</Author^>
echo     ^<Description^>Run DelayedExplorerStart.bat at logon.^</Description^>
echo   ^</RegistrationInfo^>
echo   ^<Triggers^>
echo     ^<LogonTrigger^>
echo       ^<Enabled^>true^</Enabled^>
echo     ^</LogonTrigger^>
echo   ^</Triggers^>
echo   ^<Principals^>
echo     ^<Principal id="Author"^>
echo       ^<UserId^>%USERNAME%</UserId^>
echo       ^<LogonType^>InteractiveToken^</LogonType^>
echo       ^<RunLevel^>HighestAvailable^</RunLevel^>
echo     ^</Principal^>
echo   ^</Principals^>
echo   ^<Settings^>
echo       ^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^>
echo       ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^>
echo       ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^>
echo       ^<AllowHardTerminate^>true^</AllowHardTerminate^>
echo       ^<StartWhenAvailable^>true^</StartWhenAvailable^>
echo       ^<RunOnlyIfNetworkAvailable^>false^</RunOnlyIfNetworkAvailable^>
echo       ^<IdleSettings^>
echo         ^<StopOnIdleEnd^>true^</StopOnIdleEnd^>
echo         ^<RestartOnIdle^>false^</RestartOnIdle^>
echo       ^</IdleSettings^>
echo       ^<Enabled^>true^</Enabled^>
echo       ^<Hidden^>false^</Hidden^>
echo       ^<WakeToRun^>false^</WakeToRun^>
echo       ^<ExecutionTimeLimit^>PT72H^</ExecutionTimeLimit^>
echo       ^<Priority^>7^</Priority^>
echo   ^</Settings^>
echo   ^<Actions Context="Author"^>
echo     ^<Exec^>
echo       ^<Command^>wscript.exe^</Command^>
echo       ^<Arguments^>"%VBS_PATH%"^</Arguments^>
echo     ^</Exec^>
echo   ^</Actions^>
echo ^</Task^>
) > "%XML_PATH%"

echo Delete the existing scheduled task if it exists
schtasks /delete /tn "RunDelayedExplorerStart" /f

echo Create the scheduled task using the XML file
schtasks /create /tn "RunDelayedExplorerStart" /xml "%XML_PATH%"

echo Delayed Explorer start script and VBScript created in Steam folder.
echo Scheduled Task added to run the script at logon.
echo XML file for Scheduled Task created.

echo Enable automatic logon
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d "%USERNAME%" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d "" /f

echo Disable the boot UI
bcdedit.exe -set {globalsettings} bootuxdisabled on

echo Disable Logon UI

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DisableLogonUI /t REG_DWORD /d 1 /f

echo Disable Visual Effects
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v VisualEffects /t REG_DWORD /d 3 /f

echo Increase File System Performance
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisableLastAccessUpdate /t REG_DWORD /d 1 /f

@echo off

REM Disable Fast Startup to ensure changes take effect
powercfg -h off

REM Disable the lock screen (effective for Enterprise/Education)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v NoLockScreen /t REG_DWORD /d 1 /f

REM Set the logon background to black by setting a custom background
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v DisableLogonBackgroundImage /t REG_DWORD /d 1 /f

REM Create the backgrounds folder if it doesn't exist
if not exist "C:\Windows\System32\oobe\info\backgrounds" (
    mkdir "C:\Windows\System32\oobe\info\backgrounds"
)

REM Generate a black image using PowerShell
powershell -command "Add-Type -AssemblyName System.Drawing; $width = 1920; $height = 1080; $bitmap = New-Object System.Drawing.Bitmap $width, $height; $graphics = [System.Drawing.Graphics]::FromImage($bitmap); $black = [System.Drawing.Brushes]::Black; $graphics.FillRectangle($black, 0, 0, $width, $height); $bitmap.Save('C:\Windows\System32\oobe\info\backgrounds\backgroundDefault.jpg', [System.Drawing.Imaging.ImageFormat]::Jpeg); $graphics.Dispose(); $bitmap.Dispose();"

REM Set the custom black background image for the lock screen
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v LockScreenImage /t REG_SZ /d "C:\Windows\System32\oobe\info\backgrounds\backgroundDefault.jpg" /f

REM Do not display last signed-in user name
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DontDisplayLastUserName /t REG_DWORD /d 1 /f

REM Do not display the username and other information during sign-in
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DontDisplayLockedUserId /t REG_DWORD /d 3 /f

REM Disable Windows animations during sign-in
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableStatusMessages /t REG_DWORD /d 1 /f

REM Disable verbose status messages
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v VerboseStatus /t REG_DWORD /d 0 /f

REM Disable the Welcome screen and reduce animation delay
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DelayedDesktopSwitchTimeout /t REG_DWORD /d 0 /f

REM Disable lock screen transitions
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v DisableLockScreenAppNotifications /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v DisableLogonUIAnimations /t REG_DWORD /d 1 /f

echo Disable Startup Delay
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f

echo Improve Windows Explorer Process Priority
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\explorer.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 3 /f
echo Adjust Large System Cache
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 1 /f
echo Enabling No GUI Boot
bcdedit /set {current} quietboot on

echo Registry modifications are complete.
echo Steam Big Picture set as default shell.
echo Automatic logon enabled.
echo Boot UI disabled.

pause

