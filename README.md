Transform your Windows Computer into a Video Game console first, PC second!

**This script is a WIP. Currently, the main functionality works as intended (certainly in V1). Steam Big Picture launches automatically when the OS boots, then explorer starts automatically after a delay, which allows you to exit to desktop via the menu without needing to launch a shortcut for Explorer.exe first.**

**Note: Steam or Playnite must be installed, you must be signed in to Steam if using the Steam variant, and finally the Steam Autostart entry in task manager must be disabled/deleted before running the script.**

**This script must be run as admin!**

# GamesDows
The Enable GamesDows batch script makes Windows boot straight into Steam Big Picture or Playnite without displaying any Explorer UI elements to ensure a Game Console like experience on Windows. I made this because I have a Steam Deck and I want the experience to mirror that of Steam OS as closely as possible. However, this will work on any Windows PC, the commands are not specific to the Steam Deck.

**How the main functionality works: The enable Game Mode batch script sets steam big picture as the shell (in V2 a VBS script is set as the shell when the computer boots, and then it immediately set Steam as the Shell, then runs a powershell command to start Steam or Playnite as admin> but launches steam as lower privileged (so the virtual mouse and keyboard don't work on system prompts such as task manager yet (in V1), it needs to run as admin to fix that. One of the 4 remaining problems, which again may be solved with V2) The enable Game Mode batch script creates a second VBS script to suppress the command prompt window when Explorer.exe launches in the background > The VBS script launches a second batch script created by the enable script creates and launches the second batch script via a scheduled task after a 20 second delay > delayed explorer batch script resets the shell to to explorer.exe, then launches explorer in the background so that it's possible to exit big picture without running a shortcut (menu performs as expected and exits directly to desktop without manually launching a separate shortcut).** 

After another delay once explorer.exe is started (it retains elevated permissions once started), the default shell is reset to Steam Big Picture so that it boots directly to Big Picture as expected upon reboot. In V2, the script is reset to the first VBS script which resets the shell to Playnite/Steam Big Picture so the loop starts again every reboot.

The powershell commands are run directly via the batch script, so no secondary powershell script is needed. Everything in the script is done automatically when run as admin.

**How the script works**

Here's a breakdown of what each part of the script does:

**1) Set Steam Big Picture as Default Shell:**

Disables echoing the command to the console (@echo off).

Enables the use of advanced scripting features (SETLOCAL EnableExtensions).

Changes the Windows shell from the default explorer.exe to Steam's Big Picture mode. It modifies the Windows Registry to make Steam.exe -bigpicture the default shell that launches upon user login.

**2) Creates and Sets Up a Delayed Start Script for Explorer:**

Defines paths for the Steam folder and Delayed Explorer Start script name.

Creates a batch file (DelayedExplorerStart.bat) that checks if the user is logged on. If the user is logged on, it sets the shell back to Windows Explorer (explorer.exe) after a delay, allowing Steam Big Picture to launch first.

After booting directly into Steam Big Picture, explorer.exe is launched automatically so that the "Exit to Desktop" menu item in Steam Big Picture works as expected. You do not need to launch a shortcut from within Big Picture first in order to be able exit to the desktop. The menu item will work as intended after the GamesDows script is run, no additional work necessary.

**3) Creates a VBScript to Run the Batch File Silently:**

A VBScript (RunBatchSilently.vbs) is created to run the DelayedExplorerStart.bat to suppress the command prompt window/run silently. This means the batch file will launch explorer in the background without opening a visible command prompt window over the Steam Big Picture UI.

**4) It Sets Up a Scheduled Task to Run the DelayedExplorerStart.bat Script at Logon/bootup:**

Creates an XML file to define a scheduled task. This task will trigger the VBScript at user logon.

Deletes any existing scheduled task with the same name and creates a new one using the XML configuration. This ensures that the DelayedExplorerStart.bat script runs every time the user logs on.

**5) Enable Automatic Logon and Disable Boot UI:**

Configures Windows to automatically log in with the current user account (AutoAdminLogon).

Sets an empty default password for automatic logon (DefaultPassword). If you have a password, please insert it into the empty quotation marks in the batch script inside this command. This is the command that inputs the user password, it is set to be blank by default. I have put a placeholder in the script breakdown here for clarity:

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d "YourPasswordGoesHere" /f

The command "bcdedit.exe -set {globalsettings} bootuxdisabled on" disables the boot user interface (bootuxdisabled). This disables Windows Branded Boot, and therefore no Windows logo is displayed when the OS boots.


What remains to be fixed:

1. Completely suppressing the taskbar from appearing when Windows Explorer automatically launches in the background. The taskbar displays temporarily for ~1 second when explorer.exe launches, which makes it appear over the Big Picture UI; and then it disappears. This is not intended behavior, and it is visually distracting. 

2. Disabling the Windows welcome sign-in UI animation (user picture, user name, spinning wheel) entirely. Currently the Boot logo is removed as intended, and the script is set to log the user account which ran the script in automatically. The welcome sign-in animation still remains, and will be disabled in future versions of the script. Going to have to write a custom C++ application to do so since there is no off the shelf way to disable the Welcome Screen on Windows 11.

3. (**Possibly solved in V2**)
  
Setting Steam to start as admin (VBS script to suppress the command prompt window set as the shell at boot > VBS script launches the batch script > batch sets steam big picture as the shell > batch launches steam as admin > delayed explorer batch script resets the shell to the VBS script so Steam launches as the default shell at boot.)

**Note: If for any reason explorer doesn't start, it needs to be launched manually via task manager by launching explorer.exe. It needs to be set as the shell first before it is launched for the desktop to appear when explorer is launched, otherwise it will just launch a file browser window**

4. Disabling the Steam client update window which displays momentarily when Steam updates (this only occurs when the Steam Client has an update, otherwise it will not appear) before launching Big Picture.

**Please let me know if you have any issues with existing functionality and I'll try to get the bugs fixed up if any arise.**

I will gladly take PRs to fix the 4 remaining issues if anyone knows how to solve them.
