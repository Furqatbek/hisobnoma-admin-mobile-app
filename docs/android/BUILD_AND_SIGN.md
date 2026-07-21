# Android — Build & Sign

How to build the Hisobnoma APK for **internal sideloading onto Android tills**,
with a proper upload keystore so updates install over old versions.

> Why signing matters even for sideloading: Android only lets a new APK
> **update** an installed one if both are signed with the **same key**. The
> debug key differs per machine/SDK, so without a fixed keystore your tills
> would need a full uninstall/reinstall (losing local data) on every update.
> Set the keystore up once and every future build upgrades cleanly.

The Gradle config (`android/app/build.gradle.kts`) already does the right thing:
- if `android/key.properties` exists → release is signed with your keystore;
- if not → release falls back to the debug key (installs, but not upgrade-safe).

Secrets are already git-ignored (`key.properties`, `*.jks`, `android/keystore/`).
**Never commit the keystore or `key.properties`.**

---

## One-time setup — create the keystore

Run on your machine (needs the JDK `keytool`, which ships with Android
Studio / Flutter's bundled JDK):

```bash
# From the repo root. Creates the keystore where Gradle expects it.
mkdir -p android/keystore
keytool -genkey -v -keystore android/keystore/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias hisobnoma
```

It will prompt for a **store password**, a **key password** (you can use the
same for both), and a name/org (any real values are fine). Remember these.

Then create **`android/key.properties`** (this file is git-ignored):

```properties
storePassword=<the store password you chose>
keyPassword=<the key password you chose>
keyAlias=hisobnoma
storeFile=../keystore/upload-keystore.jks
```

> `storeFile` is resolved relative to `android/app/`, so
> `../keystore/upload-keystore.jks` points at `android/keystore/upload-keystore.jks`.

### ⚠️ Back these up permanently
- `android/keystore/upload-keystore.jks`
- the two passwords + the alias (`hisobnoma`)

Store them somewhere safe (password manager). If you lose the keystore, you can
**never** ship an upgrade that installs over the existing app — every till would
need a clean reinstall.

---

## Build the APK

```bash
flutter pub get

# Per-CPU APKs — smallest download; hand out the arm64-v8a one.
flutter build apk --release --split-per-abi
```

Outputs in `build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk`  ← use this for virtually all modern devices
- `app-armeabi-v7a-release.apk`  (older 32-bit devices)
- `app-x86_64-release.apk`  (emulators)

Prefer a single universal APK instead? Drop `--split-per-abi`:

```bash
flutter build apk --release          # → app-release.apk (larger, runs anywhere)
```

Install: copy the `.apk` to the device and open it (enable "install unknown
apps" for your file manager the first time).

### Verify it's really signed with your key
```bash
# From Android SDK build-tools; confirms the signer is your keystore, not debug.
apksigner verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## Versioning
The APK's version comes from `pubspec.yaml` (`version: 1.0.4+5` → versionName
`1.0.4`, versionCode `5`). Bump it before each new build you distribute, or
Android may refuse to install an APK with an equal/lower versionCode over an
existing one.

---

## Notes
- **Push notifications are iOS-only right now.** The Android build runs fine, but
  push requires FCM (a separate effort — see `docs/push/APNS_PUSH_PLAN.md` §6.3).
  The in-app Alerts center and bell work on Android today.
- For the **Play Store** later, build an App Bundle instead:
  `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`.
