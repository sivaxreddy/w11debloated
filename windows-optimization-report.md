# Windows 11 Optimization Audit

**Machine:** audited Windows 11 laptop - HP Pavilion Gaming 15 (Ryzen 5 5600H)
**OS:** Windows 11 Pro 22H2, build **22621.4317**
**CPU / RAM / GPU:** Ryzen 5 5600H / **8 GB single-channel (1 of 2 slots)** / RTX 3050 Ti Laptop 4 GB + Radeon iGPU
**Disk:** WD SN730 512 GB NVMe — C: 200 GB (90.5 GB free), D: 100 GB (27.7 GB free)
**Audit date:** 2026-11-26
**Changes made:** **None.** This was a read-only audit. The script mentioned at the end was not run.

---

## 1. Verdict

| Area | Score | Comment |
|---|---:|---|
| Debloat / privacy / ads | **8.5 / 10** | Genuinely good: telemetry, ads, Copilot, Recall, Widgets, Bing web search, GameDVR and many Store apps are off. |
| Performance tuning | **6 / 10** | Some good gaming tweaks, but the machine is fighting an 8 GB single-channel RAM bottleneck **with memory compression turned off**. |
| Stability / security / maintenance | **4 / 10** | Windows 22H2 is out of support (Oct 2024), Defender excludes `Temp` and `SppExtComObjHook.dll`, PowerShell 2.0 is enabled, and several update/activation/.NET tasks are disabled. |
| Overall | **6.5 / 10** | **Debloated: yes. Fully optimal: no.** It is a well-privacy-tuned machine with a few self-inflicted performance and security problems. |

### The three biggest findings

1. **8 GB single-channel RAM is the real bottleneck.** At audit time: 7.12 GB used of 7.3 GB, only ~0.4 GB free, 204 processes, commit limit 15.3 GB. One 8 GB Hynix DDR4-3200 stick is installed; the laptop has **2 slots and supports 32 GB**. Adding a second 8 GB stick gives 16 GB **dual-channel** — the single best upgrade for this Ryzen laptop.
2. **Memory Compression and Page Combining are disabled.** `Get-MMAgent` shows `MemoryCompression=False`, `PageCombining=False`. On 8 GB this is backwards; it increases paging and makes the machine feel slower. Enable both.
3. **Windows 11 22H2 is EOL.** Build 22621.4317 is the final 22H2-era build; 22H2 Pro support ended **2024-10-08**. This machine has had no security updates since then. Upgrade to a supported release (**26H2**; 25H2 is still supported until Oct 2027, but 26H2 is current) — ideally after the RAM upgrade. From 22H2 you need an in-place ISO upgrade/Installation Assistant; the 25H2/26H2 enablement package requires 24H2/25H2 first.

---

## 2. Hardware / OS snapshot

| Item | Value |
|---|---|
| OS | Windows 11 Pro 22H2, 22621.4317 |
| CPU | AMD Ryzen 5 5600H, 6C/12T, 3.3 GHz base |
| RAM | 8 GB Hynix HMA81GS6DJR8N-XN, DDR4-3200, **1 of 2 slots used** |
| Max RAM | 32 GB (firmware `MaxCapacityEx`) |
| GPU | NVIDIA RTX 3050 Ti Laptop 4 GB (driver 580.97) + Radeon iGPU |
| Disk | WD SN730 512 GB NVMe; C: 200 GB, D: 100 GB, Y: 2 GB FAT32 |
| Power | Custom plan **“Work Stable”**, S3 sleep + hibernation available, Fast Startup off |
| Boot | Fast Startup disabled (`HiberbootEnabled=0`) |

**RAM note:** The second slot is free. A matching 8 GB DDR4-3200 **CL22** SODIMM (ideally another **1Rx8** module, like the existing Hynix HMA81GS6DJR8N-XN) gives 16 GB dual-channel. Do not buy a single 16 GB stick and leave the old 8 GB in the other slot unless you deliberately want 24 GB in asymmetric mode; 2×8 GB is the better value for dual-channel.

---

## 3. What is genuinely well optimized (keep / copy)

### 3.1 Privacy, telemetry, ads

These are clearly deliberate and are the strongest part of the setup.

