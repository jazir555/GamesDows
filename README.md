# Windows-Game-Mode
Windows boots straight into Steam Big Picture without displaying any explorer UI elements

**Here's a breakdown of what each part of the script does**:

**1. Set Steam Big Picture as Default Shell:**
Disables echoing the command to the console (@echo off).
Enables the use of advanced scripting features (SETLOCAL EnableExtensions).
Changes the Windows shell from the default explorer.exe to Steam's Big Picture mode. It modifies the Windows Registry to make Steam.exe -bigpicture the default shell that launches upon user login.

**2. Create and Set Up a Delayed Start Script for Explorer:**

Defines paths for the Steam folder and script names.

Creates a batch file (DelayedExplorerStart.bat) that checks if the user is logged on. If the user is logged on, it sets the shell back to Windows Explorer (explorer.exe) after a delay, allowing Steam Big Picture to launch first.

**3. Create a VBScript to Run the Batch File Silently:**

A VBScript (RunBatchSilently.vbs) is created to run the DelayedExplorerStart.bat silently. This means the batch file will run without opening a visible command prompt window.

**4. Set Up a Scheduled Task to Run the Script at Logon:**

Prepares an XML file to define a scheduled task. This task will trigger the VBScript at user logon.

Deletes any existing scheduled task with the same name and creates a new one using the XML configuration. This ensures that the DelayedExplorerStart.bat script runs every time the user logs on.

**5. Enable Automatic Logon and Disable Boot UI:**

Configures Windows to automatically log in with the current user account (AutoAdminLogon).
Sets an empty default password for automatic logon (DefaultPassword).
Disables the boot user interface (bootuxdisabled), which affects the visual elements displayed during system startup.
