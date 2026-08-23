import SwiftUI
import fxfileCore
import fxfileLocalization
import fxfileState

@MainActor
public struct DirectorySyncSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    
    @State private var sourceURL: URL?
    @State private var targetURL: URL?
    @State private var direction: SyncDirection = .sourceToTargetUpdate
    @State private var recursive: Bool = true
    
    @State private var syncItems: [SyncItem] = []
    @State private var isComparing: Bool = false
    @State private var isSyncing: Bool = false
    @State private var progressValue: Double = 0.0
    @State private var statusMessage: String = ""
    
    public init(appState: AppState, source: URL? = nil, target: URL? = nil) {
        self.appState = appState
        self._sourceURL = State(initialValue: source ?? appState.leftPane.currentURL)
        self._targetURL = State(initialValue: target ?? appState.rightPane.currentURL)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n("sync.title"))
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
            
            // Configuration controls
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(L10n("sync.source"))
                        .frame(width: 120, alignment: .trailing)
                    Text(sourceURL?.path ?? "None")
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Select...") {
                        selectFolder { sourceURL = $0 }
                    }
                }
                
                HStack {
                    Text(L10n("sync.target"))
                        .frame(width: 120, alignment: .trailing)
                    Text(targetURL?.path ?? "None")
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Select...") {
                        selectFolder { targetURL = $0 }
                    }
                }
                
                HStack {
                    Text(L10n("sync.direction"))
                        .frame(width: 120, alignment: .trailing)
                    Picker("", selection: $direction) {
                        ForEach(SyncDirection.allCases) { dir in
                            Text(dir.rawValue).tag(dir)
                        }
                    }
                    .frame(width: 260)
                    
                    Toggle(L10n("sync.include_subfolders"), isOn: $recursive)
                        .padding(.leading, 12)
                    
                    Spacer()
                    
                    Button(L10n("action.compare")) {
                        startCompare()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(sourceURL == nil || targetURL == nil || isComparing || isSyncing)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 8)
            
            if isComparing || isSyncing {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: progressValue, total: 1.0)
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            // Comparison Results Table
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Comparison Results: (\(syncItems.count) items)")
                        .font(.headline)
                    Spacer()
                    if !syncItems.isEmpty {
                        Button("Select All") {
                            for i in 0..<syncItems.count { syncItems[i].isSelected = true }
                        }
                        Button("Deselect All") {
                            for i in 0..<syncItems.count { syncItems[i].isSelected = false }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Table(syncItems) {
                    TableColumn("Sync") { item in
                        Toggle("", isOn: Binding(
                            get: { item.isSelected },
                            set: { newVal in
                                if let idx = syncItems.firstIndex(where: { $0.id == item.id }) {
                                    syncItems[idx].isSelected = newVal
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                    .width(40)
                    
                    TableColumn("Relative Path") { item in
                        Text(item.relativePath)
                            .lineLimit(1)
                    }
                    
                    TableColumn("Status") { item in
                        Text(item.status.rawValue)
                            .font(.caption.bold())
                            .foregroundColor(statusColor(item.status))
                    }
                    .width(140)
                    
                    TableColumn("Action") { item in
                        Text(item.action.rawValue)
                            .font(.caption)
                    }
                    .width(140)
                    
                    TableColumn("Source Size") { item in
                        Text(item.sourceSize.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) } ?? "--")
                    }
                    .width(90)
                    
                    TableColumn("Target Size") { item in
                        Text(item.targetSize.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) } ?? "--")
                    }
                    .width(90)
                }
                .frame(minHeight: 220)
            }
            
            Divider()
            
            // Footer Actions
            HStack {
                Button(L10n("action.cancel")) {
                    dismiss()
                }
                Spacer()
                
                let activeCount = syncItems.filter { $0.isSelected && $0.action != .skip }.count
                Button("\(L10n("sync.start_btn")) (\(activeCount))") {
                    startSync()
                }
                .buttonStyle(.borderedProminent)
                .disabled(activeCount == 0 || isSyncing || isComparing)
            }
            .padding()
        }
        .frame(minWidth: 740, minHeight: 540)
    }
    
    private func statusColor(_ status: SyncStatus) -> Color {
        switch status {
        case .missingInTarget, .missingInSource: return .orange
        case .newerInSource, .newerInTarget: return .blue
        case .differentSize: return .purple
        case .equal: return .secondary
        }
    }
    
    private func selectFolder(completion: @escaping (URL) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            completion(url)
        }
    }
    
    private func startCompare() {
        guard let src = sourceURL, let tgt = targetURL else { return }
        isComparing = true
        progressValue = 0.0
        syncItems.removeAll()
        
        let dir = self.direction
        let rec = self.recursive
        
        Task.detached {
            do {
                let items = try DirectorySyncEngine.shared.compareDirectories(
                    source: src,
                    target: tgt,
                    direction: dir,
                    recursive: rec
                ) { frac, status in
                    Task { @MainActor in
                        self.progressValue = frac
                        self.statusMessage = status
                    }
                }
                
                await MainActor.run {
                    self.syncItems = items
                    self.isComparing = false
                }
            } catch {
                await MainActor.run {
                    self.isComparing = false
                    self.statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func startSync() {
        guard let src = sourceURL, let tgt = targetURL else { return }
        isSyncing = true
        progressValue = 0.0
        
        let itemsToSync = self.syncItems
        
        Task.detached {
            do {
                try DirectorySyncEngine.shared.executeSync(
                    items: itemsToSync,
                    sourceBase: src,
                    targetBase: tgt
                ) { current, total, status in
                    Task { @MainActor in
                        self.progressValue = total > 0 ? Double(current) / Double(total) : 1.0
                        self.statusMessage = status
                    }
                }
                
                await MainActor.run {
                    self.isSyncing = false
                    self.appState.leftPane.refresh()
                    self.appState.rightPane.refresh()
                    self.dismiss()
                }
            } catch {
                await MainActor.run {
                    self.isSyncing = false
                    self.statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