| Setting | Detected value |
|---|---|
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowTelemetry` | `0` |
| `HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo\Enabled` | `0` |
| `HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy\TailoredExperiencesWithDiagnosticDataEnabled` | `0` |
| `HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy\HasAccepted` | `0` |
| `HKCU:\Software\Microsoft\Input\TIPC\Enabled` | `0` |
| `HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location\Value` | `Deny` |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\System` | `EnableActivityFeed=0`, `PublishUserActivities=0`, `UploadUserActivities=0` |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableWindowsConsumerFeatures` | `1` |
| `HKCU:\...\ContentDeliveryManager\ContentDeliveryAllowed` | `0` |
| `HKCU:\...\ContentDeliveryManager\OemPreInstalledAppsEnabled` | `0` |
| `HKCU:\...\ContentDeliveryManager\PreInstalledAppsEnabled` | `0` |
| `HKCU:\...\ContentDeliveryManager\SilentInstalledAppsEnabled` | `0` |
| `HKCU:\...\ContentDeliveryManager\SubscribedContent-310093Enabled` | `0` |
| `HKCU:\...\ContentDeliveryManager\SubscribedContent-338387Enabled` | `0` |
| `HKCU:\...\ContentDeliveryManager\SubscribedContent-338389Enabled` | `0` |
| `HKCU:\...\ContentDeliveryManager\SubscribedContent-338393Enabled` | `0` |
| `HKCU:\...\ContentDeliveryManager\SubscribedContent-353694Enabled` | `0` |
| `HKCU:\...\ContentDeliveryManager\SubscribedContent-353696Enabled` | `0` |
| `HKCU:\...\ContentDeliveryManager\RotatingLockScreenEnabled` | `0` |
| `HKCU:\...\ContentDeliveryManager\RotatingLockScreenOverlayEnabled` | `0` |
| `HKCU:\...\ContentDeliveryManager\FeatureManagementEnabled` | `0` |
| `HKCU:\...\UserProfileEngagement\ScoobeSystemSettingEnabled` | `0` |
| `HKCU:\...\Explorer\Advanced\Start_TrackProgs` | `0` |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search` | `AllowCortana=0`, `DisableWebSearch=1`, `ConnectedSearchUseWeb=0`, `AllowSearchToUseLocation=0` |
| `HKCU:\...\Search` | `BingSearchEnabled=0`, `CortanaConsent=0` |
| `HKCU:\...\SearchSettings\IsDynamicSearchBoxEnabled` | `0` |
| `HKLM:\SOFTWARE\Policies\Microsoft\Dsh\AllowNewsAndInterests` | `0` |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot\TurnOffWindowsCopilot` | `1` |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI\DisableAIDataAnalysis` | `1` |
| Taskbar | `TaskbarMn=0`, `ShowTaskViewButton=0`, `ShowCopilotButton=0` |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization\DODownloadMode` | `0` (HTTP only, no peer-to-peer) |

**Minor leftovers to finish (not performance-critical):**
- `SoftLandingEnabled=1` and `SystemPaneSuggestionsEnabled=1` are still on.
- `SubscribedContent-338388Enabled` and `SubscribedContent-353698Enabled` are not set (defaults may still show suggestions).
- `PreInstalledAppsEverEnabled=1` is historical.
- `ShowSyncProviderNotifications`, `Start_IrisRecommendations`, `Start_TrackDocs`, `TaskbarDa` are not set.
- `AllowTelemetry=0` on **Pro** is below the supported minimum (Pro normally uses Required/1). Windows may ignore it or update behavior may be odd. `MaxTelemetryAllowed=3` also conflicts with `AllowTelemetry=0`. On the other laptop, use `AllowTelemetry=1` (Required) if you want updates to behave predictably, or keep `0` and accept that it is a best-effort privacy tweak.

### 3.2 Store app debloat

**Removed / missing for the current user:**
`Microsoft.XboxApp`, `Microsoft.XboxGamingOverlay`, `Microsoft.XboxGameOverlay`, `Microsoft.XboxSpeechToTextOverlay`, `Microsoft.BingNews`, `Microsoft.BingWeather`, `Microsoft.BingSearch`, `Microsoft.Copilot`, `Microsoft.WindowsCopilot`, `MicrosoftTeams` (classic), `Microsoft.ZuneMusic`, `Microsoft.ZuneVideo`, `Microsoft.MicrosoftSolitaireCollection`, `Clipchamp.Clipchamp`, `Microsoft.Getstarted`, `Microsoft.WindowsFeedbackHub`, `Microsoft.SkypeApp`, `Microsoft.YourPhone`, `Microsoft.People`, `Microsoft.WindowsMaps`, `Microsoft.Microsoft3DViewer`, `Microsoft.MixedReality.Portal`, `Microsoft.PowerAutomateDesktop`, `Microsoft.Todos`, `Microsoft.LinkedIn`, `SpotifyAB.SpotifyMusic`, `Microsoft.WindowsWidgets`, `MicrosoftWindows.Client.WebExperience`, `Microsoft.Windows.Ai.Copilot.Provider`, `MicrosoftWindows.Client.AIX`.

**Kept (correctly):**
`Microsoft.WindowsStore`, `Microsoft.DesktopAppInstaller`, `Microsoft.WindowsTerminal`, `Microsoft.Windows.SubsystemForLinux`, `Microsoft.Windows.Photos`, `Microsoft.WindowsCamera`, `Microsoft.WindowsCalculator`, `Microsoft.WindowsAlarms`, `Microsoft.WindowsNotepad`, `Microsoft.Paint`, `Microsoft.ScreenSketch`, `Microsoft.WindowsSoundRecorder`, `Microsoft.MicrosoftStickyNotes`, `microsoft.windowscommunicationsapps` (Mail/Calendar), `Microsoft.MicrosoftOfficeHub`, `Microsoft.OneDriveSync`, `MSTeams` (new Teams), `Microsoft.GamingApp` (Xbox app), `Microsoft.XboxIdentityProvider`, `Microsoft.GetHelp`, and the WebView2/VCLibs/UI.Xaml frameworks.

**Important:** `Microsoft.XboxIdentityProvider` is kept. Do **not** remove it if the other laptop uses Game Pass or Microsoft Store games. Removing `Microsoft.WindowsStore`, WebView2, VCLibs, UI.Xaml, or WindowsAppRuntime breaks apps.

**Provisioned packages still present:** `Microsoft.GamingApp`, `Microsoft.GetHelp`, `Microsoft.MicrosoftOfficeHub`, `Microsoft.OneDriveSync`, `Microsoft.MicrosoftStickyNotes`, `Microsoft.WindowsCamera`, etc. A new Windows user profile on this machine would get some of these back. For a permanent debloat, remove the matching **provisioned** packages too (the script has an optional switch).

### 3.3 Gaming / responsiveness tweaks

| Setting | Detected | Assessment |
|---|---|---|
| `HKCU:\System\GameConfigStore\GameDVR_Enabled` | `0` | Good — GameDVR off |
| `HKCU:\...\GameDVR\AppCaptureEnabled` | `0` | Good |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR\AllowGameDVR` | `0` | Good |
| `HKCU:\Software\Microsoft\GameBar\AutoGameModeEnabled` | `1` | Good (Game Mode on) |
| `HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\HwSchMode` | `2` | HAGS on; good for RTX 3050 Ti, keep |
| `HKCU:\...\DirectX\UserGpuPreferences\DirectXUserGlobalSettings` | `VRROptimizeEnable=1;SwapEffectUpgradeEnable=1;` | Windowed-game optimizations on; good |
| `HKCU:\Control Panel\Desktop\MenuShowDelay` | `50` | Faster menus (default 400); safe |
| `HKCU:\...\Explorer\Serialize\StartupDelayInMSec` | `1` | Removes startup delay; minor but safe |
| `HKCU:\Software\Microsoft\Windows\DWM\EnableAeroPeek` | `0` | Peek off; minor win |
| `HKCU:\...\VisualEffects\VisualFXSetting` | `2` | “Best performance” selected, **but** see inconsistency below |
| `HKLM:\...\Multimedia\SystemProfile\SystemResponsiveness` | `10` | Gaming tweak (default 20); harmless |
| `HKLM:\...\Multimedia\SystemProfile\NetworkThrottlingIndex` | `4294967295` (0xFFFFFFFF) | Network throttling disabled; harmless |
| `...\SystemProfile\Tasks\Games` | `GPU Priority=8`, `Priority=6`, `Scheduling Category=High`, `SFIO Priority=High` | GPU Priority/Priority/Scheduling Category are stock; only `SFIO Priority=High` differs. Mostly placebo, harmless |

