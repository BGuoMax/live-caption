# Live Caption

[Installation](INSTALL.md) · [简体中文](README.zh-CN.md)

A free, open-source, real-time bilingual captioning app that runs entirely on your Mac.

## Features

- Capture audio currently playing on your Mac, or switch to microphone input
- Generate real-time original-language captions with Apple on-device speech recognition
- Generate real-time translations with the Apple Translation framework
- Display the original text and translation together
- Keep the caption window above other apps, including in full-screen spaces
- Reposition captions easily with a dedicated drag area at the top of the window
- Keep long captions inside the panel with smooth wrapping and safe line limits
- Adjust the font size of both the original text and translation, change background opacity, and hide the original text; preferences persist across launches
- Use the same font size for the original text and translation while emphasizing only the newest wrapped translation line in bold
- Work without an account, server, paid API, or subscription
- Optionally enable a CS2 commentary glossary with tournament terms, weapon names, map names, and normalized translations
- Automatically save each session's original text and translations as Markdown and JSON for later review

## System Requirements

- macOS 15 or later; macOS 26 is recommended
- An Apple silicon Mac
- An internet connection the first time each Apple offline speech or translation language pack is downloaded

## Install a Release

Download the latest Apple silicon archive from [GitHub Releases](https://github.com/BGuoMax/live-caption/releases), verify its SHA-256 checksum, move **Live Caption.app** to **Applications**, and follow the first-run permission prompts.

The current release build is ad-hoc signed but not Apple-notarized. Read the complete [English installation guide](INSTALL.md) for the safe first-open procedure, language-pack setup, permissions, and troubleshooting. A [Chinese installation guide](INSTALL.zh-CN.md) is also available.

## Build and Run

Install a matching version of Xcode or Apple Command Line Tools, then run:

```bash
./scripts/test.sh
./scripts/build-app.sh
open "dist/Live Caption.app"
```

The project also includes a `Package.swift` manifest and Swift Testing tests. With a complete Xcode installation, you can alternatively run:

```bash
swift test
swift run LiveCaption
```

For normal use, run the packaged `.app` so macOS can display the microphone and speech-recognition permission descriptions correctly.

If the build script reports inconsistent developer tools, install or update Xcode from the App Store, then run:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

## First-Run Permissions

Depending on the selected audio source, the app requests:

- **Speech Recognition**: converts audio into text
- **Microphone**: used only when microphone input is selected
- **Screen & System Audio Recording**: used only when Mac audio is selected; the app does not receive, save, or analyze the screen image

If you previously denied a permission, allow Live Caption in **System Settings → Privacy & Security**, then quit and reopen the app.

Development builds use a stable local signing requirement and fixed bundle ID so permissions survive later rebuilds. If macOS shows permission as enabled after upgrading from an older build but the app still reports a denial, run:

```bash
tccutil reset ScreenCapture local.live-caption.app
```

Then reopen the app and approve the system prompt once more.

## Privacy

Speech recognition and translation use macOS on-device capabilities. The app contains no network client, uploads neither audio nor captions, and collects no telemetry.

## Review Records

When **Save Review** is enabled, clicking **Start** creates a separate record and clicking **Stop** finalizes it. Records are stored in:

```text
~/Documents/Live Caption Records/
```

Markdown files are intended for reading, while JSON files can be searched, analyzed, or imported into other tools. The app saves only original text and translations, never audio.

## Known Limitations

- You must select the original language before using Apple Speech; automatic language detection is not yet available.
- After granting system-audio permission for the first time, macOS may require the app to be restarted.
- Not every language supported by Apple Translation necessarily has a matching on-device Apple Speech language pack.
