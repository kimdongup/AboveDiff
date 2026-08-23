import SwiftUI
import fxfileCore
import fxfileLocalization
import fxfileState
import fxfileViews

@main
struct fxfileApp: App {
    @StateObject private var appState = AppState()
    @ObservedObject private var locManager = LocalizationManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainWindow(appState: appState)
                .environmentObject(appState)
                .environmentObject(locManager)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            // File Menu
            CommandGroup(replacing: .newItem) {
                Button(L10n("action.new_tab")) {
                    appState.activePane.addTab()
                }
                .keyboardShortcut("t", modifiers: .command)
                
                Button(L10n("action.close_tab")) {
                    appState.activePane.closeTab(at: appState.activePane.activeTabIndex)
                }
                .keyboardShortcut("w", modifiers: .command)
                .disabled(appState.activePane.tabs.count <= 1)
                
                Divider()
                
                Button(L10n("action.new_folder")) {
                    _ = try? FileSystemService.shared.createFolder(at: appState.activePane.currentURL, name: "New Folder")
                    appState.activePane.refresh()
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                
                Button(L10n("action.new_file")) {
                    _ = try? FileSystemService.shared.createTextFile(at: appState.activePane.currentURL, name: "New File.txt", content: "")
                    appState.activePane.refresh()
                }
                .keyboardShortcut("n", modifiers: [.command, .option])
            }
            
            CommandGroup(after: .newItem) {
                Divider()
                
                Button(L10n("action.duplicate")) {
                    for file in appState.activePane.selectedFiles {
                        _ = try? FileSystemService.shared.duplicateItem(at: file.url)
                    }
                    appState.activePane.refresh()
                }
                .keyboardShortcut("d", modifiers: .command)
                .disabled(appState.activePane.selectedFiles.isEmpty)
                
                Button(L10n("action.properties")) {
                    if let first = appState.activePane.selectedFiles.first {
                        appState.activeToolSheet = .fileProperties(file: first)
                    }
                }
                .keyboardShortcut("i", modifiers: .command)
                .disabled(appState.activePane.selectedFiles.isEmpty)
                
                Divider()
                
                Button(L10n("action.move_to_trash")) {
                    appState.deleteSelected(pane: appState.activePane, permanently: false)
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(appState.activePane.selectedFiles.isEmpty)
                
                Button(L10n("action.delete_permanently")) {
                    appState.deleteSelected(pane: appState.activePane, permanently: true)
                }
                .keyboardShortcut(.delete, modifiers: [.command, .option])
                .disabled(appState.activePane.selectedFiles.isEmpty)
            }
            
            // Edit Menu
            CommandGroup(replacing: .pasteboard) {
                Button(L10n("action.cut")) {
                    appState.performCut()
                }
                .keyboardShortcut("x", modifiers: .command)
                .disabled(appState.activePane.selectedFiles.isEmpty)
                
                Button(L10n("action.copy")) {
                    appState.performCopy()
                }
                .keyboardShortcut("c", modifiers: .command)
                .disabled(appState.activePane.selectedFiles.isEmpty)
                
                Button(L10n("action.paste")) {
                    appState.performPaste(in: appState.activePane.currentURL)
                }
                .keyboardShortcut("v", modifiers: .command)
                .disabled(appState.clipboardURLs.isEmpty)
                
                Divider()
                
                if appState.dualPaneEnabled {
                    Button(L10n("action.copy_to_other_pane")) {
                        appState.copyActiveToInactive()
                    }
                    .keyboardShortcut("5", modifiers: .command)
                    .disabled(appState.activePane.selectedFiles.isEmpty)
                    
                    Button(L10n("action.move_to_other_pane")) {
                        appState.moveActiveToInactive()
                    }
                    .keyboardShortcut("6", modifiers: .command)
                    .disabled(appState.activePane.selectedFiles.isEmpty)
                    
                    Divider()
                }
                
                Button(L10n("action.select_all")) {
                    appState.activePane.selectAll()
                }
                .keyboardShortcut("a", modifiers: .command)
                
                Button(L10n("action.invert_selection")) {
                    appState.activePane.invertSelection()
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])
                
                Button(L10n("action.copy_path")) {
                    let paths = appState.activePane.selectedFiles.map { $0.path }.joined(separator: "\n")
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(paths, forType: .string)
                }
                .keyboardShortcut("c", modifiers: [.command, .option])
                .disabled(appState.activePane.selectedFiles.isEmpty)
            }
            
            // View Menu
            CommandGroup(after: .sidebar) {
                Divider()
                
                Button(appState.dualPaneEnabled ? L10n("view.single_pane") : L10n("view.dual_pane")) {
                    appState.dualPaneEnabled.toggle()
                }
                .keyboardShortcut("2", modifiers: .command)
                
                if appState.dualPaneEnabled {
                    Button("Switch Active Pane (Tab)") {
                        appState.switchActivePane()
                    }
                    .keyboardShortcut(.tab, modifiers: [])
                    
                    Button(appState.dualPaneOrientation == .horizontal ? L10n("view.split_vertical") : L10n("view.split_horizontal")) {
                        appState.dualPaneOrientation = appState.dualPaneOrientation == .horizontal ? .vertical : .horizontal
                    }
                    
                    Button("Swap Panes") {
                        appState.swapPanes()
                    }
                    .keyboardShortcut("u", modifiers: .command)
                }
                
                Divider()
                
                Button(appState.showHiddenFilesGlobal ? L10n("view.hide_hidden") : L10n("view.show_hidden")) {
                    appState.showHiddenFilesGlobal.toggle()
                }
                .keyboardShortcut(".", modifiers: [.command, .shift])
                
                Button(L10n("action.refresh")) {
                    appState.activePane.refresh()
                }
                .keyboardShortcut("r", modifiers: .command)
            }
            
            // Go Menu
            CommandMenu(L10n("menu.go")) {
                Button("Back") {
                    appState.activePane.goBack()
                }
                .keyboardShortcut("[", modifiers: .command)
                .disabled(!appState.activePane.canGoBack)
                
                Button("Forward") {
                    appState.activePane.goForward()
                }
                .keyboardShortcut("]", modifiers: .command)
                .disabled(!appState.activePane.canGoForward)
                
                Button("Enclosing Folder") {
                    appState.activePane.goUp()
                }
                .keyboardShortcut(.upArrow, modifiers: .command)
                .disabled(!appState.activePane.canGoUp)
                
                Divider()
                
                Button(L10n("sidebar.home")) {
                    appState.activePane.navigateTo(url: FileManager.default.homeDirectoryForCurrentUser)
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])
                
                if let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
                    Button(L10n("sidebar.desktop")) {
                        appState.activePane.navigateTo(url: desktop)
                    }
                    .keyboardShortcut("d", modifiers: [.command, .shift])
                }
                