**Visual-effects inconsistency:** `VisualFXSetting=2` (“Adjust for best performance”) is set, but `TaskbarAnimations=1`, `ListviewAlphaSelect=1`, `ListviewShadow=1`, `MinAnimate=1`, and `EnableTransparency=1` are still on. Either Windows reset them or they were re-enabled manually. For maximum speed, set those five to `0`; for a polished look, leave them. Do not claim “best performance” while animations/transparency are on.

**Fullscreen-optimization tweak:** `GameDVR_FSEBehaviorMode=2`, `GameDVR_HonorUserFSEBehaviorMode=0`, `GameDVR_DXGIHonorFSEWindowsCompatible=0`, `GameDVR_EFSEFeatureFlags=0` — this globally disables fullscreen optimizations. It can reduce latency in some games but can break alt-tab/overlays in others. **Optional, not a universal optimization.** I would not copy it by default.

### 3.4 Filesystem / storage

| Setting | Detected | Assessment |
|---|---|---|
| `HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem\NtfsDisableLastAccessUpdate` | `2147483649` (0x80000001) | Last-access updates disabled; good for SSD |
| `NtfsDisable8dot3NameCreation` | `1` | 8.3 names disabled; good |
| `NtfsMemoryUsage` | `1` | Normal; fine |
| TRIM | `DisableDeleteNotify=0` | Enabled; good |
| Storage Sense | `01=1` (on), `04=1` (temp cleanup), `2048=0`, `08` missing | Temp cleanup on; Recycle Bin/Downloads cleanup off |
| Pagefile | Fixed `8192–12288` MB, `AutomaticManagedPagefile=False` | Custom; see risk section |
| Fast Startup | `HiberbootEnabled=0` | Off; good for dual-boot/SSD reliability, slightly slower cold boot |

**Storage Sense values:** `01=1` enables Storage Sense; `04=1` deletes temporary files; `08=1` would add Recycle Bin cleanup; `32=1` would add Downloads cleanup. Current setup only does temp files. On a 90 GB-free C: drive that is fine; enabling Recycle Bin cleanup is a reasonable optional addition. Do **not** enable Downloads cleanup if you keep installers there.

### 3.5 Defender

| Setting | Detected | Assessment |
|---|---|---|
| Real-time protection | On | Good |
| Tamper protection | On | Good |
| `ScanAvgCPULoadFactor` | `15` | Lower than default 50; good for reducing scan impact |
| Exclusions | dev folders/processes + `%TEMP%` + `C:\Windows\System32\SppExtComObjHook.dll` | **Mixed** — see risk section |

Dev-folder/process exclusions (Git, node, bun, cargo, Gradle, VS Code, npm cache, WSL, etc.) are a common developer performance tweak. They reduce scan overhead but also reduce protection in those folders. That is a conscious trade-off; keep only what you actually need.

### 3.6 Power plan

Active scheme: **“Work Stable”** (`ed4fbac6-81fb-4afb-9d0b-dfd295762966`), a custom plan — not a stock Balanced/High Performance/Ultimate plan.

| Setting | AC | DC (battery) |
|---|---:|---:|
| Minimum processor state | 5% | 5% |
| Maximum processor state | 100% | 60% |
| Processor performance boost mode | 2 (Aggressive) | 2 (Aggressive) |
| System cooling policy | Active | Active |
| Turn off hard disk after | 1200 s | 1200 s |
| PCIe Link State Power Management | Off | Off |
| USB selective suspend | Off | On |
| Sleep after | Never | 900 s |
| Hibernate after | Never | Never |
| Allow wake timers | Off | Off |
| Active power overlay | **Best Performance** (`961cc777…`) | **Best Performance** (`961cc777…`) |

**Assessment:** AC side is a sensible “performance while plugged in” profile. The DC side is contradictory: **Best Performance overlay + 60% max CPU** fight each other, and PCIe ASPM off on battery costs power. For battery life, set the DC overlay to Balanced and enable PCIe ASPM on DC. For a laptop, “Best Performance” on battery is usually the wrong default.

**Fast Startup:** `HiberbootEnabled=0`, and `powercfg /a` says Fast Startup is disabled by policy. Hibernation itself is available. This is fine; Fast Startup is not a real performance win on NVMe and can cause driver/dual-boot issues.

### 3.7 Network

