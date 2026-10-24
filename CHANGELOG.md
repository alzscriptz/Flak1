# Changelog

## 3.0.0

### Added
- Offline PE, ELF, and Mach-O identification with architecture metadata and SHA-256 report hashes.
- Printable ASCII string extraction and wildcard AOB signature scans.
- PE section and ELF PT_LOAD mapping from file offsets to preferred virtual addresses, with ASLR/PIE caveats.
- Optional Capstone instruction decoding for supported x86, x86-64, ARM, and ARM64 executable segments.
- Bounded JSON reports, graceful fallback when Capstone is not installed, and unit tests run in CI.
- macOS Process Lab metadata diagnostics and local dump/report exploration.

### Notes and limitations
- Disassembly is a linear sweep, not control-flow recovery; embedded data may decode as instructions.
- Mach-O section/address mapping, YARA integration, semantic matching, and runtime instrumentation are not implemented.
- The analyzer reads selected local files; it does not inspect arbitrary process memory or infer validated private runtime offsets.
- macOS release signing and notarization depend on repository secrets.
