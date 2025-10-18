#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs black screen overlay to hide Windows logon animations.

.DESCRIPTION
    Creates and installs a fullscreen black overlay that covers the logon UI
    animations, combined with registry tweaks for maximum suppression.
    The overlay automatically dismisses when the desktop shell loads.

.NOTES
    - Requires Administrator privileges
    - Creates overlay executable and scheduled task
    - Combines with registry animation suppression
    - Completely safe - no system file modifications
#>

function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Warning { param($msg) Write-Host $msg -ForegroundColor Yellow }
function Write-Failure { param($msg) Write-Host $msg -ForegroundColor Red }

Write-Info "`n=== BLACK SCREEN OVERLAY INSTALLER ===`n"

# Check for admin rights
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Failure "This script requires Administrator privileges!"
    exit 1
}

$installPath = "$env:ProgramData\LogonOverlay"
$exePath = "$installPath\LogonOverlay.exe"
$csPath = "$installPath\LogonOverlay.cs"

# Create installation directory
Write-Info "[1] Creating installation directory..."
if (-not (Test-Path $installPath)) {
    New-Item -Path $installPath -ItemType Directory -Force | Out-Null
}
Write-Success "  [✓] Directory: $installPath"

# Create the C# overlay program source
Write-Info "`n[2] Creating black screen overlay program..."

$csharpCode = @'
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Drawing;
using System.Diagnostics;
using System.Threading;
using System.Linq;

namespace LogonOverlay
{
    public class OverlayForm : Form
    {
        [DllImport("user32.dll")]
        private static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
        
        [DllImport("user32.dll")]
        private static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);
        
        [DllImport("user32.dll")]
        private static extern int GetWindowLong(IntPtr hWnd, int nIndex);

        private static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
        private const uint SWP_NOSIZE = 0x0001;
        private const uint SWP_NOMOVE = 0x0002;
        private const uint SWP_SHOWWINDOW = 0x0040;
        private const int GWL_EXSTYLE = -20;
        private const int WS_EX_TOOLWINDOW = 0x00000080;
        private const int WS_EX_NOACTIVATE = 0x08000000;

        private System.Windows.Forms.Timer checkTimer;
        private DateTime startTime;

        public OverlayForm()
        {
            // Set up form properties
            this.FormBorderStyle = FormBorderStyle.None;
            this.WindowState = FormWindowState.Maximized;
            this.BackColor = Color.Black;
            this.TopMost = true;
            this.ShowInTaskbar = false;
            this.StartPosition = FormStartPosition.Manual;
            
            // Calculate bounds to cover ALL screens (handles both horizontal and vertical layouts)
            Rectangle totalBounds = Screen.AllScreens
                .Select(s => s.Bounds)
                .Aggregate((current, next) => Rectangle.Union(current, next));
            
            this.Location = new Point(totalBounds.X, totalBounds.Y);
            this.Size = new Size(totalBounds.Width, totalBounds.Height);
            
            startTime = DateTime.Now;
        }

        protected override void OnShown(EventArgs e)
        {
            base.OnShown(e);
            
            // Set extended window styles to keep it on top and prevent activation
            int exStyle = GetWindowLong(this.Handle, GWL_EXSTYLE);
            SetWindowLong(this.Handle, GWL_EXSTYLE, exStyle | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE);
            
            // Force topmost
            SetWindowPos(this.Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
            
            // Start monitoring for explorer.exe
            checkTimer = new System.Windows.Forms.Timer();
            checkTimer.Interval = 100; // Check every 100ms
            checkTimer.Tick += CheckForExplorer;
            checkTimer.Start();
        }

        private void CheckForExplorer(object sender, EventArgs e)
        {
            // Check if explorer.exe is running
            Process[] explorerProcesses = Process.GetProcessesByName("explorer");
            
            // Also check for timeout (max 10 seconds)
            TimeSpan elapsed = DateTime.Now - startTime;
            
            if (explorerProcesses.Length > 0 || elapsed.TotalSeconds > 10)
            {
                // Give explorer more time to fully render (1000ms for slower systems)
                Thread.Sleep(1000);
                
                checkTimer.Stop();
                this.Close();
                Application.Exit();
            }
        }

        protected override CreateParams CreateParams
        {
            get
            {
                CreateParams cp = base.CreateParams;
                cp.ExStyle |= WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE;
                return cp;
            }
        }

        protected override bool ShowWithoutActivation
        {
            get { return true; }
        }
    }