**No harmful “gamer” TCP tweaks were found** — that is a positive. `netsh int tcp show global` shows:
- RSS enabled, RSC enabled, Receive Window Auto-Tuning **normal**
- ECN disabled, RFC 1323 timestamps allowed
- Fast Open enabled, HyStart enabled, Proportional Rate Reduction enabled
- No `TcpAckFrequency`/`TCPNoDelay`/`TcpDelAckTicks` overrides
- No `DefaultReceiveWindow`/`DefaultSendWindow`/AFD buffer tweaks
- `Tcp1323Opts`, `MaxUserPort`, `TcpTimedWaitDelay`, `DefaultTTL`, `SackOpts` all **not set** (defaults)

DNS on Wi-Fi: `1.1.1.1` plus the Tailscale DNS server. Tailscale tunnel is up. Wake on Magic Packet and Wake on Pattern Match are **Enabled** on Wi-Fi — harmless on AC, but can wake the laptop in sleep and drain battery. Disable if you don’t need WoWLAN.

---

## 4. What I would NOT copy to the other laptop

These are either risky, functionality-breaking, security-weakening, or mostly placebo.

### 4.1 Memory compression / page combining off

`Get-MMAgent`:
```
MemoryCompression : False
PageCombining     : False
ApplicationPreLaunch : False
```

On 8 GB, this is the **opposite** of optimal. Memory compression compresses cold pages in RAM instead of paging them to disk; page combining deduplicates identical pages. Both reduce pagefile I/O and improve responsiveness on low-RAM systems. Disabling them is a “gaming latency” tweak that only makes sense on high-RAM machines, and even then the gain is dubious.

**Fix on this machine (suggested, not applied):**
```powershell
Enable-MMAgent -MemoryCompression
Enable-MMAgent -PageCombining
# reboot
```

Do **not** copy `MemoryCompression=False` / `PageCombining=False` to the other laptop.

### 4.2 Defender exclusions for `Temp` and `SppExtComObjHook.dll`

- `%TEMP%` is one of the most common malware execution paths. Excluding it from Defender is a real security hole for a negligible performance gain.
- `C:\Windows\System32\SppExtComObjHook.dll` is part of Windows activation/KMS hooking. Excluding it is not a performance tweak; it is an activation-related change. Do not replicate it.

Keep dev-folder exclusions only if you understand the trade-off; never exclude all of `Temp`.

### 4.3 Disabled NVIDIA services

`NvContainerLocalSystem`, `NVDisplay.ContainerLocalSystem`, `nvagent`, and `FvSvc` are disabled. The NVIDIA driver still renders games, but:
- The **NVIDIA Control Panel** app is installed (`NVIDIACorp.NVIDIAControlPanel 8.1.969.0`). It may fail or lose display/3D settings without `NVDisplay.ContainerLocalSystem`.
- NVIDIA App features (driver update, ShadowPlay, filters, display settings) depend on these services.
- The RAM saving is small (tens of MB), not worth losing GPU control on a gaming laptop.

`FvSvc` (FrameView SDK) is safe to leave disabled — it is benchmark telemetry, not needed.

**Suggestion:** re-enable `NVDisplay.ContainerLocalSystem` and `NvContainerLocalSystem` to `Automatic` if you use NVIDIA Control Panel/App. Keep `FvSvc` disabled.

### 4.4 Disabled WSearch and SysMain

- **WSearch (Windows Search):** Start-menu app search still works via `SearchHost`, but file search, Outlook search, and some Start results stop working. On an NVMe SSD the performance gain is small. If you use search, re-enable it.
- **SysMain (Superfetch):** on an SSD it is optional, but on 8 GB RAM it can help app launch and memory management. Disabling it is not a universal win. Test both ways; do not blindly copy.

### 4.5 Disabled security/maintenance services

- **`SgrmBroker` (System Guard Runtime Monitor Broker):** a security mitigation. Disabling it is not a meaningful performance win. Leave it enabled on the other laptop.
- **`uhssvc` (Microsoft Update Health Service):** can affect update remediation. Leave it alone.
- **`WerSvc`, `PcaSvc`, `RemoteRegistry`, `MapsBroker`, `lfsvc`:** safe-ish, but only minor gains. `WerSvc`/`PcaSvc` can hide useful diagnostics/compatibility fixes.

### 4.6 Disabled scheduled tasks that should stay enabled

74 tasks are disabled. Some are default-disabled, but these are aggressive and can cause real problems:

| Task | Why it matters |
|---|---|
| `\Microsoft\Windows\.NET Framework\.NET Framework NGEN v4.0.30319 64 Critical` | Native-image generation for .NET; disabling can slow .NET app startup |
| `\Microsoft\Windows\.NET Framework\.NET Framework NGEN v4.0.30319 Critical` | Same |
| `\Microsoft\Windows\RecoveryEnvironment\VerifyWinRE` | Verifies recovery environment; keep for recoverability |
| `\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTaskLogon` | Windows/Office activation service restart |
| `\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTaskNetwork` | Same |
| `\Microsoft\Windows\Subscription\LicenseAcquisition` | Subscription/licensing |
| `\Microsoft\Windows\Clip\License Validation` | Office activation/licensing |
| `\Microsoft\Windows\Clip\LicenseImdsIntegration` | Office activation/licensing |
| `\Microsoft\Windows\UpdateOrchestrator\*` (several) | Several orchestration tasks disabled (Report policies, Schedule Maintenance Work, Schedule Wake To Work, Schedule Work, Start Oobe Expedite Work, StartOobeAppsScan*, UUS Failover). `Schedule Scan` and `WindowsUpdate\Scheduled Start` are still **Ready**, so updates can still work, but this can delay/break orchestration. |
| `\Microsoft\Windows\InstallService\WakeUpAndContinueUpdates` | Update wake/continue |
| `\Microsoft\Windows\InstallService\WakeUpAndScanForUpdates` | Update wake/scan |