                if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    Button(L10n("sidebar.documents")) {
                        appState.activePane.navigateTo(url: docs)
                    }
                    .keyboardShortcut("o", modifiers: [.command, .shift])
                }
                
                if let dl = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
                    Button(L10n("sidebar.downloads")) {
                        appState.activePane.navigateTo(url: dl)
                    }
                    .keyboardShortcut("l", modifiers: [.command, .option])
                }
                
                if let apps = FileManager.default.urls(for: .applicationDirectory, in: .systemDomainMask).first {
                    Button(L10n("sidebar.applications")) {
                        appState.activePane.navigateTo(url: apps)
                    }
                    .keyboardShortcut("a", modifiers: [.command, .shift])
                }
            }
            
            // Tools Menu
            CommandMenu(L10n("menu.tools")) {
                Button(L10n("action.batch_rename")) {
                    let selected = appState.activePane.selectedFiles
                    appState.activeToolSheet = .batchRename(files: selected.isEmpty ? appState.activePane.files : selected)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                
                Button(L10n("action.calculate_checksum")) {
                    appState.activeToolSheet = .checksum(files: appState.activePane.selectedFiles)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                
                Button(L10n("action.split_join")) {
                    appState.activeToolSheet = .fileSplitJoin(file: appState.activePane.selectedFiles.first)
                }
                .keyboardShortcut("j", modifiers: [.command, .shift])
                
                Button(L10n("action.sync_folders")) {
                    appState.activeToolSheet = .directorySync(
                        source: appState.leftPane.currentURL,
                        target: appState.rightPane.currentURL
                    )
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                
                Button(L10n("action.search")) {
                    appState.activeToolSheet = .fileSearch(root: appState.activePane.currentURL)
                }
                .keyboardShortcut("f", modifiers: .command)
                
                Button(L10n("action.scrap_basket")) {
                    appState.activeToolSheet = .fileScrap
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])
                
                Button(L10n("action.batch_create")) {
                    appState.activeToolSheet = .batchCreate(parent: appState.activePane.currentURL)
                }
                .keyboardShortcut("n", modifiers: [.command, .control])
            }
            
            // App Preferences
            CommandGroup(replacing: .appSettings) {
                Button(L10n("menu.preferences")) {
                    appState.activeToolSheet = .preferences
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
