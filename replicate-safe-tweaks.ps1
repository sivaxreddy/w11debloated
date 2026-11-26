<#
.SYNOPSIS
  Safe Windows 11 tweak replicator based on a read-only audit of a Windows 11 laptop.

.DESCRIPTION
  Applies only the low-risk, high-value tweaks from the audit:
    - Privacy / ads / telemetry / suggestions
    - GameDVR off, Game Mode on, HAGS on
    - Faster menus, no startup delay, no Aero Peek
    - NTFS last-access / 8.3-name tweaks
    - Defender scan CPU limit (no exclusions)
    - Memory Compression + Page Combining ENABLED (the audited machine had them off)
    - Optional: Store bloat removal, visual performance, power plan, Fast Startup off,
      telemetry services/tasks, Storage Sense, PowerShell 2.0 removal

  It deliberately does NOT:
    - disable WSearch, SysMain, NVIDIA, HP, SgrmBroker, Windows Update, or printing
    - add Defender exclusions (especially not %TEMP%)
    - change the pagefile, DNS, or install a custom power plan
    - remove Store/WebView2/VCLibs/UI.Xaml/frameworks

  HKCU tweaks apply to the account running the script. Run it from your own account
  with "Run as Administrator". If you elevate with a different admin account, HKCU
  changes land in that admin profile, not yours.

.PARAMETER DryRun
  Print what would change without writing anything.

.PARAMETER RemoveBloatApps
  Remove the explicit Store-app bloat list (current user + provisioned packages).
  Functional losses: Xbox overlays/Game Bar, Bing News/Weather/Search, Copilot,
  Solitaire, Clipchamp, Skype, Your Phone, People, Maps, 3D Viewer, Mixed Reality,
  Power Automate, To Do, LinkedIn, Spotify, Zune Music/Video, Widgets.

.PARAMETER ApplyVisualPerformance
  Set "best performance" visual effects consistently (disables animations/transparency).

.PARAMETER ApplyPowerTweaks
  Tune the ACTIVE power plan: 5-100% AC / 5-60% DC, aggressive boost, active cooling,
  PCIe ASPM off AC / on DC, USB suspend off AC / on DC, sleep 15 min DC, hibernate 2 h DC.
  Hardware-specific; skip on desktops or if you prefer stock battery behavior.

.PARAMETER DisableFastStartup
  Set HiberbootEnabled=0 (Fast Startup off). Good for dual-boot/SSD reliability.

.PARAMETER DisableTelemetryServices
  Disable DiagTrack and dmwappushservice only.

.PARAMETER DisableTelemetryTasks
  Disable the explicit telemetry/CEIP/diagnostic task list only.
  Does NOT touch .NET NGEN, Windows Update, activation, WinRE, or defrag tasks.

.PARAMETER EnableStorageSense
  Enable Storage Sense temp + Recycle Bin cleanup (not Downloads).

.PARAMETER DisablePowerShell2
  Remove the deprecated PowerShell 2.0 engine feature (security).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\replicate-safe-tweaks.ps1 -DryRun

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\replicate-safe-tweaks.ps1

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\replicate-safe-tweaks.ps1 -RemoveBloatApps -ApplyVisualPerformance -ApplyPowerTweaks -DisableFastStartup -DisableTelemetryServices -DisableTelemetryTasks -EnableStorageSense
#>

[CmdletBinding()]
param(
  [switch]$DryRun,
  [switch]$RemoveBloatApps,
  [switch]$ApplyVisualPerformance,
  [switch]$ApplyPowerTweaks,
  [switch]$DisableFastStartup,
  [switch]$DisableTelemetryServices,
  [switch]$DisableTelemetryTasks,
  [switch]$EnableStorageSense,
  [switch]$DisablePowerShell2
)

$ErrorActionPreference = 'Continue'
$script:Applied = New-Object System.Collections.Generic.List[string]
$script:Skipped = New-Object System.Collections.Generic.List[string]

