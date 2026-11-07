# HyperStack - disable stacked widgets (revert)
PKG=com.miui.home
DE=/data/user_de/0/$PKG/shared_prefs

if [ "$(id -u)" != "0" ]; then
  echo "ERROR: not running as root"
  exit 1
fi

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

  if grep -q debug_force_stack_widget "$F" 2>/dev/null; then
    OWN=$(stat -c '%u:%g' "$F" 2>/dev/null)
    CTX=$(ls -Z "$F" 2>/dev/null | awk '{print $1}')
    sed -i '/debug_force_stack_widget/d' "$F" 2>/dev/null
    [ -n "$OWN" ] && chown "$OWN" "$F" 2>/dev/null
    chmod 600 "$F" 2>/dev/null
    if [ -n "$CTX" ]; then
      chcon "$CTX" "$F" 2>/dev/null || restorecon "$F" 2>/dev/null
    fi
    echo "reverted: $f"
    COUNT=$((COUNT + 1))
  else
    echo "already clean: $f"
  fi
done

echo ""
echo "Restarting launcher..."
am start -a android.intent.action.MAIN -c android.intent.category.HOME >/dev/null 2>&1
echo "SUCCESS: reverted ($COUNT file(s) cleaned)."
