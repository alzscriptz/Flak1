# ❄️ Flak1 v3.0.0

**A macOS engineering utility for local process diagnostics and dump analysis.**

Credits: **ales04718**

## v3.0.0

- PID-based process discovery using macOS process metadata
- Structured diagnostic report with timestamp, PID, parent PID, user ID, state, elapsed time, and command
- Open generated reports in the searchable dump explorer, then copy or export them
- Import local text, JSON, logs, symbol maps, and developer-provided dumps for searching
- Offline binary triage CLI for PE, ELF, and Mach-O identification, printable strings, SHA-256 hashing, and wildcard AOB scans
- PE section and ELF PT_LOAD file-offset to preferred virtual-address mapping
- Optional Capstone linear-sweep disassembly for supported x86/x86-64/ARM/ARM64 executable segments, with instruction and output limits
- JSON reports with file-offset matches and explicit limits on what the scan proves
- Unit tests for binary identification, wildcard matching, and report generation
- Universal macOS build for Apple Silicon and Intel
- Icy-blue interface and snowflake branding

## Download

Open the [GitHub Releases page](https://github.com/alzscriptz/Flak1/releases) for the v3.0.0 DMG and checksum when the build finishes.

The release is not notarized unless Apple signing and notarization credentials are configured. macOS may require an explicit override in Privacy & Security.

## Offline binary analyzer (first analysis-engine milestone)

Run the CLI on a local binary or authorized capture:

```bash
python3 Tools/flak1_analyze.py ./sample.bin --pattern "48 8B ?? ?? 89" --output report.json
python3 -m unittest discover -s Tests -v
```

The scanner reports **file offsets**, not live virtual addresses or validated runtime offsets. The engine identifies PE/ELF/Mach-O formats, reports basic architecture metadata, extracts printable ASCII strings, hashes the input, and scans wildcard byte signatures. It now parses PE sections and ELF PT_LOAD segments, mapping file-offset findings to preferred PE image addresses or ELF virtual addresses when the match lies inside a parsed section/segment. PE addresses are preferred image addresses (ASLR may relocate them); ELF PIE/shared-object runtime bases may differ. Thin 64-bit Mach-O section mapping is implemented, including section file offsets and VM addresses; universal/fat slice selection and 32-bit Mach-O section mapping are not implemented yet. Mach-O VM addresses may need a runtime slide and are not validated runtime object offsets. Optional disassembly is available with `--disassemble` when the `capstone` Python package is installed; without it, the report explicitly marks disassembly unavailable and continues normally. Disassembly is a bounded linear sweep of executable segments, not a control-flow graph, and may decode embedded data as instructions. It is not yet a CFG/AST engine, YARA integration, or runtime instrumentation system. CI runs the unit tests before building the app.

## Process diagnostics and offsets

Process Lab accepts a PID and uses macOS `ps` to report process metadata. It does not read arbitrary process memory. Generic process metadata cannot establish reliable internal runtime offsets. Offset analysis is available by importing authorized developer-generated dumps, symbol maps, or debug metadata into Dump Explorer; reports should distinguish verified symbol-derived offsets from unverified guesses.

Use this tool only on systems and data you are authorized to inspect. Flak1 does not bypass OS protections or anti-cheat mechanisms.

## Build

The GitHub Actions workflow compiles a universal app bundle for macOS 13+, packages and verifies a DMG, and publishes the v3.0.0 release. The DMG is unsigned/ad-hoc-signed and not notarized when signing credentials are unavailable.

## Credits

**ales04718**