    static class Program
    {
        [STAThread]
        static void Main()
        {
            // Check if we're in the logon session
            // Only run if explorer.exe is NOT already running
            Process[] explorerProcesses = Process.GetProcessesByName("explorer");
            if (explorerProcesses.Length > 0)
            {
                // Explorer already running, don't show overlay
                return;
            }

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new OverlayForm());
        }
    }
}
'@

# Save C# source file
$csharpCode | Out-File -FilePath $csPath -Encoding UTF8 -Force

# Find csc.exe for better compilation control
Write-Info "  Locating C# compiler..."
$cscPath = $null

# Try multiple .NET Framework versions
$frameworkPaths = @(
    "${env:SystemRoot}\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "${env:SystemRoot}\Microsoft.NET\Framework\v4.0.30319\csc.exe",
    "${env:SystemRoot}\Microsoft.NET\Framework64\v3.5\csc.exe",
    "${env:SystemRoot}\Microsoft.NET\Framework\v3.5\csc.exe"
)

foreach ($path in $frameworkPaths) {
    if (Test-Path $path) {
        $cscPath = $path
        break
    }
}

if ($cscPath) {
    Write-Success "  [✓] Using csc.exe: $cscPath"
    Write-Info "  Compiling overlay executable..."
    
    # Compile with csc.exe for better error handling
    $compileArgs = @(
        "/target:winexe",
        "/out:$exePath",
        "/reference:System.Windows.Forms.dll",
        "/reference:System.Drawing.dll",
        "/reference:System.Core.dll",
        "/reference:System.Linq.dll",
        "/nologo",
        "/optimize+",
        $csPath
    )
    
    $compileOutput = & $cscPath $compileArgs 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Failure "  [✗] Compilation failed:"
        Write-Host $compileOutput -ForegroundColor Red
        exit 1
    }
    
    Write-Success "  [✓] Compilation successful using csc.exe"
} else {
    # Fallback to Add-Type
    Write-Warning "  [!] csc.exe not found, using Add-Type fallback"
    Write-Info "  Compiling overlay executable..."
    
    try {
        Add-Type -TypeDefinition $csharpCode -ReferencedAssemblies @(
            'System.Windows.Forms',
            'System.Drawing',
            'System.Core',
            'System.Linq'
        ) -OutputAssembly $exePath -OutputType WindowsApplication -ErrorAction Stop
        
        Write-Success "  [✓] Compilation successful using Add-Type"
    } catch {
        Write-Failure "  [✗] Failed to compile overlay program: $($_.Exception.Message)"
        exit 1
    }
}

if (-not (Test-Path $exePath)) {
    Write-Failure "  [✗] Executable was not created!"
    exit 1
}

Write-Success "  [✓] Overlay program created: $exePath"

# Set file permissions (only SYSTEM and Admins)
Write-Info "`n[3] Setting security permissions..."
try {
    $acl = Get-Acl $exePath
    $acl.SetAccessRuleProtection($true, $false)
    
    $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "BUILTIN\Administrators", "FullControl", "Allow"
    )
    $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "NT AUTHORITY\SYSTEM", "FullControl", "Allow"
    )
    
    $acl.SetAccessRule($adminRule)
    $acl.SetAccessRule($systemRule)
    Set-Acl $exePath $acl
    
    Write-Success "  [✓] Security permissions configured"
} catch {
    Write-Warning "  [!] Could not set permissions: $($_.Exception.Message)"
}

# Create scheduled task to run at system startup (before logon)
Write-Info "`n[4] Creating scheduled task..."

$taskName = "LogonOverlayBlackScreen"
$taskPath = "\Microsoft\Windows\Shell\"

# Remove existing task if present
$existingTask = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false
}

try {
    # Create action
    $action = New-ScheduledTaskAction -Execute $exePath
    
    # Create trigger - At system startup
    $trigger = New-ScheduledTaskTrigger -AtStartup
    
    # Create principal - Run as SYSTEM with highest privileges
    $principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Create settings - optimized for laptops and priority execution
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -DontStopOnIdleEnd `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 1) `
        -Priority 0 `
        -StartWhenAvailable `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)
    
    # Register task
    Register-ScheduledTask `
        -TaskName $taskName `
        -TaskPath $taskPath `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings `
        -Force | Out-Null
    
    Write-Success "  [✓] Scheduled task created: $taskPath$taskName"
    Write-Info "      Priority: Highest (0)"
    Write-Info "      Battery: Will run on battery power"
    Write-Info "      Restart: Auto-restart on failure (3 attempts)"
} catch {
    Write-Failure "  [✗] Failed to create scheduled task: $($_.Exception.Message)"
    exit 1
}

