import SwiftUI
import fxfileCore
import fxfileLocalization
import fxfileState

@MainActor
public struct FileTableView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var paneState: PaneState
    
    @State private var sortOrder: [KeyPathComparator<FileItem>] = [
        .init(\.name, order: .forward)
    ]
    
    public init(appState: AppState, paneState: PaneState) {
        self.appState = appState
        self.paneState = paneState
    }
    
    public var body: some View {
        Table(paneState.files, selection: $paneState.selectedItemIDs, sortOrder: $sortOrder) {
            TableColumn(L10n("column.name"), value: \.name) { item in
                HStack(spacing: 6) {
                    Image(nsImage: item.icon)
                        .resizable()
                        .frame(width: 16, height: 16)
                    
                    Text(item.name)
                        .fontWeight(item.isDirectory ? .semibold : .regular)
                        .foregroundColor(item.isHidden ? .secondary : .primary)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    handleDoubleTap(on: item)
                }
                .contextMenu {
                    contextMenu(for: item)
                }
            }
            
            TableColumn(L10n("column.size"), value: \.size) { item in
                Text(item.formattedSize)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .contextMenu {
                        contextMenu(for: item)
                    }
            }
            .width(min: 80, ideal: 100, max: 130)
            
            TableColumn(L10n("column.kind"), value: \.kind) { item in
                Text(item.kind)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .contextMenu {
                        contextMenu(for: item)
                    }
            }
            .width(min: 100, ideal: 130, max: 180)
            
            TableColumn(L10n("column.date_modified"), value: \.modificationDateTimestamp) { item in
                Text(item.formattedDate)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .contextMenu {
                        contextMenu(for: item)
                    }
            }
            .width(min: 120, ideal: 140, max: 180)
            
            TableColumn(L10n("column.permissions"), value: \.permissionsString) { item in
                Text(item.permissionsString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .contextMenu {
                        contextMenu(for: item)
                    }
            }
            .width(min: 90, ideal: 100, max: 120)
        }
        .onChange(of: sortOrder) { newOrder in
            if let primary = newOrder.first {
                switch primary.keyPath {
                case \FileItem.name:
                    paneState.sortField = .name
                case \FileItem.size:
                    paneState.sortField = .size
                case \FileItem.kind:
                    paneState.sortField = .kind
                case \FileItem.modificationDateTimestamp:
                    paneState.sortField = .dateModified
                case \FileItem.permissionsString:
                    paneState.sortField = .permissions
                default:
                    break
                }
                paneState.sortAscending = primary.order == .forward
            }
        }
    }
    
    private func handleDoubleTap(on item: FileItem) {
        if item.isDirectory && !item.isPackage {
            paneState.navigateTo(url: item.url)
        } else {
            FileSystemService.shared.openWithDefaultApp(url: item.url)
        }
    }
    
    @ViewBuilder
    private func contextMenu(for item: FileItem) -> some View {
        let targets = paneState.selectedFiles.isEmpty ? [item] : paneState.selectedFiles
        
        Button(action: {
            if item.isDirectory && !item.isPackage {
                paneState.navigateTo(url: item.url)
            } else {
                FileSystemService.shared.openWithDefaultApp(url: item.url)
            }
        }) {
            Label(L10n("action.open"), systemImage: "arrow.up.forward.square")
        }
        
        Button(action: { FileSystemService.shared.revealInFinder(url: item.url) }) {
            Label(L10n("action.show_in_finder"), systemImage: "finder")
        }
        
        Button(action: { FileSystemService.shared.openTerminal(at: item.url) }) {
            Label(L10n("action.open_in_terminal"), systemImage: "terminal")
        }
        
        Divider()
        
        Button(action: { appState.performCopy() }) {
            Label(L10n("action.copy"), systemImage: "doc.on.doc")
        }
        
        Button(action: { appState.performCut() }) {
            Label(L10n("action.cut"), systemImage: "scissors")
        }
        
        Button(action: { appState.performPaste(in: paneState.currentURL) }) {
            Label(L10n("action.paste"), systemImage: "doc.on.clipboard")
        }
        
        Button(action: {
            for target in targets {
                _ = try? FileSystemService.shared.duplicateItem(at: target.url)
            }
            paneState.refresh()
        }) {
            Label(L10n("action.duplicate"), systemImage: "plus.square.on.square")
        }
        
        if appState.dualPaneEnabled {
            Divider()
            
            Button(action: { appState.copyActiveToInactive() }) {
                Label(L10n("action.copy_to_other_pane") + " (F5)", systemImage: "arrow.right.doc.on.clipboard")
            }
            
            Button(action: { appState.moveActiveToInactive() }) {
                Label(L10n("action.move_to_other_pane") + " (F6)", systemImage: "arrow.right.square")
            }
        }
        
        Divider()
        
        Button(action: {
            appState.activeToolSheet = .batchRename(files: targets)
        }) {
            Label(L10n("action.batch_rename"), systemImage: "pencil.line")
        }
        
        Button(action: {
            appState.addToScrap(files: targets)
        }) {
            Label(L10n("action.add_to_scrap"), systemImage: "tray.and.arrow.down")
        }
        
        Button(action: {
            appState.activeToolSheet = .checksum(files: targets)
        }) {
            Label(L10n("action.calculate_checksum"), systemImage: "number")
        }
        
        Button(action: {
            appState.activeToolSheet = .fileProperties(file: item)
        }) {
            Label(L10n("action.properties"), systemImage: "info.circle")
        }
        
        Divider()
        
        Button(role: .destructive, action: {
            appState.deleteSelected(pane: paneState, permanently: false)
        }) {
            Label(L10n("action.move_to_trash"), systemImage: "trash")
        }
        
        Button(role: .destructive, action: {
            appState.deleteSelected(pane: paneState, permanently: true)
        }) {
            Label(L10n("action.delete_permanently"), systemImage: "trash.slash")
        }
    }
}

extension FileItem {
    public var modificationDateTimestamp: Double {
        modificationDate?.timeIntervalSince1970 ?? 0
    }
}
