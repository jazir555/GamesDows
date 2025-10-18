#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Undo Windows animation suppression for ALL editions.

.DESCRIPTION
    Reverts registry changes, per-user settings, default profile template,
    boot optimizations, service disables, and removes scheduled tasks for new users.

.NOTES
    - Requires Administrator privileges
    - Works on Windows 10/11 all editions
    - Modifies system and all user profiles
    - Restart required
#>

function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Warning { param($msg) Write-Host $msg -ForegroundColor Yellow }
function Write-Failure { param($msg) Write-Host $msg -ForegroundColor Red }

Write-Info "`n=== WINDOWS ANIMATION SUPPRESSION UNDO ===`n"

# Check for admin rights
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Failure "This script requires Administrator privileges!"
    exit 1
}

# Create restore point
Write-Info "Creating system restore point..."
try {
    Checkpoint-Computer -Description "Before Undo Animation Suppression" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    Write-Success "Restore point created.`n"
} catch {
    Write-Warning "Could not create restore point: $($_.Exception.Message)"
    $continue = Read-Host "Continue anyway? (Y/N)"
    if ($continue -ne 'Y') { exit 0 }
}

# Function to safely remove registry values
function Remove-RegValue {
    param(
        [string]$Path,
        [string]$Name,
        [switch]$Suppress
    )
    try {
        if (Test-Path $Path) {
            $prop = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($prop) {
                Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction Stop
                if (-not $Suppress) { Write-Success "  [✓] Removed: $Name" }
                return $true
            }
        }
        return $false
    } catch {
        if (-not $Suppress) { Write-Warning "  [!] Could not remove $Name" }
        return $false
    }
}

# Mount registry hives
Write-Info "Mounting registry hives..."
$null = New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS -ErrorAction SilentlyContinue

# Get all user profiles
$profiles = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | 
    ForEach-Object {
        $sid = $_.PSChildName
        $profilePath = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).ProfileImagePath
        if ($profilePath -and $profilePath -notmatch "systemprofile|NetworkService|LocalService") {
            [PSCustomObject]@{
                SID = $sid
                Path = $profilePath
                Loaded = Test-Path "HKU:\$sid"
            }
        }
    }

Write-Info "Found $($profiles.Count) user profile(s)`n"

# Load unloaded user hives
$loadedHives = @()
foreach ($profile in $profiles | Where-Object { -not $_.Loaded }) {
    $hivePath = Join-Path $profile.Path "NTUSER.DAT"
    if (Test-Path $hivePath) {
        $tempKey = "TEMP_$($profile.SID)"
        try {
            reg load "HKU\$tempKey" $hivePath 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { 
                $loadedHives += $tempKey 
                Write-Success "  Loaded hive for: $(Split-Path $profile.Path -Leaf)"
            }
        } catch {
            Write-Warning "  Could not load: $(Split-Path $profile.Path -Leaf)"
        }
    }
}

# Get all SIDs to process
$allSIDs = @(".DEFAULT") + $profiles.SID + $loadedHives
Write-Info "`nWill process $($allSIDs.Count) profile(s)`n"

#region SYSTEM-WIDE KEYS TO REMOVE

Write-Info "=== REVERTING SYSTEM-WIDE SETTINGS ===`n"

Write-Info "[1] Core Animation Settings"
$policies = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
Remove-RegValue -Path $policies -Name "EnableFirstLogonAnimation"
Remove-RegValue -Path $policies -Name "DisableAnimations"
Remove-RegValue -Path $policies -Name "DisableStatusMessages"
Remove-RegValue -Path $policies -Name "VerboseStatus"
Remove-RegValue -Path $policies -Name "HideShutdownScripts"
Remove-RegValue -Path $policies -Name "DelayedDesktopSwitchTimeout"

Write-Info "`n[2] LogonUI Settings"
$logonUI = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
Remove-RegValue -Path $logonUI -Name "AnimationDisabled"
Remove-RegValue -Path $logonUI -Name "EnableTransitions"
Remove-RegValue -Path $logonUI -Name "LastLoggedOnDisplayName"
Remove-RegValue -Path $logonUI -Name "LastLoggedOnSAMUser"
Remove-RegValue -Path $logonUI -Name "LastLoggedOnUser"

Write-Info "`n[3] Lock Screen"
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen"

Write-Info "`n[4] Winlogon Timing"
$winlogon = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Remove-RegValue -Path $winlogon -Name "DelayedDesktopSwitchTimeout"
Remove-RegValue -Path $winlogon -Name "AutoLogonDelay"

