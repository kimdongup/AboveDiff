import Foundation
import SwiftUI
import AppKit
import AboveDiffCore
import AboveDiffLocalization

public struct BookmarkItem: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var url: URL
    
    public init(id: UUID = UUID(), name: String, url: URL) {
        self.id = id
        self.name = name
        self.url = url
    }
}

public enum ToolSheetType: Identifiable, Equatable {
    case batchRename(files: [FileItem])
    case checksum(files: [FileItem])
    case fileSplitJoin(file: FileItem?)
    case directorySync(source: URL?, target: URL?)
    case fileSearch(root: URL?)
    case fileScrap
    case batchCreate(parent: URL)
    case fileProperties(file: FileItem)
    case preferences
    case folderCompare(left: URL?, right: URL?)

    public var id: String {
        switch self {
        case .batchRename: return "batchRename"
        case .checksum: return "checksum"
        case .fileSplitJoin: return "fileSplitJoin"
        case .directorySync: return "directorySync"
        case .fileSearch: return "fileSearch"
        case .fileScrap: return "fileScrap"
        case .batchCreate: return "batchCreate"
        case .fileProperties: return "fileProperties"
        case .preferences: return "preferences"
        case .folderCompare: return "folderCompare"
        }
    }
    
    public static func == (lhs: ToolSheetType, rhs: ToolSheetType) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
public final class AppState: ObservableObject {
    @AppStorage("abovediff_dual_pane_enabled") public var dualPaneEnabled: Bool = true
    @Published public var dualPaneOrientation: Axis = .horizontal
    @Published public var activePaneIndex: Int = 0 // 0 = left/top, 1 = right/bottom
    
    @Published public var leftPane: PaneState
    @Published public var rightPane: PaneState
    
    @Published public var fileScrapItems: [FileItem] = []
    @Published public var bookmarks: [BookmarkItem] = []
    
    @Published public var activeToolSheet: ToolSheetType? = nil
    
    @AppStorage("abovediff_confirm_delete") public var confirmBeforeDelete: Bool = true
    @AppStorage("abovediff_show_hidden_global") public var showHiddenFilesGlobal: Bool = false {
        didSet {
            leftPane.showHiddenFiles = showHiddenFilesGlobal
            rightPane.showHiddenFiles = showHiddenFilesGlobal
        }
    }
    
    // Internal clipboard
    @Published public var clipboardURLs: [URL] = []
    @Published public var clipboardIsCut: Bool = false
    
    public var activePane: PaneState {
        if !dualPaneEnabled || activePaneIndex == 0 {
            return leftPane
        } else {
            return rightPane
        }
    }
    
    public var inactivePane: PaneState {
        if !dualPaneEnabled || activePaneIndex == 0 {
            return rightPane
        } else {
            return leftPane
        }
    }
    
    public init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? home
        
        self.leftPane = PaneState(initialURL: home)
        self.rightPane = PaneState(initialURL: docs)
        
        loadDefaultBookmarks()
    }
    
