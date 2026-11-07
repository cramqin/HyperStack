# HyperStack - restart only the launcher (picks up the flag / refresh).
PKG=com.miui.home

if [ "$(id -u)" != "0" ]; then
  echo "ERROR: not running as root"
  exit 1
fi

echo "Restarting launcher..."
am force-stop $PKG >/dev/null 2>&1
sleep 1
am start -a android.intent.action.MAIN -c android.intent.category.HOME >/dev/null 2>&1
sleep 1
echo "SUCCESS: launcher restarted."