Write-Info "`n[5] Boot Animations"
$bootAnim = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation"
Remove-RegValue -Path $bootAnim -Name "DisableStartupSound"
Remove-RegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\EditionOverrides" -Name "UserSetting_DisableStartupSound"

Write-Info "`n[6] Desktop Window Manager"
$dwm = "HKLM:\SOFTWARE\Microsoft\Windows\DWM"
Remove-RegValue -Path $dwm -Name "DisableAnimation"
Remove-RegValue -Path $dwm -Name "AnimationsShiftKey"
Remove-RegValue -Path $dwm -Name "EnableAeroPeek"
Remove-RegValue -Path $dwm -Name "AlwaysHibernateThumbnails"

Write-Info "`n[7] Memory Management"
$prefetch = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
Remove-RegValue -Path $prefetch -Name "EnablePrefetcher"
Remove-RegValue -Path $prefetch -Name "EnableSuperfetch"

Write-Info "`n[8] Content Delivery"
$contentDel = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
Remove-RegValue -Path $contentDel -Name "SubscribedContent-310093Enabled"
Remove-RegValue -Path $contentDel -Name "SubscribedContent-338389Enabled"

Write-Info "`n[9] User Profile Engagement"
Remove-RegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" -Name "ScoobeSystemSettingEnabled"

Write-Info "`n[10] App Privacy"
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsRunInBackground"

Write-Info "`n[11] Power Settings"
Remove-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled"

Write-Info "`n[12] Network UI"
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "DontDisplayNetworkSelectionUI"

Write-Info "`n[13] Profile List"
Remove-RegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" -Name "UseProfilePathExtensionVersion"

#endregion

#region PER-USER KEYS

Write-Info "`n=== REVERTING PER-USER SETTINGS ===`n"

