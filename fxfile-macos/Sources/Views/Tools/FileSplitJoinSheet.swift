import SwiftUI
import fxfileCore
import fxfileLocalization
import fxfileState

@MainActor
public struct FileSplitJoinSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    let initialFile: FileItem?
    
    @State private var selectedTab: Int = 0 // 0 = Split, 1 = Join
    
    // Split State
    @State private var splitSourceURL: URL?
    @State private var splitOutputDir: URL?
    @State private var splitPreset: SplitPresetSize = .zip100
    @State private var customSizeMB: Int = 100
    @State private var useCustomSize: Bool = false
    @State private var generateChecksum: Bool = true
    @State private var isSplitting: Bool = false
    @State private var splitProgress: Double = 0.0
    @State private var splitStatusText: String = ""
    
    // Join State
    @State private var joinFirstPartURL: URL?
    @State private var joinOutputDir: URL?
    @State private var joinOutputName: String = ""
    @State private var detectedParts: [URL] = []
    @State private var isJoining: Bool = false
    @State private var joinProgress: Double = 0.0
    @State private var joinStatusText: String = ""
    
    public init(appState: AppState, file: FileItem?) {
        self.appState = appState
        self.initialFile = file
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n("splitjoin.title"))
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
            
            Picker("", selection: $selectedTab) {
                Text(L10n("splitjoin.tab_split")).tag(0)
                Text(L10n("splitjoin.tab_join")).tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if selectedTab == 0 {
                // Split View
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(L10n("splitjoin.source_file"))
                            .frame(width: 130, alignment: .trailing)
                        Text(splitSourceURL?.lastPathComponent ?? "None selected")
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Spacer()
                        Button("Choose...") {
                            chooseSplitSource()
                        }
                    }
                    
                    HStack {
                        Text(L10n("splitjoin.output_folder"))
                            .frame(width: 130, alignment: .trailing)
                        Text(splitOutputDir?.path ?? "Same directory")
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Button("Change...") {
                            chooseSplitOutputDir()
                        }
                    }
                    
                    HStack(alignment: .top) {
                        Text(L10n("splitjoin.chunk_size"))
                            .frame(width: 130, alignment: .trailing)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("", selection: $splitPreset) {
                                ForEach(SplitPresetSize.allCases) { preset in
                                    Text(preset.displayName).tag(preset)
                                }
                            }
                            .disabled(useCustomSize)
                            .frame(width: 220)
                            
                            Toggle("Custom Size (MB)", isOn: $useCustomSize)
                            if useCustomSize {
                                HStack {
                                    Stepper("\(customSizeMB) MB", value: $customSizeMB, in: 1...100000, step: 10)
                                }
                            }
                            
                            Toggle("Create .sfv Checksum File", isOn: $generateChecksum)
                        }
                    }
                    
                    if isSplitting {
                        VStack(alignment: .leading, spacing: 4) {
                            ProgressView(value: splitProgress, total: 1.0)
                            Text(splitStatusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Button(L10n("splitjoin.split_btn")) {
                            startSplit()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(splitSourceURL == nil || isSplitting)
                    }
                }
                .padding()
            } else {
                // Join View
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(L10n("splitjoin.first_part"))
                            .frame(width: 140, alignment: .trailing)
                        Text(joinFirstPartURL?.lastPathComponent ?? "None selected (.001)")
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Spacer()
                        Button("Choose...") {
                            chooseJoinFirstPart()
                        }
                    }
                    
                    if !detectedParts.isEmpty {
                        HStack {
                            Text(L10n("splitjoin.parts_found"))
                                .frame(width: 140, alignment: .trailing)
                            Text("\(detectedParts.count) parts detected")
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    HStack {
                        Text("Output Name:")
                            .frame(width: 140, alignment: .trailing)
                        TextField("Output filename", text: $joinOutputName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text(L10n("splitjoin.output_folder"))
                            .frame(width: 140, alignment: .trailing)
                        Text(joinOutputDir?.path ?? "Same directory")
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Button("Change...") {
                            chooseJoinOutputDir()
                        }
                    }
                    
                    if isJoining {
                        VStack(alignment: .leading, spacing: 4) {
                            ProgressView(value: joinProgress, total: 1.0)
                            Text(joinStatusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Button(L10n("splitjoin.join_btn")) {
                            startJoin()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(joinFirstPartURL == nil || detectedParts.isEmpty || isJoining)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 580, minHeight: 440)
        .onAppear {
            if let file = initialFile {
                if file.name.hasSuffix(".001") {
                    selectedTab = 1
                    joinFirstPartURL = file.url
                    joinOutputDir = file.url.deletingLastPathComponent()
                    detectedParts = FileSplitJoinEngine.shared.findSequentialParts(firstPartURL: file.url)
                    joinOutputName = FileSplitJoinEngine.shared.suggestedJoinedName(firstPartURL: file.url)
                } else {
                    splitSourceURL = file.url
                    splitOutputDir = file.url.deletingLastPathComponent()
                }
            }
        }
    }
    
    // MARK: - Handlers
    
    private func chooseSplitSource() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            splitSourceURL = url
            if splitOutputDir == nil {
                splitOutputDir = url.deletingLastPathComponent()
            }
        }
    }
    
    private func chooseSplitOutputDir() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            splitOutputDir = url
        }
    }
    
    private func chooseJoinFirstPart() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            joinFirstPartURL = url
            joinOutputDir = url.deletingLastPathComponent()
            detectedParts = FileSplitJoinEngine.shared.findSequentialParts(firstPartURL: url)
            joinOutputName = FileSplitJoinEngine.shared.suggestedJoinedName(firstPartURL: url)
        }
    }
    
    private func chooseJoinOutputDir() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            joinOutputDir = url
        }
    }
    
    private func startSplit() {
        guard let source = splitSourceURL else { return }
        let outDir = splitOutputDir ?? source.deletingLastPathComponent()
        let size: Int64 = useCustomSize ? Int64(customSizeMB) * 1024 * 1024 : splitPreset.rawValue
        let config = SplitConfig(sourceURL: source, destinationDirectory: outDir, chunkSize: size, generateChecksum: generateChecksum)
        
        isSplitting = true
        splitProgress = 0.0
        
        Task.detached {
            do {
                _ = try FileSplitJoinEngine.shared.splitFile(config: config) { progress, status in
                    Task { @MainActor in
                        self.splitProgress = progress
                        self.splitStatusText = status
                    }
                }
                await MainActor.run {
                    self.isSplitting = false
                    self.appState.activePane.refresh()
                    self.dismiss()
                }
            } catch {
                await MainActor.run {
                    self.isSplitting = false
                    self.splitStatusText = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func startJoin() {
        guard let firstPart = joinFirstPartURL else { return }
        let outDir = joinOutputDir ?? firstPart.deletingLastPathComponent()
        let config = JoinConfig(firstPartURL: firstPart, destinationDirectory: outDir, customOutputName: joinOutputName.isEmpty ? nil : joinOutputName)
        
        isJoining = true
        joinProgress = 0.0
        
        Task.detached {
            do {
                _ = try FileSplitJoinEngine.shared.joinFiles(config: config) { progress, status in
                    Task { @MainActor in
                        self.joinProgress = progress
                        self.joinStatusText = status
                    }
                }
                await MainActor.run {
                    self.isJoining = false
                    self.appState.activePane.refresh()
                    self.dismiss()
                }
            } catch {
                await MainActor.run {
                    self.isJoining = false
                    self.joinStatusText = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
