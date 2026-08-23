import SwiftUI
import fxfileCore
import fxfileLocalization
import fxfileState

@MainActor
public struct ChecksumSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    let files: [FileItem]
    
    @State private var selectedAlgorithm: ChecksumAlgorithm = .sha256
    @State private var computedHashes: [ChecksumResult] = []
    @State private var isCalculating: Bool = false
    @State private var progressValue: Double = 0.0
    @State private var progressMessage: String = ""
    @State private var verifyInput: String = ""
    @State private var copiedAlgorithm: ChecksumAlgorithm? = nil
    
    public init(appState: AppState, files: [FileItem]) {
        self.appState = appState
        self.files = files
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n("checksum.title"))
                    .font(.title2.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                // Target File Info
                HStack(alignment: .top) {
                    Text(L10n("checksum.file"))
                        .fontWeight(.semibold)
                        .frame(width: 110, alignment: .trailing)
                    
                    if files.isEmpty {
                        Text("No file selected")
                            .foregroundColor(.secondary)
                    } else if files.count == 1 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(files[0].name)
                                .fontWeight(.medium)
                            Text(files[0].formattedSize + " — " + files[0].path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("\(files.count) files selected")
                            .fontWeight(.medium)
                    }
                }
                
                // Algorithm Picker
                HStack {
                    Text(L10n("checksum.algorithm"))
                        .fontWeight(.semibold)
                        .frame(width: 110, alignment: .trailing)
                    
                    Picker("", selection: $selectedAlgorithm) {
                        ForEach(ChecksumAlgorithm.allCases) { algo in
                            Text(algo.rawValue).tag(algo)
                        }
                    }
                    .frame(width: 140)
                    
                    Button(L10n("checksum.calculate")) {
                        calculateHashes()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(files.isEmpty || isCalculating)
                }
                
                // Progress Bar if running
                if isCalculating {
                    VStack(alignment: .leading, spacing: 4) {
                        ProgressView(value: progressValue, total: 1.0)
                        Text(progressMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                }
                
                // Results List
                if !computedHashes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Computed Hashes:")
                            .font(.headline)
                        
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(computedHashes, id: \.hash) { result in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack {
                                                Text(result.algorithm.rawValue)
                                                    .font(.caption.bold())
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.accentColor.opacity(0.15))
                                                    .cornerRadius(4)
                                                if files.count > 1 {
                                                    Text(result.fileURL.lastPathComponent)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            Text(result.hash)
                                                .font(.system(.body, design: .monospaced))
                                                .textSelection(.enabled)
                                        }
                                        Spacer()
                                        Button(action: {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(result.hash, forType: .string)
                                            copiedAlgorithm = result.algorithm
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                copiedAlgorithm = nil
                                            }
                                        }) {
                                            Label(copiedAlgorithm == result.algorithm ? "Copied!" : "Copy", systemImage: "doc.on.doc")
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    .padding(8)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(6)
                                }
                            }
                        }
                        .frame(maxHeight: 180)
                    }
                }
                
                // Verify / Compare section
                if !computedHashes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n("checksum.verify"))
                            .font(.headline)
                        
                        HStack {
                            TextField("Paste expected hash to compare...", text: $verifyInput)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                            
                            if !verifyInput.trimmingCharacters(in: .whitespaces).isEmpty {
                                Button("Clear") {
                                    verifyInput = ""
                                }
                            }
                        }
                        
                        let trimmedInput = verifyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedInput.isEmpty {
                            let match = computedHashes.contains { $0.hash.caseInsensitiveCompare(trimmedInput) == .orderedSame }
                            HStack {
                                Image(systemName: match ? "checkmark.seal.fill" : "xmark.seal.fill")
                                    .foregroundColor(match ? .green : .red)
                                Text(match ? L10n("checksum.match") : L10n("checksum.mismatch"))
                                    .fontWeight(.semibold)
                                    .foregroundColor(match ? .green : .red)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Footer
            HStack {
                if !computedHashes.isEmpty {
                    Button(L10n("checksum.export_sfv")) {
                        exportChecksumFile()
                    }
                }
                Spacer()
                Button(L10n("action.close")) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 620, minHeight: 480)
        .onAppear {
            if !files.isEmpty {
                calculateHashes()
            }
        }
    }
    
    private func calculateHashes() {
        guard !files.isEmpty else { return }
        isCalculating = true
        progressValue = 0.0
        computedHashes.removeAll()
        
        let targetFiles = files
        let algo = selectedAlgorithm
        
        Task {
            var results: [ChecksumResult] = []
            for (idx, file) in targetFiles.enumerated() {
                do {
                    let hash = try ChecksumService.shared.calculateChecksum(for: file.url, algorithm: algo) { p in
                        Task { @MainActor in
                            self.progressValue = (Double(idx) + p) / Double(targetFiles.count)
                            self.progressMessage = "Hashing \(file.name)..."
                        }
                    }
                    results.append(ChecksumResult(algorithm: algo, hash: hash, fileURL: file.url, fileSize: file.size))
                } catch {
                    print("Checksum error: \(error)")
                }
            }
            
            await MainActor.run {
                self.computedHashes = results
                self.isCalculating = false
                self.progressValue = 1.0
            }
        }
    }
    
    private func exportChecksumFile() {
        guard !computedHashes.isEmpty, let first = files.first else { return }
        let parent = first.url.deletingLastPathComponent()
        let filename = "\(first.name).\(selectedAlgorithm.defaultExtension)"
        let saveURL = parent.appendingPathComponent(filename)
        
        let content = ChecksumService.shared.generateChecksumExport(results: computedHashes, algorithm: selectedAlgorithm)
        try? content.write(to: saveURL, atomically: true, encoding: .utf8)
        
        appState.activePane.refresh()
    }
}
