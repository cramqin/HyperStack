# HyperStack - system check report (read only).
PKG=com.miui.home
DE=/data/user_de/0/$PKG/shared_prefs

echo "-- Device --"
echo "Model   : $(getprop ro.product.model)"
echo "Device  : $(getprop ro.product.device)"
echo "Android : $(getprop ro.build.version.release)  (SDK $(getprop ro.build.version.sdk))"
echo "HyperOS : $(getprop ro.miui.ui.version.name)  code $(getprop ro.miui.ui.version.code)"
echo "Build   : $(getprop ro.build.version.incremental)"
echo ""

echo "-- Root --"
id
echo ""

echo "-- Launcher --"
dumpsys package $PKG 2>/dev/null | grep -m1 versionName
echo ""

echo "-- Stack flag --"
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

echo "-- App Vault / minus screen --"
if pm path com.mi.globalminusscreen >/dev/null 2>&1; then
  echo "com.mi.globalminusscreen : $(dumpsys package com.mi.globalminusscreen 2>/dev/null | grep -m1 versionName | tr -d ' ')"
elif pm path com.miui.personalassistant >/dev/null 2>&1; then
  echo "com.miui.personalassistant : present"
else
  echo "app vault not found"
fi
