# HyperStack - turn stacked widgets ON (single gentle pass; no retry storm).
# Write the flag, cycle the launcher once so it loads it, verify once.
PKG=com.miui.home
DE=/data/user_de/0/$PKG/shared_prefs
MAIN=$DE/launcher_sharedpreference.xml
BK=/data/local/tmp/hyperstack/backup/$(date +%Y%m%d_%H%M%S)

if [ "$(id -u)" != "0" ]; then echo "ERROR: not running as root"; exit 1; fi
if [ ! -f "$MAIN" ]; then echo "ERROR: $MAIN not found"; exit 1; fi

mkdir -p "$BK" 2>/dev/null
cp -p "$MAIN" "$BK/" 2>/dev/null

for f in launcher_sharedpreference.xml launcher_sharedpreference_private.xml; do
  F="$DE/$f"
  [ -f "$F" ] || continue
  O=$(stat -c '%u:%g' "$F" 2>/dev/null)
  C=$(ls -Z "$F" 2>/dev/null | awk '{print $1}')
  # Remove any existing element (NOT the whole line: this XML is a single line).
  sed -i 's|<boolean[^>]*name="debug_force_stack_widget"[^>]*/>||g' "$F" 2>/dev/null
  sed -i 's|<map>|<map><boolean name="debug_force_stack_widget" value="true"/>|' "$F" 2>/dev/null
  [ -n "$O" ] && chown "$O" "$F" 2>/dev/null
  chmod 600 "$F" 2>/dev/null
  [ -n "$C" ] && { chcon "$C" "$F" 2>/dev/null || restorecon "$F" 2>/dev/null; }
done

am force-stop $PKG >/dev/null 2>&1
am start -a android.intent.action.MAIN -c android.intent.category.HOME >/dev/null 2>&1
sleep 3

echo "Backup: $BK"
if grep -q debug_force_stack_widget "$MAIN" 2>/dev/null; then
  echo "SUCCESS: stacked widgets enabled."
else
  echo "WARN: flag not seen after restart. Tap \"Turn on\" once more."
fi
