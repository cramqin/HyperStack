# HyperStack - turn stacked widgets OFF (single gentle pass; no retry storm).
PKG=com.miui.home
DE=/data/user_de/0/$PKG/shared_prefs
MAIN=$DE/launcher_sharedpreference.xml

if [ "$(id -u)" != "0" ]; then echo "ERROR: not running as root"; exit 1; fi
if [ ! -f "$MAIN" ]; then echo "ERROR: $MAIN not found"; exit 1; fi

for f in launcher_sharedpreference.xml launcher_sharedpreference_private.xml; do
  F="$DE/$f"
  [ -f "$F" ] || continue
  grep -q debug_force_stack_widget "$F" 2>/dev/null || continue
  O=$(stat -c '%u:%g' "$F" 2>/dev/null)
  C=$(ls -Z "$F" 2>/dev/null | awk '{print $1}')
    # Remove only the element (the XML is one line — deleting the line kills the file).
    sed -i 's|<boolean[^>]*name="debug_force_stack_widget"[^>]*/>||g' "$F" 2>/dev/null
  [ -n "$O" ] && chown "$O" "$F" 2>/dev/null
  chmod 600 "$F" 2>/dev/null
  [ -n "$C" ] && { chcon "$C" "$F" 2>/dev/null || restorecon "$F" 2>/dev/null; }
done

am force-stop $PKG >/dev/null 2>&1
am start -a android.intent.action.MAIN -c android.intent.category.HOME >/dev/null 2>&1
sleep 3

if grep -q debug_force_stack_widget "$MAIN" 2>/dev/null; then
  echo "WARN: flag still present. Tap \"Turn off\" once more."
else
  echo "SUCCESS: stacked widgets disabled."
fi