Telemetry/CEIP tasks (`Microsoft Compatibility Appraiser`, `Consolidator`, `UsbCeip`, `ProgramDataUpdater`, `DiskDiagnosticDataCollector`, `WinSAT`, `Autochk Proxy`, `Diagnosis Scheduled`, `Power Efficiency Diagnostics`, `MapsUpdateTask`, `MemoryDiagnostic`, `QueueReporting`) are safe to keep disabled if you want privacy. Some of the 74 are default-disabled anyway; the point is **do not copy the entire disabled-task list**.

### 4.7 Disabled HP services

`HPAppHelperCap`, `HPDiagsCap`, `HPNetworkCap`, `HPOmenCap`, `HPSysInfoCap`, `HpTouchpointAnalyticsService` are disabled. No HP apps are installed, so this is fine here. On another HP laptop, these can affect HP hotkeys, OMEN Gaming Hub, diagnostics, or network helpers. Disable only if the other laptop also has no HP software you use.

### 4.8 Fixed 8–12 GB pagefile

Current: `AutomaticManagedPagefile=False`, `C:\pagefile.sys 8192 12288`, commit limit 15.3 GB. On 8 GB RAM this is workable, but it is hardware-specific. Do **not** copy this number to a laptop with 16/32 GB RAM. Use system-managed, or size it to the other laptop’s RAM and workload. If you keep this machine on 8 GB, consider a larger max (e.g. 16 GB) for heavy Chrome/Teams sessions.

### 4.9 `AllowTelemetry=0` on Windows Pro

`AllowTelemetry=0` is “Security” level, which Microsoft supports on Enterprise/Education/IoT, not officially on Pro. On Pro, Windows may treat it as `1` or behave inconsistently. `MaxTelemetryAllowed=3` in the other key is a direct conflict. For a Pro laptop, `AllowTelemetry=1` (Required) is the sane privacy/update balance. This is a minor point, not a performance issue.

### 4.10 Visual-effects half-tweak

`VisualFXSetting=2` with animations/transparency still on is inconsistent. Do not copy the mix; decide:
- Max speed: `TaskbarAnimations=0`, `ListviewAlphaSelect=0`, `ListviewShadow=0`, `MinAnimate=0`, `EnableTransparency=0`.
- Polished look: leave them on and don’t claim “best performance.”

### 4.11 PowerShell 2.0 enabled

Windows feature `MicrosoftWindowsPowerShellV2` / `MicrosoftWindowsPowerShellV2Root` is enabled. This is an old, unnecessary attack surface. Disable it on both laptops:
```powershell
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2
```
(Keep PowerShell 7 / Windows PowerShell 5.1; this only removes the v2 engine.)

### 4.12 Windows 11 22H2

Build 22621.4317 is the final 22H2-era build; 22H2 Pro support ended **2024-10-08**. This machine has missed roughly two years of security fixes. Do not replicate “stay on 22H2” to the other laptop. Upgrade to a supported release (**26H2** is current; 25H2 remains supported until Oct 2027; 24H2 ended Oct 13, 2026) — after adding RAM if the other laptop is also 8 GB. From 22H2 the 25H2/26H2 enablement package cannot be used; do an in-place ISO upgrade or use the Installation Assistant.

---

## 5. Values that are just Windows defaults (no action)

These often get mistaken for “optimizations”:

| Setting | Value | Note |
|---|---|---|
| `Win32PrioritySeparation` | `2` | Windows client default; not the “26” gaming tweak |
| `EnablePrefetcher` | `3` | Default (app launch + boot prefetch) |
| `ClearPageFileAtShutdown` | `0` | Default |
| `LargeSystemCache` | `0` | Default for client |
| `DisablePagingExecutive` | `0` | Default |
| TCP autotuning / RSS / RSC | normal / on / on | Defaults; good |
| ECN | disabled | Default |
| RFC 1323 timestamps | allowed | Default |
| UAC | enabled, prompt `5` | Default |
| RDP | `fDenyTSConnections=1` | Default off |
| Spooler | Automatic / Running | Default; printing works |
| Bluetooth | Manual | Default |
| Audio services | Automatic / Running | Default |
| Defender | On, tamper on | Default/good |
| HAGS | `2` | Default on supported Win11 GPUs; keep |
| Game Mode | `1` | Default on; keep |
| `NtfsDisableLastAccessUpdate` / 8dot3 | disabled / disabled | Common default/optimizer values; safe either way |

**`Win32PrioritySeparation=2` is not the “26” tweak.** If you see guides telling you to set 26 for gaming, that is a different value; this machine is at the Windows default. No need to change it.

---

## 6. Replication plan for the other laptop

Do this in order. **Do not clone the whole machine blindly** — the other laptop may have different RAM, GPU, storage, or Windows edition.

### Step 0 — Inspect the other laptop first

```powershell
winver
Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber
Get-CimInstance Win32_PhysicalMemory | Select-Object BankLabel, Capacity, Speed, Manufacturer, PartNumber
Get-CimInstance Win32_PhysicalMemoryArray | Select-Object MemoryDevices, MaxCapacityEx
Get-PhysicalDisk | Select-Object FriendlyName, MediaType, Size, BusType
Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion
Get-Volume | Where-Object DriveLetter
```

Then:
- **If it is on 22H2 or older:** update to a supported release first.
- **If it has 8 GB single-channel:** add a matching 8 GB DDR4-3200 CL22 stick (ideally 1Rx8) before chasing registry tweaks.
- **If it has an NVIDIA GPU and you use NVIDIA Control Panel/App:** do not disable NVIDIA services.
- **If it prints:** keep Spooler.
- **If it uses Xbox/Game Pass:** keep Xbox Identity Provider and GamingApp.
- **If it uses Store apps:** keep Store, DesktopAppInstaller, WebView2, VCLibs, UI.Xaml, WindowsAppRuntime.

