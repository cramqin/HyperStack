# HyperStack

**Unlock home-screen stacked widgets on HyperOS 4 (Global) — safely and reversibly.**

HyperOS 4's System Launcher (V8, the Flutter/Rust rewrite) ships widget stacking but gates
it behind a China/App-Vault flag. HyperStack flips the launcher's own hidden
`debug_force_stack_widget` preference so the feature turns on. It is a **runtime** change to
launcher app-data — nothing is flashed, no system partition is touched, and it is undone by a
single tap (or a reboot plus clearing the launcher).

> This is **not** an LSPosed or Magisk module. The launcher has no `classes.dex` (it's Dart +
> Rust), so LSPosed can't hook it. A tiny root app that writes one preference is the correct
> tool. See [Why an app?](#why-an-app).

---

## What it does

Long-press and stack two **MIUI / App Vault widgets** of the same size on the home screen and
swipe between them. HyperStack unlocks that ability on Global builds where Xiaomi leaves it off.

It only affects **MIUI widgets** (the App Vault "minus screen" widgets). Third-party Android
app widgets are not stackable — that's a HyperOS design limit, not something this can change.

## Requirements

- Rooted device (Magisk, KernelSU, or temporary/exploit root) — the app shells out to `su`.
- HyperOS 4 with the V8 launcher (`com.miui.home`, `RELEASE-8.0…`).
- App Vault / minus screen present (`com.mi.globalminusscreen` or `com.miui.personalassistant`).

## How it works

The launcher's gate is one function in `libapp_launcher.so`:

```
LauncherUtils::is_support_stack_widget()
  1. if PreferenceUtils::get_bool("debug_force_stack_widget")  -> true   (debug override)
  2. if HyperOS < 4                                            -> false
  3. read package meta-data "supportStackWidget" from App Vault -> …
```

Step 3 is false on Global, so stacking stays off. HyperStack writes the override from step 1.

The real preferences live in **device-protected storage** (not `/data/data`):

```
/data/user_de/0/com.miui.home/shared_prefs/launcher_sharedpreference.xml
/data/user_de/0/com.miui.home/shared_prefs/launcher_sharedpreference_private.xml
```

The app inserts `<boolean name="debug_force_stack_widget" value="true"/>` into those files,
restores the original owner/SELinux context, restarts the launcher, and keeps a backup under
`/data/local/tmp/hyperstack/backup/`.

## Usage

1. Install the APK.
2. Open it and grant the superuser prompt when it runs.
3. **Enable** → go to your home screen → stack two same-size MIUI widgets.
4. **Disable** removes the flag (full revert).

## Build

### GitHub Actions (recommended)
Push to `main`; the `build` workflow produces `HyperStack-debug` as a downloadable artifact.
Tag `v1.0.0` to publish a release APK automatically.

### Locally
```bash
# Requires JDK 17 and the Android SDK (ANDROID_HOME set)
./gradlew assembleDebug
# -> app/build/outputs/apk/debug/app-debug.apk
```

> The APK is debug-signed so it installs by sideloading. For your own release signing, add a
> `signingConfig` in `app/build.gradle.kts`.

## Why an app? (app vs LSPosed vs Magisk)

| Option | Works? | Why |
|---|---|---|
| **App (this)** | ✅ | Runs `su` at runtime; works on temp **and** persistent root; one-tap, reversible. |
| LSPosed | ❌ | Launcher is Flutter + Rust with **no `classes.dex`**; the gate is native, nothing for Xposed to hook. |
| Magisk/KSU module | ⚠️ | Works, but needs persistent root and re-applies at boot; more fragile across updates. |

## Notes & disclaimer

- The value is an internal Xiaomi debug switch; it can change or disappear in a future launcher
  update. The app degrades gracefully (it just reports "not set").
- Visual behaviour that "looks like a single widget after a while" is stock HyperOS behaviour,
  not a bug introduced here.
- Use at your own risk. You are modifying another app's private data as root. Backups are made
  automatically, but you are responsible for your device.

## License

MIT — see [LICENSE](LICENSE).
