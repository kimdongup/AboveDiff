import SwiftUI
import fxfileCore
import fxfileLocalization
import fxfileState

@MainActor
public struct FunctionKeysBar: View {
    @ObservedObject var appState: AppState
    @State private var showingNewFolderDialog = false
    @State private var newFolderName = "New Folder"
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        HStack(spacing: 2) {
            fButton(key: "F2", title: L10n("action.rename"), shortcut: .init("2", modifiers: [])) {
                if let first = appState.activePane.selectedFiles.first {
                    appState.activeToolSheet = .batchRename(files: [first])
                }
            }
            
            fButton(key: "F3", title: L10n("action.quick_look"), shortcut: .init("3", modifiers: [])) {
                if let first = appState.activePane.selectedFiles.first {
                    FileSystemService.shared.openWithDefaultApp(url: first.url)
                }
            }
            
            fButton(key: "F4", title: L10n("action.open"), shortcut: .init("4", modifiers: [])) {
                if let first = appState.activePane.selectedFiles.first {
                    FileSystemService.shared.openWithDefaultApp(url: first.url)
                }
            }
            
            fButton(key: "F5", title: L10n("action.copy"), shortcut: .init("5", modifiers: [])) {
                if appState.dualPaneEnabled {
                    appState.copyActiveToInactive()
                } else {
                    appState.performCopy()
                }
            }
            
            fButton(key: "F6", title: L10n("action.move_to_other_pane"), shortcut: .init("6", modifiers: [])) {
                if appState.dualPaneEnabled {
                    appState.moveActiveToInactive()
                } else {
                    appState.performCut()
                }
            }
            
            fButton(key: "F7", title: L10n("action.new_folder"), shortcut: .init("7", modifiers: [])) {
                showingNewFolderDialog = true
            }
            
            fButton(key: "F8", title: L10n("action.delete"), shortcut: .init("8", modifiers: [])) {
                appState.deleteSelected(pane: appState.activePane, permanently: false)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(Color(NSColor.windowBackgroundColor))
        .alert(L10n("action.new_folder"), isPresented: $showingNewFolderDialog) {
            TextField(L10n("prompt.new_folder"), text: $newFolderName)
            Button(L10n("action.ok")) {
                _ = try? FileSystemService.shared.createFolder(at: appState.activePane.currentURL, name: newFolderName)
                appState.activePane.refresh()
                newFolderName = "New Folder"
            }
            Button(L10n("action.cancel"), role: .cancel) {}
        } message: {
            Text(L10n("prompt.new_folder"))
        }
    }
    
    @ViewBuilder
    private func fButton(key: String, title: String, shortcut: KeyboardShortcut, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(key)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.accentColor.opacity(0.85))
                    .cornerRadius(3)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}
