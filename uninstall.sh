#!/bin/bash
AGENT="$HOME/Library/LaunchAgents/com.macisland.loader.plist"
launchctl bootout gui/$(id -u) "$AGENT" 2>/dev/null
rm -f "$AGENT"; rm -rf "$HOME/Library/MacIsland"
C="$HOME/Library/Group Containers/com.apple.MenuBar/Library/Preferences/com.apple.MenuBar"
for d in "$C"; do
  defaults delete "$d" ShowSoftwareNotch 2>/dev/null; defaults delete "$d" EmulateCenterHUD 2>/dev/null
done
defaults delete com.apple.campo SupportsIslandMitosis 2>/dev/null
# Do not remove whole feature-flag domains: they may contain unrelated settings.
killall MenuBarAgent
echo "Removed. Reboot to fully reset feature flags."
