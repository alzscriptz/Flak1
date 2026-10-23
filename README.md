# ❄️ Flak1 v2.0.0

**A macOS engineering utility for local process diagnostics and dump analysis.**

Credits: **ales04718**

## v2.0.0

- PID-based process discovery using macOS process metadata
- Structured diagnostic report with timestamp, PID, parent PID, user ID, state, elapsed time, and command
- Open generated reports in the searchable dump explorer, then copy or export them
- Import local text, JSON, logs, symbol maps, and developer-provided dumps for searching
- Universal macOS build for Apple Silicon and Intel
- Icy-blue interface and snowflake branding

## Download

Open the [GitHub Releases page](https://github.com/alzscriptz/Flak1/releases) for the v2.0.0 DMG and checksum when the build finishes.

The release is not notarized unless Apple signing and notarization credentials are configured. macOS may require an explicit override in Privacy & Security.

## Process diagnostics and offsets

Process Lab accepts a PID and uses macOS `ps` to report process metadata. It does not read arbitrary process memory. Generic process metadata cannot establish reliable internal runtime offsets. Offset analysis is available by importing authorized developer-generated dumps, symbol maps, or debug metadata into Dump Explorer; reports should distinguish verified symbol-derived offsets from unverified guesses.

Use this tool only on systems and data you are authorized to inspect. Flak1 does not bypass OS protections or anti-cheat mechanisms.

## Build

The GitHub Actions workflow compiles a universal app bundle for macOS 13+, packages and verifies a DMG, and publishes the v2.0.0 release. The DMG is unsigned/ad-hoc-signed and not notarized when signing credentials are unavailable.

## Credits

**ales04718**
