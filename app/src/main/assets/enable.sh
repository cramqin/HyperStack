# HyperStack - enable stacked widgets
# Runs as root (piped to `su -c "sh -s"`).
PKG=com.miui.home
DE=/data/user_de/0/$PKG/shared_prefs
BK=/data/local/tmp/hyperstack/backup/$(date +%Y%m%d_%H%M%S)

if [ "$(id -u)" != "0" ]; then
  echo "ERROR: not running as root"
  exit 1
fi

if [ ! -d "$DE" ]; then
  echo "ERROR: $DE not found (is the launcher initialized?)"
  exit 1
fi

mkdir -p "$BK" 2>/dev/null
echo "Backup dir: $BK"
echo ""

echo "Stopping launcher..."
am force-stop $PKG >/dev/null 2>&1
sleep 1

COUNT=0
for f in launcher_sharedpreference.xml launcher_sharedpreference_private.xml; do
  F="$DE/$f"
  if [ ! -f "$F" ]; then
    echo "skip (missing): $f"
    continue
  fi

  cp -p "$F" "$BK/" 2>/dev/null
  OWN=$(stat -c '%u:%g' "$F" 2>/dev/null)
  CTX=$(ls -Z "$F" 2>/dev/null | awk '{print $1}')

  sed -i '/debug_force_stack_widget/d' "$F" 2>/dev/null
  sed -i 's|<map>|<map><boolean name="debug_force_stack_widget" value="true"/>|' "$F" 2>/dev/null

  if grep -q debug_force_stack_widget "$F" 2>/dev/null; then
    [ -n "$OWN" ] && chown "$OWN" "$F" 2>/dev/null
    chmod 600 "$F" 2>/dev/null
    if [ -n "$CTX" ]; then
      chcon "$CTX" "$F" 2>/dev/null || restorecon "$F" 2>/dev/null
    fi
    echo "patched: $f"
    COUNT=$((COUNT + 1))
  else
    echo "FAILED: $f"
  fi
done

echo ""
if [ "$COUNT" -gt 0 ]; then
  echo "Restarting launcher..."
  am start -a android.intent.action.MAIN -c android.intent.category.HOME >/dev/null 2>&1
  echo "SUCCESS: stacked widgets enabled ($COUNT file(s) patched)."
else
  echo "ERROR: nothing was patched."
  exit 1
fi
