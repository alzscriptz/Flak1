import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct Flak1App: App {
    var body: some Scene {
        WindowGroup { MainView().preferredColorScheme(.dark).frame(minWidth: 900, minHeight: 600) }
            .windowStyle(.titleBar)
    }
}

struct MainView: View {
    @State private var dumpText = """
    // FLAK1 SAMPLE — illustrative local metadata only
    {
      "name": "ExampleMetadata",
      "source": "local sample",
      "address": "0x00000000",
      "kind": "illustrative",
      "note": "Import a file you are authorized to inspect."
    }
    """
    @State private var searchText = ""
    @State private var selectedTab = "Dump Explorer"
    @State private var loadedFile = "Sample metadata"
    @State private var showImporter = false
    @State private var showExporter = false
    @State private var statusMessage = "Ready · Local files only"
    @State private var snowEnabled = true
    @State private var pidText = ""
    @State private var processReport = "Choose a PID and select Inspect process to generate a diagnostic report."
    private let ice = Color(red: 0.28, green: 0.76, blue: 1)
    private let muted = Color(red: 0.52, green: 0.65, blue: 0.75)
    private var lines: [(Int, String)] {
        dumpText.components(separatedBy: .newlines).enumerated().map { ($0.offset + 1, $0.element) }
    }
    private var visibleLines: [(Int, String)] {
        searchText.isEmpty ? lines : lines.filter { $0.1.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack {
            Color(red: 0.025, green: 0.045, blue: 0.075).ignoresSafeArea()
            if snowEnabled { SnowfallView().ignoresSafeArea().allowsHitTesting(false).opacity(0.55) }
            HStack(spacing: 0) {
                sidebar
                VStack(spacing: 0) {
                    header
                    Divider().overlay(Color.white.opacity(0.08))
                    if selectedTab == "Dump Explorer" { explorer } else if selectedTab == "Process Lab" { processLab } else { about }
                    footer
                }
            }.padding(12)
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.plainText, .json, .data], allowsMultipleSelection: false) { result in
            do {
                guard let url = try result.get().first else { return }
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url)
                dumpText = renderImportedData(data)
                loadedFile = url.lastPathComponent
                searchText = ""
                statusMessage = "Imported \(url.lastPathComponent)"
            } catch { statusMessage = "Import failed: \(error.localizedDescription)" }
        }
        .fileExporter(isPresented: $showExporter, document: TextFileDocument(text: dumpText), contentType: .plainText, defaultFilename: "Flak1-dump.txt") { result in
            switch result {
            case .success(let url): statusMessage = "Exported \(url.lastPathComponent)"
            case .failure(let error): statusMessage = "Export failed: \(error.localizedDescription)"
            }
        }
        .tint(ice)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                Image(systemName: "snowflake").font(.system(size: 27)).foregroundStyle(ice)
                    .frame(width: 44, height: 44).background(ice.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("FLAK1").font(.system(size: 20, weight: .black, design: .rounded)).tracking(2)
                    Text("METADATA LAB").font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(1.2).foregroundStyle(muted)
                }
            }.padding(.top, 6)
            Text("WORKSPACE").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1.5).foregroundStyle(muted)
            navItem("Dump Explorer", icon: "square.stack.3d.up")
            navItem("Process Lab", icon: "cpu")
            navItem("About Flak1", icon: "snowflake")
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                Label("LOCAL MODE", systemImage: "circle.fill").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(.white.opacity(0.85))
                Text("No process attachment\nNo network collection").font(.system(size: 10, design: .monospaced)).foregroundStyle(muted).lineSpacing(3)
            }.padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
            Text("CREDITS · ales04718").font(.system(size: 9, weight: .medium, design: .monospaced)).foregroundStyle(muted)
        }.padding(16).frame(width: 218).background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 18))
            .overlay(alignment: .trailing) { Rectangle().fill(Color.white.opacity(0.04)).frame(width: 1) }
    }

    private func navItem(_ title: String, icon: String) -> some View {
        Button { selectedTab = title } label: {
            HStack(spacing: 10) {
                Image(systemName: icon).frame(width: 18)
                Text(title).font(.system(size: 12, weight: .semibold))
                Spacer()
                if selectedTab == title { Circle().fill(ice).frame(width: 5, height: 5).shadow(color: ice, radius: 5) }
            }.foregroundStyle(selectedTab == title ? .white : muted).padding(.horizontal, 12).padding(.vertical, 11)
                .background(selectedTab == title ? ice.opacity(0.13) : .clear, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(selectedTab == title ? ice.opacity(0.25) : .clear, lineWidth: 1))
        }.buttonStyle(.plain)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedTab).font(.system(size: 22, weight: .bold, design: .rounded))
                Text(selectedTab == "Process Lab" ? "Inspect process metadata and export diagnostic reports" : "Inspect and search files you choose to open").font(.system(size: 11)).foregroundStyle(muted)
            }
            Spacer()
            Button { snowEnabled.toggle() } label: { Label("Snow", systemImage: snowEnabled ? "snowflake" : "cloud") }.buttonStyle(QuietButton())
            Button { showImporter = true } label: { Label("Import file", systemImage: "square.and.arrow.down") }.buttonStyle(IceButton())
        }.padding(.horizontal, 20).padding(.vertical, 16)
    }

    private var explorer: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                metric("LINES", value: "\(lines.count)", icon: "list.number")
                metric("MATCHES", value: searchText.isEmpty ? "—" : "\(visibleLines.count)", icon: "magnifyingglass")
                metric("SOURCE", value: loadedFile, icon: "doc.text", compact: true)
            }
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(ice)
                TextField("Search symbols, names, offsets, or any text…", text: $searchText).textFieldStyle(.plain).font(.system(size: 12, design: .monospaced))
                if !searchText.isEmpty { Button { searchText = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(muted) }.buttonStyle(.plain) }
                Text(searchText.isEmpty ? "⌘F" : "\(visibleLines.count) found").font(.system(size: 10, design: .monospaced)).foregroundStyle(muted)
            }.padding(13).background(Color(red: 0.045, green: 0.075, blue: 0.11), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ice.opacity(0.15), lineWidth: 1))
            VStack(spacing: 0) {
                HStack {
                    Circle().fill(.red).frame(width: 7, height: 7)
                    Circle().fill(.orange).frame(width: 7, height: 7)
                    Circle().fill(.green).frame(width: 7, height: 7)
                    Text(loadedFile).font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundStyle(muted).padding(.leading, 8)
                    Spacer()
                    Button { showExporter = true } label: { Label("Export", systemImage: "square.and.arrow.up") }.buttonStyle(QuietButton())
                    Button { copyDump() } label: { Label("Copy all", systemImage: "doc.on.doc") }.buttonStyle(QuietButton())
                }.padding(.horizontal, 14).padding(.vertical, 10)
                Divider().overlay(Color.white.opacity(0.07))
                ScrollView([.vertical, .horizontal]) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if visibleLines.isEmpty { Text("No lines match “\(searchText)”").foregroundStyle(muted).padding(24) }
                        else {
                            ForEach(Array(visibleLines.enumerated()), id: \.offset) { pair in
                                let item = pair.element
                                HStack(alignment: .firstTextBaseline, spacing: 16) {
                                    Text(String(format: "%04d", item.0)).frame(width: 38, alignment: .trailing).foregroundStyle(ice.opacity(0.55))
                                    Text(item.1.isEmpty ? " " : item.1).foregroundStyle(colorForLine(item.1)).textSelection(.enabled)
                                }.font(.system(size: 11, design: .monospaced)).padding(.horizontal, 14).padding(.vertical, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(!searchText.isEmpty && item.1.localizedCaseInsensitiveContains(searchText) ? ice.opacity(0.12) : .clear)
                            }
                        }
                    }.padding(.vertical, 8)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }.background(Color(red: 0.025, green: 0.04, blue: 0.065).opacity(0.94), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }.padding(18)
    }

    private var processLab: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "cpu").font(.system(size: 28)).foregroundStyle(ice)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Process Diagnostics").font(.system(size: 23, weight: .bold, design: .rounded))
                    Text("Inspect a PID using macOS process metadata tools").font(.system(size: 11)).foregroundStyle(muted)
                }
            }
            HStack(spacing: 10) {
                TextField("Process ID (PID)", text: $pidText).textFieldStyle(.roundedBorder).font(.system(.body, design: .monospaced))
                    .onChange(of: pidText) { value in pidText = String(value.filter(\.isNumber).prefix(10)) }
                Button { inspectProcess() } label: { Label("Inspect process", systemImage: "waveform.path.ecg") }.buttonStyle(IceButton())
                Button { dumpText = processReport; loadedFile = "Process diagnostic report"; selectedTab = "Dump Explorer"; statusMessage = "Report loaded in explorer" } label: { Label("Open report", systemImage: "doc.text") }.buttonStyle(QuietButton())
            }
            Text("Report preview").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1.2).foregroundStyle(muted)
            ScrollView([.vertical, .horizontal]) {
                Text(processReport).font(.system(size: 12, design: .monospaced)).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading).padding(16)
            }.background(Color(red: 0.025, green: 0.04, blue: 0.065), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(ice.opacity(0.16), lineWidth: 1))
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle").foregroundStyle(ice)
                Text("This report uses macOS ps metadata only. It does not read process memory or claim to infer private runtime offsets. For reliable symbol offsets, import debug symbols or an authorized developer-generated dump in Dump Explorer.")
                    .font(.system(size: 11)).foregroundStyle(muted).lineSpacing(3)
            }
            Spacer(minLength: 0)
        }.padding(20)
    }

    // Text files stay readable; binary inputs become a conventional 16-byte hex view.
    // This is an offline file viewer, not a live-process memory dumper.
    private func renderImportedData(_ data: Data) -> String {
        if let text = String(data: data, encoding: .utf8) {
            let sample = text.unicodeScalars.prefix(4096)
            let printable = sample.filter { CharacterSet.controlCharacters.contains($0) == false || $0 == "\n" || $0 == "\r" || $0 == "\t" }.count
            if sample.isEmpty || Double(printable) / Double(sample.count) > 0.90 {
                return text
            }
        }
        let bytes = [UInt8](data)
        guard !bytes.isEmpty else { return "(empty file)" }
        var output: [String] = []
        output.reserveCapacity((bytes.count + 15) / 16)
        for start in stride(from: 0, to: bytes.count, by: 16) {
            let end = min(start + 16, bytes.count)
            let slice = bytes[start..<end]
            let hex = slice.map { String(format: "%02X", $0) }.joined(separator: " ")
            let paddedHex = hex.padding(toLength: 47, withPad: " ", startingAt: 0)
            let ascii = slice.map { byte -> Character in
                (byte >= 0x20 && byte <= 0x7E) ? Character(UnicodeScalar(byte)) : "."
            }
            output.append(String(format: "%08X  %@  |%@|", start, paddedHex, String(ascii)))
        }
        return "FLAK1 OFFLINE HEX VIEW\nFile size: \(bytes.count) bytes\nOffset     Hex bytes                                        ASCII\n" + output.joined(separator: "\n")
    }

    private func inspectProcess() {
        guard let pid = Int(pidText), pid > 0 else { processReport = "ERROR: Enter a valid positive numeric PID."; statusMessage = "Invalid PID"; return }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-p", String(pid), "-o", "pid=,ppid=,uid=,state=,etime=,comm="]
        let output = Pipe()
        task.standardOutput = output
        task.standardError = output
        do {
            try task.run()
            task.waitUntilExit()
            let raw = output.fileHandleForReading.readDataToEndOfFile()
            let detail = String(data: raw, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let stamp = ISO8601DateFormatter().string(from: Date())
            if task.terminationStatus == 0 && !detail.isEmpty {
                processReport = """
                FLAK1 PROCESS DIAGNOSTIC REPORT
                Generated: \(stamp)
                Host OS: macOS
                Requested PID: \(pid)
                Status: FOUND
                Fields: PID PPID UID STATE ELAPSED COMMAND
                Process: \(detail)

                Collection method: /bin/ps (metadata only)
                Memory access: Not performed
                Offset confidence: Not assessed — process metadata does not reveal runtime offsets
                """
                statusMessage = "Process metadata collected for PID \(pid)"
            } else {
                processReport = """
                FLAK1 PROCESS DIAGNOSTIC REPORT
                Generated: \(stamp)
                Requested PID: \(pid)
                Status: NOT FOUND OR NOT VISIBLE
                Details: \(detail.isEmpty ? "No matching process returned by macOS ps." : detail)
                """
                statusMessage = "PID \(pid) not found or not visible"
            }
        } catch { processReport = "ERROR inspecting PID \(pid): \(error.localizedDescription)"; statusMessage = "Process inspection failed" }
    }
    private var about: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "snowflake").font(.system(size: 42)).foregroundStyle(ice)
            Text("A colder way to inspect data.").font(.system(size: 28, weight: .bold, design: .rounded))
            Text("Flak1 is a local-first text and metadata explorer. Import files you are authorized to inspect, search their contents instantly, and export your findings.")
                .font(.system(size: 14)).foregroundStyle(muted).lineSpacing(5).frame(maxWidth: 580, alignment: .leading)
            Label("Local files only — no process memory access", systemImage: "lock.shield").foregroundStyle(ice)
            Spacer()
            Text("Designed with icy tones and slow snowfall.").foregroundStyle(muted)
        }.padding(32).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var footer: some View {
        HStack {
            Circle().fill(ice).frame(width: 5, height: 5)
            Text(statusMessage).lineLimit(1)
            Spacer()
            Text("FLAK1 • v3.0.0").foregroundStyle(muted.opacity(0.8))
        }.font(.system(size: 10, design: .monospaced)).foregroundStyle(muted).padding(.horizontal, 18).padding(.vertical, 10)
    }

    private func metric(_ label: String, value: String, icon: String, compact: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(ice)
            VStack(alignment: .leading, spacing: 4) {
                Text(label).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(muted)
                Text(value).font(.system(size: compact ? 11 : 18, weight: .semibold, design: compact ? .monospaced : .rounded)).lineLimit(1).truncationMode(.middle)
            }
            Spacer(minLength: 0)
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    private func colorForLine(_ text: String) -> Color {
        let t = text.trimmingCharacters(in: .whitespaces)
        if t.hasPrefix("//") || t.hasPrefix("#") { return muted }
        if t.contains("0x") { return Color(red: 0.45, green: 0.85, blue: 1) }
        if t.contains(":") { return Color(red: 0.75, green: 0.83, blue: 1) }
        return Color(red: 0.78, green: 0.85, blue: 0.92)
    }
    private func copyDump() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(dumpText, forType: .string)
        statusMessage = "Copied \(lines.count) lines to clipboard"
    }
}

