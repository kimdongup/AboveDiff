import SwiftUI
import fxfileCore
import fxfileLocalization
import fxfileState

@MainActor
public struct ToolbarView: ToolbarContent {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some ToolbarContent {
        // Dual Pane & Layout Group
        ToolbarItemGroup(placement: .navigation) {
            Button(action: {
                appState.dualPaneEnabled.toggle()
            }) {
                Label(appState.dualPaneEnabled ? L10n("view.single_pane") : L10n("view.dual_pane"),
                      systemImage: appState.dualPaneEnabled ? "rectangle.split.2x1" : "rectangle")
            }
            .help(appState.dualPaneEnabled ? "Switch to Single Pane" : "Switch to Dual Pane")
            
            if appState.dualPaneEnabled {
                Button(action: {
                    appState.dualPaneOrientation = appState.dualPaneOrientation == .horizontal ? .vertical : .horizontal
                }) {
                    Label("Toggle Split Orientation",
                          systemImage: appState.dualPaneOrientation == .horizontal ? "rectangle.split.2x1.fill" : "rectangle.split.1x2.fill")
                }
                .help("Toggle Horizontal / Vertical Split")
                
                Button(action: {
                    appState.swapPanes()
                }) {
                    Label("Swap Panes", systemImage: "arrow.left.arrow.right")
                }
                .help("Swap Left and Right Panes")
            }
        }
        
        // Power Tools Group
        ToolbarItemGroup(placement: .primaryAction) {
            // Batch Rename
            Button(action: {
                let selected = appState.activePane.selectedFiles
                appState.activeToolSheet = .batchRename(files: selected.isEmpty ? appState.activePane.files : selected)
            }) {
                Label(L10n("action.batch_rename"), systemImage: "pencil.and.outline")
            }
            .help(L10n("rename.title"))
            
            // Search
            Button(action: {
                appState.activeToolSheet = .fileSearch(root: appState.activePane.currentURL)
            }) {
                Label(L10n("action.search"), systemImage: "magnifyingglass")
            }
            .help(L10n("search.title"))
            
            // Checksum
            Button(action: {
                appState.activeToolSheet = .checksum(files: appState.activePane.selectedFiles)
            }) {
                Label(L10n("action.calculate_checksum"), systemImage: "number.square")
            }
            .help(L10n("checksum.title"))
            
            // Split & Join
            Button(action: {
                appState.activeToolSheet = .fileSplitJoin(file: appState.activePane.selectedFiles.first)
            }) {
                Label(L10n("action.split_join"), systemImage: "scissors.circle")
            }
            .help(L10n("splitjoin.title"))
           
        //추가중
	Button(action: {
	    appState.activeToolSheet = .folderCompare(
		left: appState.leftPane.currentURL,
		right: appState.rightPane.currentURL
	    )
	}) {
	    Label("Compare Panes", systemImage: "rectangle.split.2x1")
	}
	.help("Compare current left and right folders")
	.disabled(!appState.dualPaneEnabled)

            // Directory Sync
            Button(action: {
                appState.activeToolSheet = .directorySync(
                    source: appState.leftPane.currentURL,
                    target: appState.rightPane.currentURL
                )
            }) {
                Label(L10n("action.sync_folders"), systemImage: "arrow.triangle.2.circlepath")
            }
            .help(L10n("sync.title"))
            
            // Batch Create
            Button(action: {
                appState.activeToolSheet = .batchCreate(parent: appState.activePane.currentURL)
            }) {
                Label(L10n("action.batch_create"), systemImage: "plus.rectangle.on.rectangle")
            }
            .help(L10n("batchcreate.title"))
            
            // File Scrap Basket
            Button(action: {
                appState.activeToolSheet = .fileScrap
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "tray.fill")
                    if !appState.fileScrapItems.isEmpty {
                        Text("\(appState.fileScrapItems.count)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
            }
            .help(L10n("scrap.title"))
            
            // Hidden Files Toggle
            Button(action: {
                appState.showHiddenFilesGlobal.toggle()
            }) {
                Label("Toggle Hidden Files",
                      systemImage: appState.showHiddenFilesGlobal ? "eye.fill" : "eye.slash")
            }
            .help(appState.showHiddenFilesGlobal ? L10n("view.hide_hidden") : L10n("view.show_hidden"))
        }
    }
}
