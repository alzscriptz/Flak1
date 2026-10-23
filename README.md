# ❄️ Flak1

**A dark, icy-blue local metadata and dump explorer for macOS.**

Credits: **ales04718**

![Platform](https://img.shields.io/badge/platform-macOS-77cfff)
![Build](https://img.shields.io/badge/build-GitHub%20Actions-161b22)

Flak1 provides a searchable viewer for text dumps, logs, JSON metadata and other local text files. It features a midnight interface, gently falling snow, a line-numbered viewer, search filtering, copy, and export.

## Features

- 🌨️ Subtle animated snowfall and smooth dark/icy-blue visuals
- 🔎 Instant line search with match counts
- 📂 Import local UTF-8 text, JSON, log and dump files
- 📋 Copy contents and export a text copy
- 🧊 Local-first: no telemetry, no upload, and no process attachment
- 📦 GitHub Actions builds a macOS .dmg artifact

## Download

After the first successful workflow run, open the repository's Actions tab, select "Build Flak1 for macOS", and download the "Flak1-macOS-dmg" artifact from the completed run.

The workflow currently creates an ad-hoc signed app for testing. It is **not notarized**. macOS may warn when opening it; only run builds you trust. A Developer ID certificate and Apple notarization credentials are required for a fully signed public release.

## Build locally

Requires a Mac with Xcode Command Line Tools / Swift installed.

    mkdir -p build/Flak1.app/Contents/MacOS
    swiftc -parse-as-library Sources/Flak1App.swift -o build/Flak1.app/Contents/MacOS/Flak1 -framework SwiftUI -framework AppKit -framework UniformTypeIdentifiers

For a distributable DMG, create a complete app bundle with the Info.plist in .github/workflows/build-macos.yml, then package it with hdiutil.

## Scope and responsible use

Flak1 inspects files that you select. It does not attach to Roblox, read another process's memory, bypass anti-cheat, or fetch private runtime offsets. Use it to examine metadata and symbols you are authorized to access.

## Credits

Created with icy inspiration. **ales04718**