Create a restore point:
```powershell
Checkpoint-Computer -Description "Before optimization tweaks" -RestorePointType MODIFY_SETTINGS
```
If System Restore is off, enable it for C: first.

### Step 1 — Privacy / ads / telemetry (safe, high value)

Apply the values in section 3.1, plus finish the leftovers:
```powershell
# CloudContent extras
$cc = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
New-Item $cc -Force | Out-Null
Set-ItemProperty $cc DisableConsumerAccountStateContent 1 -Type DWord
Set-ItemProperty $cc DisableSoftLanding 1 -Type DWord
Set-ItemProperty $cc DisableCloudOptimizedContent 1 -Type DWord
Set-ItemProperty $cc DisableThirdPartySuggestions 1 -Type DWord

# ContentDeliveryManager leftovers
$cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
Set-ItemProperty $cdm SoftLandingEnabled 0 -Type DWord
Set-ItemProperty $cdm SystemPaneSuggestionsEnabled 0 -Type DWord
Set-ItemProperty $cdm 'SubscribedContent-338388Enabled' 0 -Type DWord
Set-ItemProperty $cdm 'SubscribedContent-353698Enabled' 0 -Type DWord
Set-ItemProperty $cdm PreInstalledAppsEverEnabled 0 -Type DWord

# Explorer leftovers
$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-ItemProperty $adv ShowSyncProviderNotifications 0 -Type DWord
Set-ItemProperty $adv Start_IrisRecommendations 0 -Type DWord
Set-ItemProperty $adv Start_TrackDocs 0 -Type DWord
Set-ItemProperty $adv TaskbarDa 0 -Type DWord

# Feedback / diagnostic limits
$dc = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
Set-ItemProperty $dc DoNotShowFeedbackNotifications 1 -Type DWord
Set-ItemProperty $dc LimitDiagnosticLogCollection 1 -Type DWord
Set-ItemProperty $dc LimitDumpCollection 1 -Type DWord
Set-ItemProperty $dc AllowDeviceNameInTelemetry 0 -Type DWord
```

**Do not** set `AllowTelemetry=0` on a Pro laptop unless you accept the caveat; use `1` if unsure.

### Step 2 — Remove Store bloat (optional)

Remove only the explicit list in section 3.2. Keep the “kept” list. For permanent debloat, remove matching provisioned packages too:
```powershell
$bloat = @(
  'Microsoft.XboxApp','Microsoft.XboxGamingOverlay','Microsoft.XboxGameOverlay',
  'Microsoft.XboxSpeechToTextOverlay','Microsoft.BingNews','Microsoft.BingWeather',
  'Microsoft.BingSearch','Microsoft.Copilot','Microsoft.WindowsCopilot',
  'Microsoft.MicrosoftSolitaireCollection','Clipchamp.Clipchamp','Microsoft.Getstarted',
  'Microsoft.WindowsFeedbackHub','Microsoft.SkypeApp','Microsoft.YourPhone',
  'Microsoft.People','Microsoft.WindowsMaps','Microsoft.Microsoft3DViewer',
  'Microsoft.MixedReality.Portal','Microsoft.PowerAutomateDesktop','Microsoft.Todos',
  'Microsoft.LinkedIn','SpotifyAB.SpotifyMusic','Microsoft.ZuneMusic','Microsoft.ZuneVideo'
)
foreach ($n in $bloat) {
  Get-AppxPackage -Name $n | Remove-AppxPackage
  Get-AppxProvisionedPackage -Online |
    Where-Object DisplayName -eq $n |
    Remove-AppxProvisionedPackage -Online
}
```
Do **not** add Store, WebView2, VCLibs, UI.Xaml, WindowsAppRuntime, DesktopAppInstaller, Terminal, WSL, Photos, Camera, Calculator, Notepad, Paint, Snipping Tool, or the Xbox Identity Provider to this list.

### Step 3 — Gaming / responsiveness

```powershell
# GameDVR off
$gc = 'HKCU:\System\GameConfigStore'
Set-ItemProperty $gc GameDVR_Enabled 0 -Type DWord
$gd = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR'
Set-ItemProperty $gd AppCaptureEnabled 0 -Type DWord
$gp = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'
New-Item $gp -Force | Out-Null
Set-ItemProperty $gp AllowGameDVR 0 -Type DWord

# Game Mode on
Set-ItemProperty 'HKCU:\Software\Microsoft\GameBar' AutoGameModeEnabled 1 -Type DWord

# HAGS on (supported NVIDIA/AMD GPU; reboot required)
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' HwSchMode 2 -Type DWord

# Faster menus / startup / no Aero Peek
Set-ItemProperty 'HKCU:\Control Panel\Desktop' MenuShowDelay '50' -Type String
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize' StartupDelayInMSec 1 -Type DWord
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\DWM' EnableAeroPeek 0 -Type DWord
```

Optional (gaming placebo but harmless):
```powershell
$sp = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
Set-ItemProperty $sp SystemResponsiveness 10 -Type DWord
Set-ItemProperty $sp NetworkThrottlingIndex 0xFFFFFFFF -Type DWord
$games = "$sp\Tasks\Games"
Set-ItemProperty $games 'GPU Priority' 8 -Type DWord
Set-ItemProperty $games 'Priority' 6 -Type DWord
Set-ItemProperty $games 'Scheduling Category' 'High' -Type String
Set-ItemProperty $games 'SFIO Priority' 'High' -Type String
```

