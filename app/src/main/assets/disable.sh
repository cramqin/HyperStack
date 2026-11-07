# HyperStack - turn stacked widgets OFF.
# Same write/verify/retry approach as enable (the launcher rewrites its prefs).
PKG=com.miui.home
DE=/data/user_de/0/$PKG/shared_prefs
MAIN=$DE/launcher_sharedpreference.xml

if [ "$(id -u)" != "0" ]; then echo "ERROR: not running as root"; exit 1; fi
if [ ! -f "$MAIN" ]; then echo "ERROR: $MAIN not found"; exit 1; fi

remove_flag() {
  for f in launcher_sharedpreference.xml launcher_sharedpreference_private.xml; do
    F="$DE/$f"
    [ -f "$F" ] || continue
    grep -q debug_force_stack_widget "$F" 2>/dev/null || continue
    O=$(stat -c '%u:%g' "$F" 2>/dev/null)
    C=$(ls -Z "$F" 2>/dev/null | awk '{print $1}')
    sed -i '/debug_force_stack_widget/d' "$F" 2>/dev/null
    [ -n "$O" ] && chown "$O" "$F" 2>/dev/null
    chmod 600 "$F" 2>/dev/null
    [ -n "$C" ] && { chcon "$C" "$F" 2>/dev/null || restorecon "$F" 2>/dev/null; }
  done
}

flag_off() { ! grep -q debug_force_stack_widget "$MAIN" 2>/dev/null; }

ok=0
n=0
while [ "$n" -lt 6 ]; do
  am force-stop $PKG >/dev/null 2>&1
  remove_flag
  if flag_off; then
    am start -a android.intent.action.MAIN -c android.intent.category.HOME >/dev/null 2>&1
    sleep 2
    if flag_off; then ok=1; break; fi
  fi
  n=$((n + 1))
done

if [ "$ok" -eq 1 ]; then
  echo "SUCCESS: stacked widgets disabled."
else
  echo "ERROR: could not clear the flag (tried $n times)."
  exit 1
fi
