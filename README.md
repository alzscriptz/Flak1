# ❄️ Flak1

**A dark, icy-blue local metadata and dump explorer for macOS.**

Credits: **ales04718**

Flak1 is a searchable viewer for local text dumps, logs, JSON metadata, and other files you are authorized to inspect.

## Features

- Animated snowfall and dark icy-blue visuals
- Custom snowflake app icon
- Universal macOS binary for Apple Silicon and Intel Macs
- Instant search, line numbers, copy, import, and export
- Local-first; does not upload files or attach to Roblox processes

## Build artifacts

Every push to `main` builds a DMG and validates the disk image. If Apple Developer ID signing and notarization credentials are not configured, Actions uploads a **preview-only, not-notarized** artifact for 14 days.

[Open the latest build in GitHub Actions](https://github.com/alzscriptz/Flak1/actions).

## Public release requirements

A public macOS release that opens under normal Gatekeeper settings must be signed with an Apple Developer ID Application certificate and notarized by Apple. GitHub repository administrators must add these Actions secrets under **Settings → Secrets and variables → Actions**:

- `MACOS_CERTIFICATE_P12`: base64-encoded Developer ID Application certificate exported as a password-protected .p12 file
- `MACOS_CERTIFICATE_PASSWORD`: password used to export the .p12 file
- `MACOS_SIGNING_IDENTITY`: exact Developer ID Application identity name shown by `security find-identity -v -p codesigning`
- `APPLE_ID`: Apple Developer account email
- `APPLE_APP_SPECIFIC_PASSWORD`: app-specific password for notarization
- `APPLE_TEAM_ID`: Apple Developer Team ID

When all six secrets are present, the workflow signs the app, notarizes and staples the DMG, then publishes/updates the public `v0.2.0` GitHub Release. Without these credentials, it deliberately does not label the preview as a full release.

Apple's official requirements: [Notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

## Use

Mount the DMG, drag `Flak1.app` to Applications, and launch it. Use Import file to inspect a local UTF-8 text, JSON, log, or dump file. Search filters the displayed lines; Export saves the loaded text.

## Scope

Flak1 inspects files selected by the user. It does not attach to Roblox, read another process's memory, bypass anti-cheat, or fetch private runtime offsets.

## Credits

**ales04718**
