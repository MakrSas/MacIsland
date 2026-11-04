#!/bin/bash
AGENT="$HOME/Library/LaunchAgents/com.macisland.loader.plist"
launchctl bootout gui/$(id -u) "$AGENT" 2>/dev/null
rm -f "$AGENT"; rm -rf "$HOME/Library/MacIsland"
C="$HOME/Library/Containers/com.apple.MenuBarAgent/Data/Library/Preferences/com.apple.MenuBarAgent"
for d in "$C" com.apple.MenuBarAgent com.apple.MenuBar; do
  defaults delete "$d" ShowSoftwareNotch 2>/dev/null; defaults delete "$d" EmulateCenterHUD 2>/dev/null
done
sudo rm -f /Library/Preferences/FeatureFlags/Domain/MenuBar.plist /Library/Preferences/FeatureFlags/Domain/ControlCenter.plist
killall MenuBarAgent
echo "Removed. Reboot to fully reset feature flags."
