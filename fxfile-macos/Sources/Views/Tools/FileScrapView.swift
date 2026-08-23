import SwiftUI
import fxfileCore
import fxfileLocalization
import fxfileState

@MainActor
public struct FileScrapView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    
    @State private var selectedScrapIDs: Set<UUID> = []
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n("scrap.title"))
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
            
            // Actions Toolbar
            HStack(spacing: 12) {
                Button(action: { addFilesViaDialog() }) {
                    Label("Add Files...", systemImage: "plus")
                }
                
                Button(action: {
                    let selected = appState.fileScrapItems.filter { selectedScrapIDs.contains($0.id) }
                    appState.removeFromScrap(files: selected)
                    selectedScrapIDs.removeAll()
                }) {
                    Label("Remove from Basket", systemImage: "minus.circle")
                }
                .disabled(selectedScrapIDs.isEmpty)
                
                Button(action: {
                    appState.clearScrap()
                    selectedScrapIDs.removeAll()
                }) {
                    Label(L10n("scrap.clear_all"), systemImage: "trash")
                }
                .disabled(appState.fileScrapItems.isEmpty)
                
                Spacer()
                
                Button(action: { copyPathsToClipboard() }) {
                    Label("Copy Paths", systemImage: "doc.on.doc")
                }
                .disabled(appState.fileScrapItems.isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            // Scrap List Table
            if appState.fileScrapItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(L10n("scrap.empty"))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(appState.fileScrapItems, selection: $selectedScrapIDs) {
                    TableColumn("Name") { item in
                        HStack(spacing: 6) {
                            Image(nsImage: item.icon)
                                .resizable()
                                .frame(width: 16, height: 16)
                            Text(item.name)
                                .fontWeight(.medium)
                        }
                    }
                    TableColumn("Original Path") { item in
                        Text(item.path)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    TableColumn("Size") { item in
                        Text(item.formattedSize)
                    }
                    .width(90)
                    TableColumn("Modified") { item in
                        Text(item.formattedDate)
                    }
                    .width(130)
                }
            }
            
            Divider()
            
            // Footer Execution Buttons
            HStack {
                Text("\(appState.fileScrapItems.count) files in basket")
                    .foregroundColor(.secondary)
                    .font(.callout)
                
                Spacer()
                
                Button(L10n("scrap.move_all")) {
                    appState.moveScrapToActivePane()
                    dismiss()
                }
                .disabled(appState.fileScrapItems.isEmpty)
                
                Button(L10n("scrap.copy_all")) {
                    appState.copyScrapToActivePane()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.fileScrapItems.isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 680, minHeight: 460)
    }
    
    private func addFilesViaDialog() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        if panel.runModal() == .OK {
            let items = panel.urls.map { FileItem(url: $0) }
            appState.addToScrap(files: items)
        }
    }
    
    private func copyPathsToClipboard() {
        let paths = appState.fileScrapItems.map { $0.path }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(paths, forType: .string)
    }
}