private struct SnowfallView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: false)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<85 {
                    let xBase = CGFloat((i * 73 + 19) % 997) / 997 * size.width
                    let flakeSize = CGFloat((i * 17) % 4 + 1)
                    let speed = CGFloat((i * 13) % 55 + 22)
                    let y = (CGFloat(time.truncatingRemainder(dividingBy: 10000)) * speed + CGFloat(i * 29)).truncatingRemainder(dividingBy: size.height + 20) - 10
                    let sway = sin(time * 0.35 + Double(i)) * Double((i * 11) % 26 - 13)
                    let rect = CGRect(x: xBase + sway, y: y, width: flakeSize, height: flakeSize)
                    context.fill(Path(ellipseIn: rect), with: .color(Color(red: 0.55, green: 0.82, blue: 1).opacity(Double((i * 7) % 55 + 20) / 100)))
                }
            }
        }
    }
}
private struct IceButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 11, weight: .semibold)).padding(.horizontal, 13).padding(.vertical, 9)
            .background(Color(red: 0.18, green: 0.58, blue: 0.85).opacity(configuration.isPressed ? 0.65 : 0.9), in: RoundedRectangle(cornerRadius: 9))
            .foregroundStyle(.white).scaleEffect(configuration.isPressed ? 0.97 : 1).animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
private struct QuietButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 11, weight: .medium)).padding(.horizontal, 10).padding(.vertical, 8)
            .background(Color.white.opacity(configuration.isPressed ? 0.1 : 0.045), in: RoundedRectangle(cornerRadius: 9))
            .foregroundStyle(Color(red: 0.7, green: 0.82, blue: 0.92)).animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
private struct TextFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    var text: String
    init(text: String = "") { self.text = text }
    init(configuration: ReadConfiguration) throws {
        text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self)
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
