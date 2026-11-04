# MacIsland

Enables the hidden **Dynamic Island** (internally `CenterHUD` / System Aperture) that ships in `MenuBarAgent` on **macOS 27.3 beta**, including on Macs without a notch.

## How it works
- Feature flags `MenuBar/LiveActivitiesQFA`, `MenuBar/MenuBarQFA`, `ControlCenter/AVLiveActivity` are switched on.
- `MenuBarAgent` reads `ShowSoftwareNotch` and `EmulateCenterHUD` from its sandbox container, **but only if `IsAppleInternalBuild()` returns true**.
- A tiny dylib interposes `IsAppleInternalBuild` (CoreUtils) to return `true` **only inside MenuBarAgent**; every other process gets the real value.
- A LaunchAgent injects the dylib on login (env var is set for ~3 s and removed right after).

## Requirements
- Apple Silicon, macOS 27.3 (tested on 26C5035r)
- SIP disabled, AMFI disabled (`amfi_get_out_of_my_way=0x1` in boot-args)
- Xcode Command Line Tools

## Install
```bash
git clone https://github.com/MakrSas/MacIsland && cd MacIsland && ./install.sh
```

## Uninstall
```bash
./uninstall.sh
```

## Disclaimer
Disabling SIP/AMFI lowers your Mac's security. Use at your own risk. Not affiliated with Apple.

Credit for discovering the feature: [@itspdfu](https://x.com/itspdfu).
