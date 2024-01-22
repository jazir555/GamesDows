**This script is a WIP. Currently, the main functionality works as intended. Steam Big Picture launches automatically when the OS boots, then explorer starts automatically after a delay, which allows you to exit to desktop via the menu without needing to launch a shortcut for Explorer.exe first.**

What remains to be fixed:

1. Completely suppressing the taskbar when Windows Explorer automatically launches. The taskbar displays for a second when Explorer starts, which makes it appear over the Big Picture UI for a second, and then it disappears. This is not intended behavior, and it is visually distracting.

2. Disabling the Windows welcome screen entirely. Currently the Boot logo is removed as intended, and the script is set to log the user account which ran the script in automatically. The welcome screen still remains, and will be disabled in future versions of the script.

3. Need to modify the batch script which starts explorer via the scheduled task to set the shell back to Big Picture once Explorer starts so that Game Mode persists between reboots. The registry key for the default shell needs to be reset to point to explorer.exe before the Explorer shell can be launched. Currently the script does not change the shell back to Big Picture after Explorer.exe is launched, which means Game Mode does not persist across reboots.

# Windows Game Mode
The Enable Game Mode script makes Windows boots straight into Steam Big Picture without displaying any Explorer UI elements to ensure a Game Console like experience on Windows. I made this because I have a Steam Deck and I want the experience to mirror that of Steam OS as closely as possible. However, this will work on any Windows PC, the commands are not specific to the Steam Deck.

**Here's a breakdown of what each part of the script does**:

**1. Set Steam Big Picture as Default Shell:**

Disables echoing the command to the console (@echo off).

Enables the use of advanced scripting features (SETLOCAL EnableExtensions).

Changes the Windows shell from the default explorer.exe to Steam's Big Picture mode. It modifies the Windows Registry to make Steam.exe -bigpicture the default shell that launches upon user login.

**2. Create and Set Up a Delayed Start Script for Explorer:**

Defines paths for the Steam folder and Delayed Explorer Start script name.

Creates a batch file (DelayedExplorerStart.bat) that checks if the user is logged on. If the user is logged on, it sets the shell back to Windows Explorer (explorer.exe) after a delay, allowing Steam Big Picture to launch first. 

After booting directly into Steam Big Picture, Explorer.exe is launched automatically so that the "Exit to Desktop" menu item in Steam Big Picture works as expected. You do not need to launch a shortcut from within Big Picture first in order to be able exit to the desktop.

**3. Create a VBScript to Run the Batch File Silently:**

A VBScript (RunBatchSilently.vbs) is created to run the DelayedExplorerStart.bat to suppress the command prompt window/run silently. This means the batch file will launch explorer in the background without opening a visible command prompt window over the Steam Big Picture UI.

**4. Set Up a Scheduled Task to Run the DelayedExplorerStart.bat Script at Logon/bootup:**

Creates an XML file to define a scheduled task. This task will trigger the VBScript at user logon.

Deletes any existing scheduled task with the same name and creates a new one using the XML configuration. This ensures that the DelayedExplorerStart.bat script runs every time the user logs on.

**5. Enable Automatic Logon and Disable Boot UI:**

Configures Windows to automatically log in with the current user account (AutoAdminLogon).

Sets an empty default password for automatic logon (DefaultPassword).

6. The command "bcdedit.exe -set {globalsettings} bootuxdisabled on" disables the boot user interface (bootuxdisabled). This disables Windows Branded Boot, and therefore no Windows logo is displayed when the OS boots.

**Revert Script**

The Revert script reverts all changes, which resets the Windows configuration to what it was before the Enable Game Mode script was run. If the script fails to revert any of the changes, they can be manually removed. If needed, delete the Scheduled Task created in Task Scheduler called "RunDelayedExplorerStart". This script currently creates the scripts the scheduled task runs and the XML file for the scheduled task inside the default Steam Installation Directory, "C:\Program Files (x86)\Steam".
