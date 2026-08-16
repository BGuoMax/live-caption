# Install Live Caption

[简体中文](INSTALL.zh-CN.md) · [Back to README](README.md)

## Requirements

- An Apple silicon Mac
- macOS 15 or later; macOS 26 is recommended
- Internet access for the initial app download and Apple language packs

## Install from GitHub Releases

1. Open the project's [GitHub Releases](https://github.com/BGuoMax/live-caption/releases) page.
2. Open the newest release and download both files whose names resemble:

   ```text
   Live-Caption-v0.1.0-macOS-arm64.zip
   Live-Caption-v0.1.0-macOS-arm64.zip.sha256
   ```

3. In Terminal, verify the downloaded archive before opening it:

   ```bash
   cd ~/Downloads
   shasum -a 256 -c Live-Caption-v0.1.0-macOS-arm64.zip.sha256
   ```

   Replace `v0.1.0` with the version you downloaded. Continue only if the result says `OK`.

4. Double-click the ZIP file, then drag **Live Caption.app** into the **Applications** folder.
5. Open **Live Caption** from Applications.

## First Open and Gatekeeper

Current community builds are ad-hoc signed but are not signed with an Apple Developer ID or notarized by Apple. macOS may therefore block the first launch.

Only override the warning if you downloaded the archive from this repository's official Releases page and its checksum passed:

1. Try to open **Live Caption** once and close the warning.
2. Open **System Settings → Privacy & Security**.
3. Scroll to **Security** and click **Open Anyway** next to Live Caption.
4. Confirm by clicking **Open** and authenticate if macOS asks.

Apple explains both the protection and this exception process in [Open apps safely on your Mac](https://support.apple.com/102445). A future Developer ID and notarized release can remove this extra step.

## Download Language Resources

Live Caption uses Apple's on-device speech recognition and translation, so the matching system language resources must be present.

### Original-text speech recognition

Download the language spoken in the audio:

1. Open **System Settings → Keyboard**.
2. Turn on **Dictation**.
3. Open **Languages** and add the original language.
4. Stay online until macOS finishes downloading it.

### Translation

Download both the original and translation languages:

1. Open **System Settings → General → Language & Region**.
2. Click **Translation Languages**.
3. Download both languages.
4. Enable **On-Device Mode**, then click **Done**.

Not every Apple Translation language necessarily has a matching on-device Speech model.

## Grant Permissions

Start Live Caption and select an audio source. macOS requests only the permissions needed for that source:

- **Speech Recognition** converts captured audio into original text.
- **Microphone** is required only for microphone input.
- **Screen & System Audio Recording** is required only for Mac audio. Live Caption excludes screen video and processes audio only.

If a permission was denied, open **System Settings → Privacy & Security**, enable Live Caption in the corresponding section, then completely quit and reopen the app.

For a stale system-audio permission left by an older development build, run:

```bash
tccutil reset ScreenCapture local.live-caption.app
```

Reopen the app and approve the prompt again.

## Build from Source

Install Xcode or Apple Command Line Tools, then run:

```bash
git clone https://github.com/BGuoMax/live-caption.git
cd live-caption
./scripts/test.sh
./scripts/build-app.sh
open "dist/Live Caption.app"
```

The built application is located at `dist/Live Caption.app`.

## Publish a Release (Maintainers)

The repository workflow tests, builds, ad-hoc signs, archives, checksums, and publishes the app automatically whenever a semantic version tag is pushed:

```bash
git switch main
git pull --ff-only
git tag -a v0.1.0 -m "Live Caption v0.1.0"
git push origin v0.1.0
```

Use a new version number for each release. You can also open **GitHub → Actions → Build and publish release → Run workflow** and enter a version tag manually.

The workflow attaches the Apple silicon ZIP and its SHA-256 checksum to a GitHub Release. Developer ID signing and Apple notarization are intentionally not configured yet because they require an Apple Developer Program identity and repository secrets.
