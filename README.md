# HyperStack

**Unlock home-screen stacked widgets on HyperOS 4 (Global) — safely and reversibly.**

HyperOS 4's System Launcher (V8, the Flutter/Rust rewrite) ships widget stacking but gates
it behind a China/App-Vault flag. HyperStack flips the launcher's own hidden
`debug_force_stack_widget` preference so the feature turns on. It's a **runtime** change to
launcher app-data — nothing is flashed, no system partition is touched, and it is undone by a
single tap.

> This is **not** an LSPosed or Magisk module. The launcher has no `classes.dex` (it's Dart +
> Rust), so LSPosed can't hook it. A tiny root app that writes one preference is the correct
> tool. See [Why an app?](#why-an-app).

> **Status:** a hobby project, made in free time **with DeepSeek AI**. It was only tested on one
> device — Xiaomi 25113PN0EG ("pudding"), HyperOS 4.0.1.0 XPCMIXM, launcher
> `RELEASE-8.01.02.7755` — so it is **not guaranteed to work on every device / ROM / launcher
> build**. If something breaks or doesn't work, open an Issue ("ticket") and attach the in-app
> **Copy log** / **System check** output (see [Support](#support)).

## What it does

Long-press and stack two **MIUI / App Vault widgets** of the same size on the home screen and
swipe between them. HyperStack unlocks that on Global builds where Xiaomi leaves it off.

It only affects **MIUI widgets** (App Vault "minus screen" widgets). Third-party Android app
widgets are not stackable — that's a HyperOS design limit, not something this can change.

## Requirements

- Rooted device (Magisk, KernelSU, or temporary/exploit root) — the app shells out to `su`.
- HyperOS 4 with the V8 launcher (`com.miui.home`, `RELEASE-8.0…`).
- App Vault / minus screen present (`com.mi.globalminusscreen` or `com.miui.personalassistant`).

## Usage

1. Install the APK (use the **release** APK — see [Signing and updates](#signing-and-updates)).
2. Open it; grant the superuser prompt.
3. **Turn on** — it writes the flag and cycles the launcher automatically (a few seconds).
4. On the home screen, long‑press one same‑size MIUI widget and drop it onto another.
5. **Turn off** to revert (also cycles the launcher).

**Restart Launcher** / **Restart SystemUI** are there if you want to force a refresh. The
console shows each action's output; **Copy log** / **Clear log** are provided, and
**System check** prints a device/launcher/flag report.

## How it works

The gate is one function in `libapp_launcher.so`:

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

The scripts insert `<boolean name="debug_force_stack_widget" value="true"/>`, restore the
original owner/SELinux context, and back up to `/data/local/tmp/hyperstack/backup/`.

## Build

### GitHub Actions
- Push to `main` → the `build` workflow builds a debug APK (compile check / quick test).
- Push a tag `v*` → the `release` workflow builds a **signed** release APK and attaches it to
  the GitHub release. Tags containing `beta`, `alpha` or `rc` are published as **pre-releases**.
- Rebuild an existing release without moving its tag:
  `gh workflow run release.yml --ref refs/tags/v0.0.4-beta` (or Actions → release → Run workflow
  on that tag).

### Locally
```bash
# Requires JDK 17 and the Android SDK (ANDROID_HOME set)
./gradlew assembleDebug     # debug
./gradlew assembleRelease   # release (debug-signed unless KEYSTORE_FILE is set)
```

## Signing and updates

So that a newer build (e.g. `0.0.4-beta`) installs **over** an older one (e.g. `0.0.3-beta`) —
Android requires the same signature — the release APK is signed with a stable keystore stored in
repository secrets:

| Secret              | Value                                             |
|---------------------|---------------------------------------------------|
| `KEYSTORE_BASE64`   | base64 of the `.keystore` file (single line)      |
| `KEYSTORE_PASSWORD` | keystore password                                 |
| `KEY_ALIAS`         | key alias (e.g. `hyperstack`)                     |
| `KEY_PASSWORD`      | key password                                      |

`app/build.gradle.kts` reads these via env vars (`KEYSTORE_FILE`, `KEYSTORE_PASSWORD`,
`KEY_ALIAS`, `KEY_PASSWORD`). With no secrets it falls back to the debug key so local builds
still work.

> Keep a backup of the keystore. If it changes, users must uninstall before installing a newer
> version. Install the **release** APK (not the CI debug artifact) so updates keep working.

## Why an app?

| Option | Works? | Why |
|---|---|---|
| **App (this)** | ✅ | Runs `su` at runtime; works on temp **and** persistent root; one-tap, reversible. |
| LSPosed | ❌ | Launcher is Flutter + Rust with **no `classes.dex`**; the gate is native, nothing for Xposed to hook. |
| Magisk/KSU module | ⚠️ | Works, but needs persistent root and re-applies at boot; more fragile across updates. |

## FAQ

**What if I lose root, or my temporary root disappears after a reboot?**
Nothing breaks — no bootloop, no crash, no brick. The unlock is just a preference stored in the
launcher's own data (`/data/user_de/0/com.miui.home/shared_prefs/…`), which **persists across
reboots — both a soft reboot and a full reboot**. With the flag set, stacking keeps working even
with root gone. Without root the app
simply can't run its commands (it shows "Root not granted") and can't toggle the flag until root
is back. The app has no boot-time service and does not auto-start, so it can never affect boot.

**To turn it off you need root again.** If you're unrooted and want to revert, either re-gain
root and tap **Turn off**, or clear the launcher's data (which resets the home screen layout).

**If I revoke root (e.g. remove HyperStack's superuser grant), does stacking turn off?** No.
The flag is already written into the launcher's data; revoking root only stops the app from
*toggling* it. Stacking stays on until you re-grant root and tap **Turn off**.

**Does toggling reset my home-screen layout / grid / transitions?** Not in `0.0.4-beta` and
later — fixing an earlier bug where disabling could clear the launcher's preferences. Updates
are applied by editing a single element and cycling the launcher; enable/disable leave the rest
of your preferences intact.

**Why are beta builds published as pre-releases?** Tags containing `beta`/`alpha`/`rc` are
published as pre-releases by the workflow, so the latest stable release isn't shadowed.

## Known limitations

These are HyperOS / App Vault behaviours that the preference unlock exposes but does **not**
change:

- **The "Add to stack" button (long‑press a stack → Edit stack) does nothing.** The launcher
  tries to open `stack_add://com.mi.globalminusscreen`, but the Global App Vault (13.75.0)
  does not expose that activity, so it resolves to nothing.
  *Workaround:* **drag another same‑size MIUI widget onto the existing stack** to add it.
- **Turning the module off while a stack exists dissolves it**, and a freed widget may be moved
  to another slot (often the last page) because it now needs its own cell. If layout matters,
  dissolve the stack in the UI *before* turning the module off. This is the launcher's placement
  logic, not something the tool controls.
- Stacks only accept **MIUI / App Vault widgets**, not third‑party Android widgets.

## Notes & disclaimer

- The value is an internal Xiaomi debug switch; it can change or disappear in a future launcher
  update. The app degrades gracefully (it just reports "not set").
- Visual behaviour that "looks like a single widget after a while" is stock HyperOS behaviour,
  not a bug introduced here.
- Use at your own risk. You are modifying another app's private data as root. Backups are made
  automatically, but you are responsible for your device.

## Support

This is a free-time hobby project **made with DeepSeek AI**, provided as-is with no guarantee.
Tested only on the single device/build listed at the top; your mileage may vary.

If it doesn't work or something breaks:

1. In the app, run **System check** and tap **Copy log** (or copy the console).
2. Open a GitHub **Issue** and paste that log, plus: device model/codename, HyperOS version,
   launcher `versionName`, and your root solution (Magisk / KernelSU / temp root).

I can't promise fixes, but a log makes it diagnosable.

## License

MIT — see [LICENSE](LICENSE).