**Skip the global FSE tweak** (`GameDVR_FSEBehaviorMode=2`) unless a specific game benefits and you are willing to test alt-tab/overlays.

### Step 4 — Visual effects (choose one, don’t mix)

Max speed:
```powershell
$fx = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
Set-ItemProperty $fx VisualFXSetting 2 -Type DWord
$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-ItemProperty $adv TaskbarAnimations 0 -Type DWord
Set-ItemProperty $adv ListviewAlphaSelect 0 -Type DWord
Set-ItemProperty $adv ListviewShadow 0 -Type DWord
Set-ItemProperty 'HKCU:\Control Panel\Desktop\WindowMetrics' MinAnimate '0' -Type String
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' EnableTransparency 0 -Type DWord
```
Polished look: leave animations/transparency on and don’t set `VisualFXSetting=2`.

### Step 5 — Power (optional, hardware-specific)

Do **not** import this machine’s “Work Stable” plan GUID. On the other laptop, tune its active plan:
```powershell
# AC: performance; DC: sane battery limits
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 5
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 5
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 60
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 2
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 2
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR SYSCOOLPOL 1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR SYSCOOLPOL 1
powercfg /setacvalueindex SCHEME_CURRENT SUB_PCIEXPRESS ASPM 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PCIEXPRESS ASPM 1
powercfg /setacvalueindex SCHEME_CURRENT SUB_USB USBSELECTIVESUSPEND 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_USB USBSELECTIVESUSPEND 1
powercfg /setacvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 1200
powercfg /setdcvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 1200
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 900
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE 7200
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 0
powercfg /setactive SCHEME_CURRENT
```
This is a **suggestion**, not a universal best. On a desktop, DC values don’t matter. On a laptop with a different CPU, test heat/battery.

For this machine specifically: set the **DC power overlay to Balanced** (not Best Performance), and enable PCIe ASPM on DC. Hibernate after 120 min on DC is also more sensible than “never” if you leave it unplugged.

### Step 6 — Services / tasks (safe subset only)

Safe telemetry services:
```powershell
Set-Service DiagTrack -StartupType Disabled
Set-Service dmwappushservice -StartupType Disabled
```
Optionally:
```powershell
Set-Service RemoteRegistry -StartupType Disabled
Set-Service MapsBroker -StartupType Disabled
Set-Service lfsvc -StartupType Disabled
```
**Do not** disable: `WSearch`, `SysMain`, `SgrmBroker`, `uhssvc`, NVIDIA services, HP services, Spooler, audio, Bluetooth, Wi-Fi, Defender, Windows Update, or `EventLog`.

Telemetry tasks (safe subset):
```powershell
$tasks = @(
  '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
  '\Microsoft\Windows\Application Experience\ProgramDataUpdater',
  '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator',
  '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip',
  '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector',
  '\Microsoft\Windows\Maintenance\WinSAT',
  '\Microsoft\Windows\Autochk\Proxy',
  '\Microsoft\Windows\Diagnosis\Scheduled',
  '\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem',
  '\Microsoft\Windows\Maps\MapsUpdateTask',
  '\Microsoft\Windows\MemoryDiagnostic\ProcessMemoryDiagnosticEvents',
  '\Microsoft\Windows\MemoryDiagnostic\RunFullMemoryDiagnostic',
  '\Microsoft\Windows\Windows Error Reporting\QueueReporting',
  '\Microsoft\Windows\Feedback\Siuf\DmClient',
  '\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload',
  '\Microsoft\Windows\PI\Sqm-Tasks'
)
foreach ($t in $tasks) {
  $leaf = Split-Path $t -Leaf
  $path = Split-Path $t -Parent
  Disable-ScheduledTask -TaskPath $path -TaskName $leaf -ErrorAction SilentlyContinue | Out-Null
}
```
**Do not** disable .NET NGEN, Windows Update, activation/licensing, WinRE verification, or the entire 74-task list.

### Step 7 — Defender

Only copy the CPU-friendly scan setting:
```powershell
Set-MpPreference -ScanAvgCPULoadFactor 15
```
Do **not** copy the exclusions wholesale. If you need dev exclusions, add them explicitly:
```powershell
Add-MpPreference -ExclusionPath 'C:\Dev'
Add-MpPreference -ExclusionProcess 'node.exe'
```
Never exclude `%TEMP%`, `C:\Windows`, or `SppExtComObjHook.dll`.

### Step 8 — Storage / filesystem

Safe:
```powershell
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' NtfsDisableLastAccessUpdate 0x80000001 -Type DWord
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' NtfsDisable8dot3NameCreation 1 -Type DWord
```
Optional Storage Sense (temp + Recycle Bin):
```powershell
$ss = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
Set-ItemProperty $ss 01 1 -Type DWord
Set-ItemProperty $ss 04 1 -Type DWord
Set-ItemProperty $ss 08 1 -Type DWord
Set-ItemProperty $ss 32 0 -Type DWord   # don't auto-delete Downloads
Set-ItemProperty $ss 2048 0 -Type DWord
```
Keep TRIM enabled. Do not disable it.

### Step 9 — Reboot and verify

- Reboot.
- Check `Get-MMAgent` — MemoryCompression/PageCombining should be **True**.
- Check `powercfg /getactivescheme`.
- Check `Get-Service` for anything you disabled.
- Run Windows Update.
- Test printing, Bluetooth, audio, NVIDIA Control Panel, Store apps, Xbox/Game Pass (if used), WSL (if used).

---

## 7. Further optimization for THIS laptop (suggestions only)

### P0 — biggest wins