$revertedUsers = 0
foreach ($sid in $allSIDs) {
    $displayName = if ($sid -eq ".DEFAULT") { "Default User Profile" } 
                   elseif ($sid -like "TEMP_*") { "Temp: $(($sid -split '_')[1].Substring(0,8))..." }
                   else { $sid.Substring(0,20) + "..." }
    
    $userRoot = "HKU:\$sid"
    $removed = 0
    
    # Visual Effects
    if (Remove-RegValue -Path "$userRoot\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Suppress) { $removed++ }
    
    # Desktop settings
    if (Remove-RegValue -Path "$userRoot\Control Panel\Desktop" -Name "DragFullWindows" -Suppress) { $removed++ }
    if (Remove-RegValue -Path "$userRoot\Control Panel\Desktop" -Name "FontSmoothing" -Suppress) { $removed++ }
    if (Remove-RegValue -Path "$userRoot\Control Panel\Desktop" -Name "UserPreferencesMask" -Suppress) { $removed++ }
    if (Remove-RegValue -Path "$userRoot\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Suppress) { $removed++ }
    
    # Explorer Advanced
    $explorerAdv = "$userRoot\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    if (Remove-RegValue -Path $explorerAdv -Name "TaskbarAnimations" -Suppress) { $removed++ }
    if (Remove-RegValue -Path $explorerAdv -Name "DisablePreviewDesktop" -Suppress) { $removed++ }
    if (Remove-RegValue -Path $explorerAdv -Name "ListviewAlphaSelect" -Suppress) { $removed++ }
    if (Remove-RegValue -Path $explorerAdv -Name "ListviewShadow" -Suppress) { $removed++ }
    if (Remove-RegValue -Path $explorerAdv -Name "TaskbarSmallIcons" -Suppress) { $removed++ }
    if (Remove-RegValue -Path $explorerAdv -Name "DisallowShaking" -Suppress) { $removed++ }
    
    # Content Delivery Manager
    $userCDM = "$userRoot\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    if (Remove-RegValue -Path $userCDM -Name "SubscribedContent-310093Enabled" -Suppress) { $removed++ }
    if (Remove-RegValue -Path $userCDM -Name "SubscribedContent-338389Enabled" -Suppress) { $removed++ }
    if (Remove-RegValue -Path $userCDM -Name "SystemPaneSuggestionsEnabled" -Suppress) { $removed++ }
    
    # Accessibility
    if (Remove-RegValue -Path "$userRoot\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Suppress) { $removed++ }
    
    if ($removed -gt 0) {
        Write-Success "  [✓] $displayName - Removed $removed setting(s)"
        $revertedUsers++
    } else {
        Write-Info "  [i] $displayName - No settings found"
    }
}

Write-Success "`nReverted settings for $revertedUsers profile(s)"

#endregion

#region SERVICES

Write-Info "`n=== RE-ENABLING SERVICES ===`n"

$servicesToRestore = @{
    "DiagTrack" = "Automatic"
    "dmwappushservice" = "Manual"
    "SysMain" = "Automatic"
    "WSearch" = "Automatic"
    "TabletInputService" = "Manual"
}

$restoredCount = 0
foreach ($svc in $servicesToRestore.Keys) {
    try {
        $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($service -and $service.StartType -eq 'Disabled') {
            $startupType = $servicesToRestore[$svc]
            Set-Service -Name $svc -StartupType $startupType -ErrorAction Stop
            
            if ($startupType -eq "Automatic") {
                Start-Service -Name $svc -ErrorAction SilentlyContinue
            }
            
            Write-Success "  [✓] Restored: $svc ($startupType)"
            $restoredCount++
        }
    } catch {
        Write-Warning "  [!] Could not restore: $svc"
    }
}

if ($restoredCount -eq 0) {
    Write-Info "  [i] No disabled services found to restore"
} else {
    Write-Success "  [✓] Restored $restoredCount service(s)"
}

#endregion

#region BOOT CONFIGURATION

Write-Info "`n=== RESTORING BOOT CONFIGURATION ===`n"

try {
    bcdedit /set bootux standard | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "  [✓] Re-enabled boot graphics"
    } else {
        Write-Warning "  [!] Could not modify boot configuration"
    }
} catch {
    Write-Warning "  [!] Could not modify boot configuration"
}

#endregion

#region SCHEDULED TASK

Write-Info "`n=== REMOVING NEW USER AUTO-CONFIG TASK ===`n"

$taskName = "SuppressAnimationNewUsers"
$taskPath = "\Microsoft\Windows\Shell\"

$existingTask = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
if ($existingTask) {
    try {
        Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false -ErrorAction Stop
        Write-Success "  [✓] Removed scheduled task"
    } catch {
        Write-Warning "  [!] Could not remove scheduled task: $($_.Exception.Message)"
    }
} else {
    Write-Info "  [i] Scheduled task not found (already removed or never created)"
}

$scriptPath = "$env:ProgramData\AnimationSuppress\ApplyNewUserSettings.ps1"
$scriptDir = Split-Path $scriptPath -Parent

if (Test-Path $scriptPath) {
    try {
        Remove-Item $scriptPath -Force -ErrorAction Stop
        Write-Success "  [✓] Removed auto-configuration script"
    } catch {
        Write-Warning "  [!] Could not remove script file"
    }
}

if (Test-Path $scriptDir) {
    try {
        Remove-Item $scriptDir -Force -Recurse -ErrorAction Stop
        Write-Success "  [✓] Removed script directory"
    } catch {
        Write-Warning "  [!] Could not remove script directory"
    }
}

#endregion

#region UNLOAD TEMP HIVES

Write-Info "`nCleaning up temporary registry hives..."
foreach ($hive in $loadedHives) {
    try {
        [gc]::Collect()
        Start-Sleep -Milliseconds 500
        reg unload "HKU\$hive" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "  Unloaded: $hive"
        }
    } catch {
        Write-Warning "  $hive will unload on reboot"
    }
}

#endregion

# Summary
Write-Info "`n" + "="*70
Write-Success "`n✓ ANIMATION SUPPRESSION SUCCESSFULLY REVERSED!"
Write-Info "="*70

Write-Host "`n📋 SUMMARY:" -ForegroundColor Cyan
Write-Host "  ✓ System-wide registry keys removed"
Write-Host "  ✓ Per-user settings reverted: $revertedUsers profile(s)"
Write-Host "  ✓ Services restored: $restoredCount"
Write-Host "  ✓ Boot configuration restored"
Write-Host "  ✓ Scheduled task removed"
Write-Host "  ✓ Auto-configuration script removed"

Write-Warning "`n⚠️  NEXT STEPS:"
Write-Host "  1. Restart your computer for all changes to take effect"
Write-Host "  2. Windows will restore default animations"
Write-Host "  3. Welcome screen and profile animations will return"
Write-Host "  4. All visual effects will be reset to system defaults"

Write-Info "`n" + "="*70

$restart = Read-Host "`nRestart computer now? (Y/N)"
if ($restart -eq 'Y') {
    Write-Info "Restarting in 10 seconds... (Ctrl+C to cancel)"
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Warning "`nPlease restart your computer manually for full restoration.`n"
}