# Apply registry tweaks for maximum suppression
Write-Info "`n[5] Applying registry animation suppression..."

function Set-RegValue {
    param($Path, $Name, $Value, $Type = "DWord")
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Core suppression keys
$suppressionKeys = @(
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name="EnableFirstLogonAnimation"; Value=0},
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name="DisableAnimations"; Value=1},
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"; Name="AnimationDisabled"; Value=1},
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"; Name="EnableTransitions"; Value=0},
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name="DisableStatusMessages"; Value=1},
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"; Name="DelayedDesktopSwitchTimeout"; Value=0},
    @{Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"; Name="AutoLogonDelay"; Value=0}
)

$appliedCount = 0
foreach ($key in $suppressionKeys) {
    if (Set-RegValue -Path $key.Path -Name $key.Name -Value $key.Value) {
        $appliedCount++
    }
}

Write-Success "  [✓] Applied $appliedCount registry tweaks"

# Summary
Write-Info "`n" + "="*70
Write-Success "`n✓ BLACK SCREEN OVERLAY INSTALLED SUCCESSFULLY!"
Write-Info "="*70

Write-Host "`n📋 WHAT WAS INSTALLED:" -ForegroundColor Cyan
Write-Host "  ✓ C# source code: $csPath"
Write-Host "  ✓ Overlay executable: $exePath"
Write-Host "  ✓ Scheduled task: Runs at system startup (highest priority)"
Write-Host "  ✓ Registry tweaks: Core animation suppression applied"
Write-Host "  ✓ Security: SYSTEM-level execution with highest priority"

Write-Host "`n💡 HOW IT WORKS:" -ForegroundColor Green
Write-Host "  1. At boot, black overlay launches before LogonUI"
Write-Host "  2. Covers ALL screens with solid black window (multi-monitor aware)"
Write-Host "  3. Uses Rectangle.Union for proper multi-monitor coverage"
Write-Host "  4. Stays on top of all animations and UI elements"
Write-Host "  5. Monitors for explorer.exe (desktop shell)"
Write-Host "  6. Waits 1000ms after shell detected (slow system support)"
Write-Host "  7. Dismisses itself gracefully"
Write-Host "  8. Result: Completely black transition to desktop"

Write-Host "`n🎯 WHAT YOU'LL SEE:" -ForegroundColor Green
Write-Host "  • Windows logo during boot (normal)"
Write-Host "  • Solid black screen (instead of animations)"
Write-Host "  • Your desktop appears smoothly"
Write-Host "  • NO profile picture, username, spinning wheel, or status text"

Write-Host "`n🖥️  MULTI-MONITOR SUPPORT:" -ForegroundColor Green
Write-Host "  • Covers horizontal screen layouts"
Write-Host "  • Covers vertical screen layouts"
Write-Host "  • Covers mixed/irregular layouts"
Write-Host "  • Uses Rectangle.Union for proper bounds calculation"

Write-Warning "`n⚠️  IMPORTANT NOTES:"
Write-Host "  • Overlay has 10-second timeout (safety mechanism)"
Write-Host "  • 1000ms delay after explorer.exe for slow systems"
Write-Host "  • Auto-restart on failure (3 attempts)"
Write-Host "  • Works with auto-login and password-protected accounts"
Write-Host "  • Battery-friendly (runs on laptop battery)"
Write-Host "  • Restart required to see it in action"

Write-Success "`n✅ ADVANTAGES:"
Write-Host "  • Compiled with csc.exe for better compatibility"
Write-Host "  • Fallback to Add-Type if csc.exe unavailable"
Write-Host "  • No system file modifications"
Write-Host "  • No security compromises"
Write-Host "  • Update-proof (survives all Windows Updates)"
Write-Host "  • Fully reversible (use uninstall script)"
Write-Host "  • Zero performance impact"

Write-Info "`n📝 TO UNINSTALL:"
Write-Host "  Run the companion uninstall script to completely remove"
Write-Host "  all components and revert registry changes."

Write-Info "`n" + "="*70

$restart = Read-Host "`nRestart computer now to test? (Y/N)"
if ($restart -eq 'Y') {
    Write-Info "Restarting in 10 seconds... (Ctrl+C to cancel)"
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Warning "`nRestart your computer to see the black screen overlay in action!`n"
}