# Android Dev Environment Setup

**Set up:** 2026-08-27, on this Mac, for the Android port (`feature/android-port` branch)
**Purpose:** everything here is machine-local software/config, not tracked in git. If you move to
a new machine, none of it comes with you automatically - this is the checklist to redo it.

---

## What's machine-local (needs redoing on a new machine)

### 1. Java (JDK 17)

Installed via the Homebrew **formula** (not the `temurin` cask - that needs `sudo`/an admin
password to run its installer, which fails in a non-interactive session):

```bash
brew install openjdk@17
```

This installs keg-only (not symlinked into `/usr/local`), so it needs `JAVA_HOME` set explicitly
rather than relying on a system-wide `java` command.

### 2. Android SDK command-line tools

Installed via Homebrew cask (this is just the SDK tooling, not the full Android Studio GUI -
deliberately chosen since it's scriptable and doesn't need a GUI installer):

```bash
brew install --cask android-commandlinetools
```

Default install location: `/usr/local/share/android-commandlinetools`.

### 3. Environment variables

Added to `~/.zshrc` (already present on this Mac; would need re-adding on a new one):

```bash
export JAVA_HOME="/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export ANDROID_HOME="/usr/local/share/android-commandlinetools"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
```

### 4. SDK components + licenses

```bash
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-36" "platforms;android-35" \
  "build-tools;36.1.0" "emulator" "system-images;android-35;google_apis;x86_64"
```

`flutter_secure_storage` 11.0.0 (used by `supplier_app`) needs `platforms;android-37.0` too -
Gradle auto-installs this itself on first build if missing (it did here), but you can add it
up front:

```bash
sdkmanager "platforms;android-37.0"
```

Currently installed on this Mac (`sdkmanager --list_installed`): platform-tools 37.0.1,
platforms 34/35/36/37.0, build-tools 35.0.0 and 36.1.0, NDK 28.2.13676358, CMake 3.22.1,
emulator 37.1.11, system-images;android-35;google_apis;x86_64.

The NDK and CMake weren't requested explicitly - Gradle pulled them in automatically as part of
the Flutter Gradle plugin's own build requirements. Expect the same to happen again on a fresh
machine; it's normal, not a sign of a missing step.

### 5. Emulator (AVD)

```bash
avdmanager create avd -n Pixel7_API35 -k "system-images;android-35;google_apis;x86_64" -d pixel_7
```

You may see `Error: Could not load devices from .../devices.xml` - this is a harmless
`avdmanager` quirk on current command-line-tools versions; the AVD is created successfully
despite the error text. Verify with `avdmanager list avd`.

AVD data lives at `~/.android/avd/Pixel7_API35.avd` - not tracked anywhere, needs recreating.

**Disk space:** the AVD's userdata partition alone needs ~12GB free. Between the SDK platforms/
build-tools/NDK/emulator downloads and the AVD, budget **20GB+ free disk space** before starting
this whole process on a new machine, more if `flutter build apk` triggers additional on-demand
downloads (platform 37, extra build-tools, etc. - each shows up as an automatic license-accept +
install step in the build log, not a manual action).

### 6. Verify

```bash
flutter doctor -v   # Android toolchain section should show green
```

---

## What's NOT machine-local (already in the repo, travels automatically)

- `applicationId` (`com.ianhamlet.loyaltycards.supplier` / `...customer`) and `compileSdk = 37`
  fix in both apps' `android/app/build.gradle.kts` - committed, just works on `git pull`.
- Gradle wrapper version, AGP version, Kotlin version (`gradle-wrapper.properties`,
  `settings.gradle.kts`) - committed, Gradle downloads the matching distribution itself on first
  build on any machine.
- `android/local.properties` (`flutter.sdk` + `sdk.dir` paths) - **gitignored**, regenerated
  automatically by `flutter pub get` once `ANDROID_HOME`/`flutter config --android-sdk` point at
  a real SDK on the new machine. Don't hand-copy this file between machines; the paths will be
  wrong.

---

## Known issues hit during this setup (for reference, not action items)

- **`temurin` cask needs sudo** - use the `openjdk@17` formula instead (see above).
- **Parallel `brew install` commands can collide** - Homebrew's own internal Ruby vendor install
  takes a lock; running two `brew install`/`brew install --cask` commands at the same time can
  make one fail with "Another `brew vendor-install ruby` process is already running." Run them
  sequentially.
- **`adb reboot` can leave the emulator's `package` service dead** (`adb shell service list`
  won't show `android.content.pm.IPackageManager`, and app installs fail with `Can't find
  service: package`). Fix: kill the emulator process entirely and cold-boot fresh
  (`emulator -avd Pixel7_API35 -no-window -no-audio -no-boot-anim -no-snapshot`) rather than
  trying to reboot in place.
- **`df` can lag behind actual freed disk space** after deleting/erasing large amounts of data
  (seen after erasing iOS Simulator device data) - if a size-dependent operation fails right
  after a big cleanup, wait a few seconds and recheck `df -h /` before concluding the cleanup
  didn't work.
