# w11debloated

Windows 11 debloat / optimization notes and a safe, reviewable PowerShell script.

This repo is based on a **read-only audit** of a Windows 11 Pro 22H2 laptop (Ryzen 5 5600H, 8 GB RAM, RTX 3050 Ti). It documents what was changed, what is worth copying to another machine, what is risky, and what to fix.

> **Read the report first.** The script is a safe subset, not a full clone. Run `-DryRun` before applying anything. No warranty; review the code and create a restore point.

## Files

- [`windows-optimization-report.md`](windows-optimization-report.md) — full audit, exact values, risks, and a replication checklist.
- [`replicate-safe-tweaks.ps1`](replicate-safe-tweaks.ps1) — applies the low-risk subset, with optional switches.

## TL;DR from the audit

- **Debloated: yes. Fully optimal: no.**
- Biggest hardware issue: **8 GB single-channel RAM** plus Memory Compression/Page Combining **off**. Add a matching 8 GB DDR4-3200 stick (2 slots, 32 GB max) and enable both.
- Biggest maintenance issue: **Windows 11 22H2 is EOL** (Pro ended 2024-10-08). Upgrade to 26H2 (or 25H2 while supported) via an in-place ISO/Installation Assistant.
- Safe to copy: privacy/ads/telemetry off, GameDVR off, Game Mode/HAGS on, menu/startup delay tweaks, NTFS last-access/8.3 off, Defender scan CPU 15, Fast Startup off, Storage Sense temp cleanup.
- Do **not** copy: memory compression off, Defender `%TEMP%` / `SppExtComObjHook.dll` exclusions, disabled NVIDIA services, disabled WSearch/SysMain, disabled .NET NGEN/update/activation/WinRE tasks, fixed pagefile, PowerShell 2.0 enabled.

## Quick start

Run from an **elevated** PowerShell on the target laptop.

```powershell
# Preview only — no changes
powershell -ExecutionPolicy Bypass -File .\replicate-safe-tweaks.ps1 -DryRun

# Apply safe core
powershell -ExecutionPolicy Bypass -File .\replicate-safe-tweaks.ps1

# Optional extras
powershell -ExecutionPolicy Bypass -File .\replicate-safe-tweaks.ps1 `
  -RemoveBloatApps -ApplyVisualPerformance -ApplyPowerTweaks `
  -DisableFastStartup -DisableTelemetryServices -DisableTelemetryTasks `
  -EnableStorageSense -DisablePowerShell2
```

## What the script does

- Privacy / ads / telemetry / suggestions off.
- GameDVR off, Game Mode on, HAGS on.
- Faster menus, no startup delay, no Aero Peek.
- NTFS last-access / 8.3-name tweaks.
- Defender scan CPU limit (no exclusions).
- Enables Memory Compression + Page Combining (the audited machine had them off).
- Optional: Store bloat removal, visual performance, power plan, Fast Startup off, telemetry services/tasks, Storage Sense, PowerShell 2.0 removal.

## What it deliberately does NOT do

- Disable WSearch, SysMain, NVIDIA, HP, SgrmBroker, Windows Update, or printing.
- Add Defender exclusions (especially not `%TEMP%`).
- Change the pagefile, DNS, or import a custom power-plan GUID.
- Remove Store/WebView2/VCLibs/UI.Xaml/frameworks.

## Requirements

- Windows 11 (build 22000+).
- PowerShell 5.1+.
- Administrator rights.
- Review the script before running; create a restore point.

## Notes

- HKCU tweaks apply to the account running the script. Run it from your own account with "Run as Administrator"; a separate admin account gets its own HKCU.
- `-RemoveBloatApps` removes Xbox overlays/Game Bar, Widgets, Copilot, Bing apps, etc. Skip it if you use those.
- `-ApplyPowerTweaks` is hardware-specific (laptop battery/heat). Skip it on desktops or if you prefer stock power behavior.
- The audit is a snapshot; Windows builds and defaults change.