1. **Add a second 8 GB DDR4-3200 CL22 SODIMM (ideally 1Rx8).** 16 GB dual-channel. This will do more than every registry tweak combined, especially with Chrome/Teams/OpenCode. The laptop has 2 slots and supports 32 GB.
2. **Enable Memory Compression + Page Combining.**
   ```powershell
   Enable-MMAgent -MemoryCompression
   Enable-MMAgent -PageCombining
   ```
   Reboot. Verify with `Get-MMAgent`.
3. **Upgrade Windows 22H2 to 26H2.** 22H2 Pro is EOL since 2024-10-08; 24H2 also ended 2026-10-13, and 25H2 is supported until Oct 2027 but is no longer current. From 22H2 the enablement package cannot be used — use Windows Update (the 7-day pause expired 2026-11-20), or an in-place ISO upgrade / Windows 11 Installation Assistant targeting 26H2. Do the RAM upgrade first if you can; 26H2 on 8 GB is heavier.

### P1 — immediate responsiveness

4. **Close Teams when not in use.** At audit time Teams + WebView2 was ~1.3 GB. The main WebView2 process alone was 879 MB. Teams is the single largest background consumer.
5. **Chrome:** enable Memory Saver, trim extensions, close unused tabs. Chrome was ~1.2 GB across processes.
6. **Startup:** current user Run has only `AMDNoiseSuppression` and `Steam`; OneDrive startup is already gone. Tailscale and Realtek audio start from Common Startup/HKLM. Disable `Steam` and `AMDNoiseSuppression` if you don’t need them at login; keep Realtek audio and SecurityHealth. Tailscale only if you need it always.
7. **Disable Teams auto-start** in Teams settings if it is enabled. It was launched by Explorer at audit time, not by a Run key, so check the app setting.

### P2 — fix risky tweaks

8. **Remove the `Temp` and `SppExtComObjHook.dll` Defender exclusions.** Keep only the dev paths/processes you actually need.
9. **Re-enable NVIDIA services** if you use NVIDIA Control Panel/App:
   ```powershell
   Set-Service NVDisplay.ContainerLocalSystem -StartupType Automatic
   Set-Service NvContainerLocalSystem -StartupType Automatic
   Start-Service NVDisplay.ContainerLocalSystem
   ```
   Keep `FvSvc` disabled (FrameView telemetry).
10. **Re-enable `SgrmBroker`** (System Guard) — security, negligible performance cost:
    ```powershell
    Set-Service SgrmBroker -StartupType Manual
    ```
11. **Re-enable .NET NGEN critical tasks** if .NET apps start slowly:
    ```powershell
    Enable-ScheduledTask -TaskPath '\Microsoft\Windows\.NET Framework\' -TaskName '.NET Framework NGEN v4.0.30319 64 Critical'
    Enable-ScheduledTask -TaskPath '\Microsoft\Windows\.NET Framework\' -TaskName '.NET Framework NGEN v4.0.30319 Critical'
    ```
12. **Reconsider WSearch/SysMain.** If you use Start/Outlook file search, enable WSearch. If app launches feel slow on 8 GB, try SysMain back on. These are optional, not mandatory.

### P3 — finish the debloat / polish

13. Finish the ad/suggestion leftovers listed in 3.1.
14. Make visual effects consistent (section 4.10).
15. On battery: set power overlay to **Balanced**, enable PCIe ASPM on DC, set hibernate after 120 min on DC. Current “Best Performance + 60% max CPU” is contradictory.
16. Disable Wi-Fi **Wake on Magic Packet/Pattern** if you don’t need WoWLAN; it can wake the laptop in sleep.
17. Pagefile: on 8 GB, consider a larger max (e.g. 16 GB) or system-managed; current commit limit is 15.3 GB. After 16 GB RAM, system-managed is fine.
18. Disable **PowerShell 2.0** (security). Optionally disable Work Folders, SMB Direct, MSRDC if unused; keep printing, .NET 3.5, WSL as needed.
19. Show file extensions (`HideFileExt=0`) — not a performance tweak, but safer.
20. If you never hibernate, `powercfg /hibernate off` frees ~6 GB and reduces disk writes; but on a laptop hibernate is useful. Fast Startup is already off.
21. `D: 27.7 GB free` — if games/large files live there, keep some headroom. Move large installers/caches off C: if it drops below ~15% free.

### P4 — optional gaming experiments

22. Test the global FSE tweak (`GameDVR_FSEBehaviorMode=2`) per game; revert if alt-tab/overlays break.
23. Test HAGS on/off per game; on RTX 3050 Ti it is usually better on.
24. The `SystemResponsiveness=10` / `NetworkThrottlingIndex=0xFFFFFFFF` / Games-task priority tweaks are harmless but mostly placebo. Keep them if you like; don’t expect measurable gains.

---

## 8. Bottom line

- **Debloat/privacy:** genuinely good. You removed the right Store apps, killed ads/telemetry/Copilot/Widgets/Bing search, and disabled GameDVR. This part is worth copying (minus the risky exclusions).
- **Performance:** not fully optimal. The 8 GB single-channel stick is the bottleneck, and turning off memory compression/page combining makes it worse. Fix those before adding more registry tweaks.
- **Security/maintenance:** the weak spot. 22H2 is EOL, Defender has risky exclusions, PowerShell 2.0 is enabled, and some update/activation/.NET tasks are disabled. Fix these on both machines.
- **Do not clone everything.** Copy the privacy/debloat list, GameDVR/HAGS/menu tweaks, NTFS settings, and Defender scan-CPU setting. Skip the NVIDIA/HP service disables, WSearch/SysMain disables, Temp/Spp exclusions, fixed pagefile, 74-task list, and the inconsistent visual-effects mix.

**Files:**
- This report: `windows-optimization-report.md`
- Safe replication script: `replicate-safe-tweaks.ps1`

The script is **not** run automatically. Use `-DryRun` first on the other laptop.

