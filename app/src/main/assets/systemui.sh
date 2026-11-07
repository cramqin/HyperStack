# HyperStack - restart SystemUI (refreshes status bar / recents / overlays).
if [ "$(id -u)" != "0" ]; then
  echo "ERROR: not running as root"
  exit 1
fi

PID=$(pidof com.android.systemui)
if [ -z "$PID" ]; then
  echo "SystemUI is not running; nothing to restart."
else
  echo "Restarting SystemUI (pid $PID)..."
  kill -9 $PID 2>/dev/null
fi
sleep 2
echo "SUCCESS: SystemUI restarted."