    private func loadDefaultBookmarks() {
        let fm = FileManager.default
        var defaults: [BookmarkItem] = []
        
        let home = fm.homeDirectoryForCurrentUser
        defaults.append(BookmarkItem(name: "Home", url: home))
        
        if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
            defaults.append(BookmarkItem(name: "Documents", url: docs))
        }
        if let downloads = fm.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            defaults.append(BookmarkItem(name: "Downloads", url: downloads))
        }
        if let desktop = fm.urls(for: .desktopDirectory, in: .userDomainMask).first {
            defaults.append(BookmarkItem(name: "Desktop", url: desktop))
        }
        
        self.bookmarks = defaults
    }
    
    // MARK: - Pane Switching & Operations
    
    public func switchActivePane() {
        activePaneIndex = activePaneIndex == 0 ? 1 : 0
    }
    
    public func swapPanes() {
        let leftURL = leftPane.currentURL
        let rightURL = rightPane.currentURL
        leftPane.navigateTo(url: rightURL)
        rightPane.navigateTo(url: leftURL)
    }
    
    public func copyActiveToInactive() {
        guard dualPaneEnabled else { return }
        let sources = activePane.selectedFiles.map { $0.url }
        guard !sources.isEmpty else { return }
        let dest = inactivePane.currentURL
        
        Task {
            do {
                try FileSystemService.shared.copyItems(sources: sources, destinationDirectory: dest)
                await MainActor.run {
                    self.inactivePane.refresh()
                }
            } catch {
                print("Error copying items: \(error)")
            }
        }
    }
    
    public func moveActiveToInactive() {
        guard dualPaneEnabled else { return }
        let sources = activePane.selectedFiles.map { $0.url }
        guard !sources.isEmpty else { return }
        let dest = inactivePane.currentURL
        
        Task {
            do {
                try FileSystemService.shared.moveItems(sources: sources, destinationDirectory: dest)
                await MainActor.run {
                    self.activePane.refresh()
                    self.inactivePane.refresh()
                }
            } catch {
                print("Error moving items: \(error)")
            }
        }
    }
    
    // MARK: - File Scrap Basket
    
    public func addToScrap(files: [FileItem]) {
        for file in files {
            if !fileScrapItems.contains(where: { $0.url == file.url }) {
                fileScrapItems.append(file)
            }
        }
    }
    
    public func removeFromScrap(files: [FileItem]) {
        let urlsToRemove = Set(files.map { $0.url })
        fileScrapItems.removeAll { urlsToRemove.contains($0.url) }
    }
    
    public func clearScrap() {
        fileScrapItems.removeAll()
    }
    
    public func copyScrapToActivePane() {
        let sources = fileScrapItems.map { $0.url }
        guard !sources.isEmpty else { return }
        let dest = activePane.currentURL
        Task {
            do {
                try FileSystemService.shared.copyItems(sources: sources, destinationDirectory: dest)
                await MainActor.run {
                    self.activePane.refresh()
                }
            } catch {
                print("Error copying scrap items: \(error)")
            }
        }
    }
    
    public func moveScrapToActivePane() {
        let sources = fileScrapItems.map { $0.url }
        guard !sources.isEmpty else { return }
        let dest = activePane.currentURL
        Task {
            do {
                try FileSystemService.shared.moveItems(sources: sources, destinationDirectory: dest)
                await MainActor.run {
                    self.fileScrapItems.removeAll()
                    self.activePane.refresh()
                }
            } catch {
                print("Error moving scrap items: \(error)")
            }
        }
    }
    
    // MARK: - Bookmarks
    
    public func addBookmark(name: String, url: URL) {
        bookmarks.append(BookmarkItem(name: name, url: url))
    }
    
    public func removeBookmark(id: UUID) {
        bookmarks.removeAll { $0.id == id }
    }
    
    // MARK: - Clipboard Operations
    
    public func performCopy() {
        let selected = activePane.selectedFiles.map { $0.url }
        guard !selected.isEmpty else { return }
        clipboardURLs = selected
        clipboardIsCut = false
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(selected as [NSURL])
    }
    
    public func performCut() {
        let selected = activePane.selectedFiles.map { $0.url }
        guard !selected.isEmpty else { return }
        clipboardURLs = selected
        clipboardIsCut = true
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(selected as [NSURL])
    }
    
    public func performPaste(in targetDirectory: URL) {
        guard !clipboardURLs.isEmpty else { return }
        let sources = clipboardURLs
        let isCut = clipboardIsCut
        
        Task {
            do {
                if isCut {
                    try FileSystemService.shared.moveItems(sources: sources, destinationDirectory: targetDirectory)
                    await MainActor.run {
                        self.clipboardURLs.removeAll()
                        self.clipboardIsCut = false
                        self.leftPane.refresh()
                        self.rightPane.refresh()
                    }
                } else {
                    try FileSystemService.shared.copyItems(sources: sources, destinationDirectory: targetDirectory)
                    await MainActor.run {
                        self.activePane.refresh()
                    }
                }
            } catch {
                print("Error pasting items: \(error)")
            }
        }
    }
    
    public func deleteSelected(pane: PaneState, permanently: Bool = false) {
        let urls = pane.selectedFiles.map { $0.url }
        guard !urls.isEmpty else { return }
        
        Task {
            do {
                if permanently {
                    try FileSystemService.shared.deleteItemsPermanently(urls: urls)
                } else {
                    try FileSystemService.shared.trashItems(urls: urls)
                }
                await MainActor.run {
                    pane.selectedItemIDs.removeAll()
                    pane.refresh()
                }
            } catch {
                print("Error deleting items: \(error)")
            }
        }
    }
}