function Step([string]$t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Note([string]$t) { Write-Host "  $t" -ForegroundColor DarkGray }
function Warn([string]$t) { Write-Host "  WARNING: $t" -ForegroundColor Yellow }
function Ok([string]$t) { Write-Host "  OK: $t" -ForegroundColor Green; $script:Applied.Add($t) }
function Skip([string]$t) { Write-Host "  SKIP: $t" -ForegroundColor DarkYellow; $script:Skipped.Add($t) }

function Set-RegValue {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)]$Value,
    [ValidateSet('DWord','String','QWord','ExpandString','MultiString','Binary')]
    [string]$Type = 'DWord'
  )
  if ($DryRun) {
    Write-Host "  [DryRun] $Path :: $Name = $Value ($Type)"
    return
  }
  try {
    if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -Type $Type -ErrorAction Stop
    Ok "$Path :: $Name = $Value"
  } catch {
    Warn "Failed $Path :: $Name -> $($_.Exception.Message)"
  }
}

function Set-SvcStart {
  param([Parameter(Mandatory)][string]$Name,[Parameter(Mandatory)][string]$StartupType)
  $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
  if (-not $svc) { Skip "Service $Name not found"; return }
  if ($DryRun) { Write-Host "  [DryRun] Set-Service $Name -StartupType $StartupType"; return }
  try {
    Set-Service -Name $Name -StartupType $StartupType -ErrorAction Stop
    Ok "Service $Name -> $StartupType"
  } catch {
    Warn "Failed service $Name -> $StartupType : $($_.Exception.Message)"
  }
}

function Disable-TaskSafe {
  param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$Name)
  if (-not $Path.EndsWith('\')) { $Path += '\' }
  $task = Get-ScheduledTask -TaskPath $Path -TaskName $Name -ErrorAction SilentlyContinue
  if (-not $task) { Skip "Task $Path$Name not found"; return }
  if ($task.State -eq 'Disabled') { Skip "Task $Path$Name already disabled"; return }
  if ($DryRun) { Write-Host "  [DryRun] Disable-ScheduledTask $Path$Name"; return }
  try {
    Disable-ScheduledTask -TaskPath $Path -TaskName $Name -ErrorAction Stop | Out-Null
    Ok "Task $Path$Name disabled"
  } catch {
    Warn "Failed task $Path$Name : $($_.Exception.Message)"
  }
}

function Remove-AppxSafe {
  param([Parameter(Mandatory)][string]$Name,[switch]$Provisioned)
  $pkg = Get-AppxPackage -Name $Name -ErrorAction SilentlyContinue
  if (-not $pkg) {
    Skip "Appx $Name not installed for current user"
  } elseif ($DryRun) {
    Write-Host "  [DryRun] Remove-AppxPackage $Name"
  } else {
    try {
      $pkg | Remove-AppxPackage -ErrorAction Stop
      Ok "Appx $Name removed"
    } catch {
      Warn "Failed to remove Appx $Name : $($_.Exception.Message)"
    }
  }

  if ($Provisioned) {
    $prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
      Where-Object { $_.DisplayName -eq $Name }
    if ($prov) {
      if ($DryRun) {
        Write-Host "  [DryRun] Remove-AppxProvisionedPackage $Name"
      } else {
        try {
          $prov | Remove-AppxProvisionedPackage -Online -ErrorAction Stop | Out-Null
          Ok "Provisioned Appx $Name removed"
        } catch {
          Warn "Failed to remove provisioned Appx $Name : $($_.Exception.Message)"
        }
      }
    }
  }
}

function Invoke-PowerCfg {
  param([Parameter(Mandatory)][string[]]$Arguments)
  if ($DryRun) {
    Write-Host "  [DryRun] powercfg $($Arguments -join ' ')"
    return
  }
  & powercfg @Arguments | Out-Null
  if ($LASTEXITCODE -eq 0) {
    Ok "powercfg $($Arguments -join ' ')"
  } else {
    Warn "powercfg failed ($LASTEXITCODE): $($Arguments -join ' ')"
  }
}

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
  throw 'Run this script from an elevated PowerShell window (Run as Administrator).'
}

