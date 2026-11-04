# MacIsland

Enables the hidden **Dynamic Island** (internally `CenterHUD` / System Aperture) that ships in `MenuBarAgent` on **macOS 27.3 beta**, including on Macs without a notch.

## How it works
- Uses the native Live Activities support already present in 27.3; no global feature-flag domains are overwritten.
- `MenuBarAgent` reads `ShowSoftwareNotch` and `EmulateCenterHUD` from its **com.apple.MenuBar group-suite preferences**, but only if `IsAppleInternalBuild()` returns true.
- A tiny dylib interposes `IsAppleInternalBuild` (CoreUtils) to return `true` **only inside MenuBarAgent**; every other process gets the real value.
- A LaunchAgent injects the dylib each time you log in, including after restarting. Its loader waits for the new MenuBarAgent PID and restores the previous launch environment immediately, including when a launch fails.

The login loader is `~/Library/LaunchAgents/com.macisland.loader.plist`.
Its logs are `~/Library/MacIsland/loader.log` and `loader-error.log`.
`state = not running` with `last exit code = 0` is normal: the loader exits after injection.

Siri AI / Spotlight has a separate native preference:
`defaults write com.apple.campo SupportsIslandMitosis -bool true`.
The installer sets it too. Restart Siri AI with
`launchctl kickstart -k gui/$(id -u)/com.apple.campo` if it is already running.
This preference persists across login; it does not require injecting Siri AI.

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
