#!/bin/bash
# MacIsland — enables the hidden Dynamic Island (CenterHUD) in MenuBarAgent on macOS 27.3+
set -e
DIR="$HOME/Library/MacIsland"
AGENT="$HOME/Library/LaunchAgents/com.macisland.loader.plist"
SRC="$(cd "$(dirname "$0")" && pwd)"

[[ "$(uname -m)" == "arm64" ]] || { echo "Apple Silicon only"; exit 1; }
csrutil status | grep -q disabled || { echo "SIP must be disabled"; exit 1; }
nvram boot-args 2>/dev/null | grep -q amfi_get_out_of_my_way || {
  echo "AMFI must be disabled: sudo nvram boot-args=\"amfi_get_out_of_my_way=0x1\" and reboot"; exit 1; }

echo "[1/4] Enabling feature flags (sudo)"
FF=/Library/Preferences/FeatureFlags/Domain
sudo mkdir -p $FF
sudo defaults write $FF/MenuBar.plist LiveActivitiesQFA -dict Enabled -bool true
sudo defaults write $FF/MenuBar.plist MenuBarQFA -dict Enabled -bool true
sudo defaults write $FF/ControlCenter.plist AVLiveActivity -dict Enabled -bool true

echo "[2/4] Writing MenuBarAgent preferences"
C="$HOME/Library/Containers/com.apple.MenuBarAgent/Data/Library/Preferences/com.apple.MenuBarAgent"
for d in "$C" com.apple.MenuBarAgent com.apple.MenuBar; do
  defaults write "$d" ShowSoftwareNotch -bool true
  defaults write "$d" EmulateCenterHUD -bool true
done

echo "[3/4] Building dylib"
mkdir -p "$DIR"
clang -arch arm64e -dynamiclib -o "$DIR/island.dylib" "$SRC/src/island.c" \
  -F/System/Library/PrivateFrameworks -framework CoreUtils -undefined dynamic_lookup
codesign -f -s - "$DIR/island.dylib"
cat > "$DIR/load.sh" <<SH
#!/bin/bash
launchctl setenv DYLD_INSERT_LIBRARIES "$DIR/island.dylib"
killall MenuBarAgent
sleep 3
launchctl unsetenv DYLD_INSERT_LIBRARIES
SH
chmod +x "$DIR/load.sh"

echo "[4/4] Installing LaunchAgent"
mkdir -p "$(dirname "$AGENT")"
cat > "$AGENT" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.macisland.loader</string>
  <key>ProgramArguments</key><array><string>$DIR/load.sh</string></array>
  <key>RunAtLoad</key><true/>
</dict></plist>
PL
launchctl bootout gui/$(id -u) "$AGENT" 2>/dev/null || true
launchctl bootstrap gui/$(id -u) "$AGENT"
echo "Done. Play some music and look at the top of the screen."
