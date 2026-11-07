# HyperStack - turn stacked widgets ON.
#
# The launcher auto-restarts after force-stop and rewrites its prefs, so a plain external
# edit can be stomped. Reliable approach: write the flag, cycle the launcher so a fresh
# instance loads it, verify it survived, and retry if the launcher overwrote it.
PKG=com.miui.home
DE=/data/user_de/0/$PKG/shared_prefs
MAIN=$DE/launcher_sharedpreference.xml
BK=/data/local/tmp/hyperstack/backup/$(date +%Y%m%d_%H%M%S)

if [ "$(id -u)" != "0" ]; then echo "ERROR: not running as root"; exit 1; fi
if [ ! -f "$MAIN" ]; then echo "ERROR: $MAIN not found"; exit 1; fi

mkdir -p "$BK" 2>/dev/null
cp -p "$MAIN" "$BK/" 2>/dev/null

write_flag() {
  for f in launcher_sharedpreference.xml launcher_sharedpreference_private.xml; do
    F="$DE/$f"
    [ -f "$F" ] || continue
    O=$(stat -c '%u:%g' "$F" 2>/dev/null)
    C=$(ls -Z "$F" 2>/dev/null | awk '{print $1}')
    sed -i '/debug_force_stack_widget/d' "$F" 2>/dev/null
    sed -i 's|<map>|<map><boolean name="debug_force_stack_widget" value="true"/>|' "$F" 2>/dev/null
    [ -n "$O" ] && chown "$O" "$F" 2>/dev/null
    chmod 600 "$F" 2>/dev/null
    [ -n "$C" ] && { chcon "$C" "$F" 2>/dev/null || restorecon "$F" 2>/dev/null; }
  done
}

flag_on() { grep -q debug_force_stack_widget "$MAIN" 2>/dev/null; }

ok=0
n=0
while [ "$n" -lt 6 ]; do
  am force-stop $PKG >/dev/null 2>&1
  write_flag
  if flag_on; then
    am start -a android.intent.action.MAIN -c android.intent.category.HOME >/dev/null 2>&1
    sleep 2
    if flag_on; then ok=1; break; fi
  fi
  n=$((n + 1))
done

echo "Backup: $BK"
if [ "$ok" -eq 1 ]; then
  echo "SUCCESS: stacked widgets enabled."
  echo "Return to the home screen and stack two same-size MIUI widgets."
else
  echo "ERROR: the launcher kept overwriting the flag (tried $n times)."
  exit 1
fi
