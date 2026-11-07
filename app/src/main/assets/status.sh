# HyperStack - status (read only)
PKG=com.miui.home
DE=/data/user_de/0/$PKG/shared_prefs

echo "== root =="
id
echo ""

echo "== launcher =="
dumpsys package $PKG 2>/dev/null | grep -m1 versionName
echo ""

echo "== flag =="
for f in launcher_sharedpreference.xml launcher_sharedpreference_private.xml; do
  F="$DE/$f"
  if [ -f "$F" ]; then
    if grep -q debug_force_stack_widget "$F" 2>/dev/null; then
      echo "$f : ENABLED"
    else
      echo "$f : not set"
    fi
  else
    echo "$f : missing"
  fi
done
echo ""

echo "== app vault =="
if pm path com.mi.globalminusscreen >/dev/null 2>&1; then
  echo "com.mi.globalminusscreen : present"
elif pm path com.miui.personalassistant >/dev/null 2>&1; then
  echo "com.miui.personalassistant : present"
else
  echo "app vault not found"
fi