$build = [Environment]::OSVersion.Version.Build
if ($build -lt 22000) {
  throw "This script targets Windows 11 (build 22000+). Detected build $build."
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = Join-Path $env:TEMP "win11-safe-tweaks-$stamp"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

try { Start-Transcript -Path (Join-Path $backupDir 'transcript.txt') -Force | Out-Null } catch { }

Write-Host "Windows 11 safe tweak replicator" -ForegroundColor White
Write-Host "Build: $build | User: $([Environment]::UserName) | DryRun: $DryRun" -ForegroundColor Gray
Write-Host "Log/backup folder: $backupDir" -ForegroundColor Gray

if (-not $DryRun) {
  try {
    Checkpoint-Computer -Description 'Before safe Windows tweaks' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
    Ok 'System restore point created'
  } catch {
    Warn "Could not create a restore point: $($_.Exception.Message). Enable System Restore if you want one."
  }
}

# ---------------------------------------------------------------------------
# 1. Privacy / telemetry / ads / suggestions
# ---------------------------------------------------------------------------
Step 'Privacy, telemetry, ads and suggestions'

# Telemetry policy. On Windows Pro, 0 may be treated as 1/Required; it is still the privacy-max setting.
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'DoNotShowFeedbackNotifications' 1
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'LimitDiagnosticLogCollection' 1
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'LimitDumpCollection' 1
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowDeviceNameInTelemetry' 0

Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 0
Set-RegValue 'HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted' 0
Set-RegValue 'HKCU:\Software\Microsoft\Input\TIPC' 'Enabled' 0
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' 'Value' 'Deny' -Type String

Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed' 0
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'PublishUserActivities' 0
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'UploadUserActivities' 0

Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableConsumerAccountStateContent' 1
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableSoftLanding' 1
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableCloudOptimizedContent' 1
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableThirdPartySuggestions' 1

$cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
Set-RegValue $cdm 'ContentDeliveryAllowed' 0
Set-RegValue $cdm 'OemPreInstalledAppsEnabled' 0
Set-RegValue $cdm 'PreInstalledAppsEnabled' 0
Set-RegValue $cdm 'PreInstalledAppsEverEnabled' 0
Set-RegValue $cdm 'SilentInstalledAppsEnabled' 0
Set-RegValue $cdm 'SoftLandingEnabled' 0
Set-RegValue $cdm 'SystemPaneSuggestionsEnabled' 0
Set-RegValue $cdm 'SubscribedContent-310093Enabled' 0
Set-RegValue $cdm 'SubscribedContent-338387Enabled' 0
Set-RegValue $cdm 'SubscribedContent-338388Enabled' 0
Set-RegValue $cdm 'SubscribedContent-338389Enabled' 0
Set-RegValue $cdm 'SubscribedContent-338393Enabled' 0
Set-RegValue $cdm 'SubscribedContent-353694Enabled' 0
Set-RegValue $cdm 'SubscribedContent-353696Enabled' 0
Set-RegValue $cdm 'SubscribedContent-353698Enabled' 0
Set-RegValue $cdm 'RotatingLockScreenEnabled' 0
Set-RegValue $cdm 'RotatingLockScreenOverlayEnabled' 0
Set-RegValue $cdm 'FeatureManagementEnabled' 0

Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement' 'ScoobeSystemSettingEnabled' 0

$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-RegValue $adv 'ShowSyncProviderNotifications' 0
Set-RegValue $adv 'Start_IrisRecommendations' 0
Set-RegValue $adv 'Start_TrackDocs' 0
Set-RegValue $adv 'Start_TrackProgs' 0
Set-RegValue $adv 'TaskbarDa' 0
Set-RegValue $adv 'TaskbarMn' 0
Set-RegValue $adv 'ShowTaskViewButton' 0
Set-RegValue $adv 'ShowCopilotButton' 0

Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 1

Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'CortanaConsent' 0
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'SearchboxTaskbarMode' 0
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings' 'IsDynamicSearchBoxEnabled' 0

$ws = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
Set-RegValue $ws 'AllowCortana' 0
Set-RegValue $ws 'DisableWebSearch' 1
Set-RegValue $ws 'ConnectedSearchUseWeb' 0
Set-RegValue $ws 'AllowSearchToUseLocation' 0

Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode' 0

# ---------------------------------------------------------------------------
# 2. Gaming / responsiveness
# ---------------------------------------------------------------------------
Step 'Gaming and responsiveness'

Set-RegValue 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0
Set-RegValue 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1

# HAGS: supported on modern NVIDIA/AMD GPUs. Ignored on unsupported hardware.
Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2

# Keep the windowed-game optimizations on.
Set-RegValue 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' 'DirectXUserGlobalSettings' 'VRROptimizeEnable=1;SwapEffectUpgradeEnable=1;' -Type String

# Faster shell feel.
Set-RegValue 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '50' -Type String
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize' 'StartupDelayInMSec' 1
Set-RegValue 'HKCU:\Software\Microsoft\Windows\DWM' 'EnableAeroPeek' 0

# Harmless gaming profile tweaks. GPU Priority/Priority/Scheduling Category are stock;
# only SFIO Priority=High differs. Kept for parity with the audited machine.
$sp = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
Set-RegValue $sp 'SystemResponsiveness' 10
Set-RegValue $sp 'NetworkThrottlingIndex' 0xFFFFFFFF
$games = "$sp\Tasks\Games"
Set-RegValue $games 'GPU Priority' 8
Set-RegValue $games 'Priority' 6
Set-RegValue $games 'Scheduling Category' 'High' -Type String
Set-RegValue $games 'SFIO Priority' 'High' -Type String

# ---------------------------------------------------------------------------
# 3. Filesystem / memory
# ---------------------------------------------------------------------------
Step 'Filesystem and memory'

# Modern default-ish, safe on SSD. 0x80000001 = user-managed + last-access updates disabled.
Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'NtfsDisableLastAccessUpdate' 0x80000001
Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'NtfsDisable8dot3NameCreation' 1

# The audited machine had these OFF; on 8 GB that is counter-productive.
if ($DryRun) {
  Write-Host '  [DryRun] Enable-MMAgent -MemoryCompression -PageCombining'
} else {
  try {
    Enable-MMAgent -MemoryCompression -PageCombining -ErrorAction Stop
    Ok 'Memory Compression + Page Combining enabled'
  } catch {
    Warn "Could not enable MMAgent features: $($_.Exception.Message)"
  }
}

# ---------------------------------------------------------------------------
# 4. Defender: scan CPU only, no exclusions
# ---------------------------------------------------------------------------
Step 'Defender scan CPU limit'

if ($DryRun) {
  Write-Host '  [DryRun] Set-MpPreference -ScanAvgCPULoadFactor 15'
} else {
  try {
    Set-MpPreference -ScanAvgCPULoadFactor 15 -ErrorAction Stop
    Ok 'Defender ScanAvgCPULoadFactor = 15'
  } catch {
    Warn "Could not set Defender scan CPU limit: $($_.Exception.Message)"
  }
}

# ---------------------------------------------------------------------------
# 5. Optional: visual performance
# ---------------------------------------------------------------------------
if ($ApplyVisualPerformance) {
  Step 'Visual performance (optional)'
  Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2
  Set-RegValue $adv 'TaskbarAnimations' 0
  Set-RegValue $adv 'ListviewAlphaSelect' 0
  Set-RegValue $adv 'ListviewShadow' 0
  Set-RegValue 'HKCU:\Control Panel\Desktop\WindowMetrics' 'MinAnimate' '0' -Type String
  Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
} else {
  Skip 'Visual performance not applied (use -ApplyVisualPerformance)'
}

# ---------------------------------------------------------------------------
# 6. Optional: Fast Startup off
# ---------------------------------------------------------------------------
if ($DisableFastStartup) {
  Step 'Fast Startup off (optional)'
  Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled' 0
} else {
  Skip 'Fast Startup unchanged (use -DisableFastStartup)'
}

# ---------------------------------------------------------------------------
# 7. Optional: power plan
# ---------------------------------------------------------------------------
if ($ApplyPowerTweaks) {
  Step 'Power plan tweaks (optional, hardware-specific)'
  Invoke-PowerCfg @('setacvalueindex','SCHEME_CURRENT','SUB_PROCESSOR','PROCTHROTTLEMIN','5')
  Invoke-PowerCfg @('setdcvalueindex','SCHEME_CURRENT','SUB_PROCESSOR','PROCTHROTTLEMIN','5')
  Invoke-PowerCfg @('setacvalueindex','SCHEME_CURRENT','SUB_PROCESSOR','PROCTHROTTLEMAX','100')
  Invoke-PowerCfg @('setdcvalueindex','SCHEME_CURRENT','SUB_PROCESSOR','PROCTHROTTLEMAX','60')
  Invoke-PowerCfg @('setacvalueindex','SCHEME_CURRENT','SUB_PROCESSOR','PERFBOOSTMODE','2')
  Invoke-PowerCfg @('setdcvalueindex','SCHEME_CURRENT','SUB_PROCESSOR','PERFBOOSTMODE','2')
  Invoke-PowerCfg @('setacvalueindex','SCHEME_CURRENT','SUB_PROCESSOR','SYSCOOLPOL','1')
  Invoke-PowerCfg @('setdcvalueindex','SCHEME_CURRENT','SUB_PROCESSOR','SYSCOOLPOL','1')
  Invoke-PowerCfg @('setacvalueindex','SCHEME_CURRENT','SUB_PCIEXPRESS','ASPM','0')
  Invoke-PowerCfg @('setdcvalueindex','SCHEME_CURRENT','SUB_PCIEXPRESS','ASPM','1')
  Invoke-PowerCfg @('setacvalueindex','SCHEME_CURRENT','SUB_USB','USBSELECTIVESUSPEND','0')
  Invoke-PowerCfg @('setdcvalueindex','SCHEME_CURRENT','SUB_USB','USBSELECTIVESUSPEND','1')
  Invoke-PowerCfg @('setacvalueindex','SCHEME_CURRENT','SUB_DISK','DISKIDLE','1200')
  Invoke-PowerCfg @('setdcvalueindex','SCHEME_CURRENT','SUB_DISK','DISKIDLE','1200')
  Invoke-PowerCfg @('setacvalueindex','SCHEME_CURRENT','SUB_SLEEP','STANDBYIDLE','0')
  Invoke-PowerCfg @('setdcvalueindex','SCHEME_CURRENT','SUB_SLEEP','STANDBYIDLE','900')
  Invoke-PowerCfg @('setacvalueindex','SCHEME_CURRENT','SUB_SLEEP','HIBERNATEIDLE','0')
  Invoke-PowerCfg @('setdcvalueindex','SCHEME_CURRENT','SUB_SLEEP','HIBERNATEIDLE','7200')
  Invoke-PowerCfg @('setacvalueindex','SCHEME_CURRENT','SUB_SLEEP','RTCWAKE','0')
  Invoke-PowerCfg @('setdcvalueindex','SCHEME_CURRENT','SUB_SLEEP','RTCWAKE','0')
  Invoke-PowerCfg @('setactive','SCHEME_CURRENT')
  Note 'On battery, set the Windows power mode slider to Balanced if you prefer battery life over latency.'
} else {
  Skip 'Power plan unchanged (use -ApplyPowerTweaks)'
}

# ---------------------------------------------------------------------------
# 8. Optional: telemetry services
# ---------------------------------------------------------------------------
if ($DisableTelemetryServices) {
  Step 'Telemetry services (optional)'
  Set-SvcStart 'DiagTrack' 'Disabled'
  Set-SvcStart 'dmwappushservice' 'Disabled'
} else {
  Skip 'Telemetry services unchanged (use -DisableTelemetryServices)'
}

# ---------------------------------------------------------------------------
# 9. Optional: telemetry tasks
# ---------------------------------------------------------------------------
if ($DisableTelemetryTasks) {
  Step 'Telemetry / CEIP tasks (optional)'
  $tasks = @(
    @('\Microsoft\Windows\Application Experience\', 'Microsoft Compatibility Appraiser'),
    @('\Microsoft\Windows\Application Experience\', 'ProgramDataUpdater'),
    @('\Microsoft\Windows\Customer Experience Improvement Program\', 'Consolidator'),
    @('\Microsoft\Windows\Customer Experience Improvement Program\', 'UsbCeip'),
    @('\Microsoft\Windows\DiskDiagnostic\', 'Microsoft-Windows-DiskDiagnosticDataCollector'),
    @('\Microsoft\Windows\Maintenance\', 'WinSAT'),
    @('\Microsoft\Windows\Autochk\', 'Proxy'),
    @('\Microsoft\Windows\Diagnosis\', 'Scheduled'),
    @('\Microsoft\Windows\Power Efficiency Diagnostics\', 'AnalyzeSystem'),
    @('\Microsoft\Windows\Maps\', 'MapsUpdateTask'),
    @('\Microsoft\Windows\MemoryDiagnostic\', 'ProcessMemoryDiagnosticEvents'),
    @('\Microsoft\Windows\MemoryDiagnostic\', 'RunFullMemoryDiagnostic'),
    @('\Microsoft\Windows\Windows Error Reporting\', 'QueueReporting'),
    @('\Microsoft\Windows\Feedback\Siuf\', 'DmClient'),
    @('\Microsoft\Windows\Feedback\Siuf\', 'DmClientOnScenarioDownload'),
    @('\Microsoft\Windows\PI\', 'Sqm-Tasks')
  )
  foreach ($t in $tasks) { Disable-TaskSafe -Path $t[0] -Name $t[1] }
} else {
  Skip 'Telemetry tasks unchanged (use -DisableTelemetryTasks)'
}

# ---------------------------------------------------------------------------
# 10. Optional: Storage Sense
# ---------------------------------------------------------------------------
if ($EnableStorageSense) {
  Step 'Storage Sense (optional)'
  $ss = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
  Set-RegValue $ss '01' 1
  Set-RegValue $ss '04' 1
  Set-RegValue $ss '08' 1
  Set-RegValue $ss '32' 0
  Set-RegValue $ss '2048' 0
} else {
  Skip 'Storage Sense unchanged (use -EnableStorageSense)'
}

# ---------------------------------------------------------------------------
# 11. Optional: remove Store bloat
# ---------------------------------------------------------------------------
if ($RemoveBloatApps) {
  Step 'Store app bloat removal (optional)'
  $bloat = @(
    'Microsoft.XboxApp',
    'Microsoft.XboxGamingOverlay',
    'Microsoft.XboxGameOverlay',
    'Microsoft.XboxSpeechToTextOverlay',
    'Microsoft.BingNews',
    'Microsoft.BingWeather',
    'Microsoft.BingSearch',
    'Microsoft.Copilot',
    'Microsoft.WindowsCopilot',
    'Microsoft.Windows.Ai.Copilot.Provider',
    'MicrosoftWindows.Client.AIX',
    'Microsoft.MicrosoftSolitaireCollection',
    'Clipchamp.Clipchamp',
    'Microsoft.Getstarted',
    'Microsoft.WindowsFeedbackHub',
    'Microsoft.SkypeApp',
    'Microsoft.YourPhone',
    'Microsoft.People',
    'Microsoft.WindowsMaps',
    'Microsoft.Microsoft3DViewer',
    'Microsoft.MixedReality.Portal',
    'Microsoft.PowerAutomateDesktop',
    'Microsoft.Todos',
    'Microsoft.LinkedIn',
    'SpotifyAB.SpotifyMusic',
    'Microsoft.ZuneMusic',
    'Microsoft.ZuneVideo',
    'Microsoft.WindowsWidgets',
    'MicrosoftWindows.Client.WebExperience'
  )
  foreach ($app in $bloat) { Remove-AppxSafe -Name $app -Provisioned }
  Note 'Kept: Store, DesktopAppInstaller, Terminal, WSL, Photos, Camera, Calculator, Notepad, Paint, Snipping Tool, Sound Recorder, Sticky Notes, Mail/Calendar, OfficeHub, OneDrive, new Teams, Xbox GamingApp, Xbox Identity Provider, GetHelp, WebView2/VCLibs/UI.Xaml.'
} else {
  Skip 'Store apps unchanged (use -RemoveBloatApps)'
}

# ---------------------------------------------------------------------------
# 12. Optional: PowerShell 2.0 off
# ---------------------------------------------------------------------------
if ($DisablePowerShell2) {
  Step 'PowerShell 2.0 removal (optional)'
  if ($DryRun) {
    Write-Host '  [DryRun] Disable-WindowsOptionalFeature MicrosoftWindowsPowerShellV2Root/V2'
  } else {
    try {
      Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root -NoRestart -ErrorAction Stop | Out-Null
      Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2 -NoRestart -ErrorAction Stop | Out-Null
      Ok 'PowerShell 2.0 engine disabled'
    } catch {
      Warn "Could not disable PowerShell 2.0: $($_.Exception.Message)"
    }
  }
} else {
  Skip 'PowerShell 2.0 unchanged (use -DisablePowerShell2)'
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Step 'Summary'
Write-Host "Applied: $($script:Applied.Count)" -ForegroundColor Green
Write-Host "Skipped: $($script:Skipped.Count)" -ForegroundColor DarkYellow
Write-Host "Log: $backupDir" -ForegroundColor Gray

Write-Host @'

Deliberately NOT changed (review manually):
  - WSearch / SysMain / NVIDIA / HP / SgrmBroker / Windows Update / Spooler
  - Defender exclusions (never exclude %TEMP% or SppExtComObjHook.dll)
  - Pagefile size, DNS servers, custom power-plan GUID
  - Store, WebView2, VCLibs, UI.Xaml, WindowsAppRuntime

Reboot is recommended for HAGS, memory compression, power, and Store-app changes.
On 8 GB laptops, adding a second 8 GB DDR4-3200 stick is worth more than any registry tweak.
'@ -ForegroundColor Gray

if (-not $DryRun) { try { Stop-Transcript | Out-Null } catch { } }

