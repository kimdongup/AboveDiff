import SwiftUI
import fxfileCore
import fxfileLocalization
import fxfileState

@MainActor
public struct MainWindow: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        NavigationSplitView {
            SidebarView(appState: appState)
        } detail: {
            VStack(spacing: 0) {
                // Main dual-pane or single-pane area
                if appState.dualPaneEnabled {
                    if appState.dualPaneOrientation == .horizontal {
                        HSplitView {
                            PaneView(appState: appState, paneState: appState.leftPane, paneIndex: 0)
                                .frame(minWidth: 260)
                            PaneView(appState: appState, paneState: appState.rightPane, paneIndex: 1)
                                .frame(minWidth: 260)
                        }
                    } else {
                        VSplitView {
                            PaneView(appState: appState, paneState: appState.leftPane, paneIndex: 0)
                                .frame(minHeight: 180)
                            PaneView(appState: appState, paneState: appState.rightPane, paneIndex: 1)
                                .frame(minHeight: 180)
                        }
                    }
                } else {
                    PaneView(appState: appState, paneState: appState.leftPane, paneIndex: 0)
                }
                
                Divider()
                
                // Classic Norton/fxfile bottom function keys bar
                FunctionKeysBar(appState: appState)
            }
        }
        .toolbar {
            ToolbarView(appState: appState)
        }
        .sheet(item: $appState.activeToolSheet) { sheetType in
            switch sheetType {
            case .batchRename(let files):
                BatchRenameSheet(appState: appState, files: files)
            case .checksum(let files):
                ChecksumSheet(appState: appState, files: files)
            case .fileSplitJoin(let file):
                FileSplitJoinSheet(appState: appState, file: file)
            case .directorySync(let source, let target):
                DirectorySyncSheet(appState: appState, source: source, target: target)
            case .fileSearch(let root):
                FileSearchSheet(appState: appState, rootURL: root)
            case .fileScrap:
                FileScrapView(appState: appState)
            case .batchCreate(let parent):
                BatchCreateSheet(appState: appState, targetDirectory: parent)
            case .fileProperties(let file):
                FilePropertiesSheet(file: file)
            case .preferences:
                PreferencesSheet(appState: appState)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}
