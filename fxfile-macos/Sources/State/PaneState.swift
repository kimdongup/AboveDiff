import Foundation
import SwiftUI
import fxfileCore
import fxfileLocalization

public enum FileViewMode: String, CaseIterable, Identifiable, Codable {
    case detailsTable
    case iconsGrid
    case list
    
    public var id: String { rawValue }
}

public struct TabItem: Identifiable, Hashable, Equatable {
    public let id: UUID
    public var title: String
    public var url: URL
    public var history: [URL]
    public var historyIndex: Int
    
    public init(id: UUID = UUID(), url: URL) {
        self.id = id
        self.url = url
        self.title = url.lastPathComponent.isEmpty ? "Macintosh HD" : url.lastPathComponent
        self.history = [url]
        self.historyIndex = 0
    }
}

@MainActor
public final class PaneState: ObservableObject, Identifiable {
    public let id = UUID()
    
    @Published public var tabs: [TabItem] = []
    @Published public var activeTabIndex: Int = 0
    @Published public var files: [FileItem] = []
    @Published public var isLoading: Bool = false
    @Published public var selectedItemIDs: Set<UUID> = []
    @Published public var sortField: FileSortField = .name {
        didSet { reloadSort() }
    }
    @Published public var sortAscending: Bool = true {
        didSet { reloadSort() }
    }
    @Published public var showHiddenFiles: Bool = false {
        didSet { refresh() }
    }
    @Published public var filterQuery: String = "" {
        didSet { refresh() }
    }
    @Published public var viewMode: FileViewMode = .detailsTable
    @Published public var statusMessage: String = ""
    
    public var currentTab: TabItem {
        guard !tabs.isEmpty, activeTabIndex >= 0, activeTabIndex < tabs.count else {
            return TabItem(url: FileManager.default.homeDirectoryForCurrentUser)
        }
        return tabs[activeTabIndex]
    }
    
    public var currentURL: URL {
        currentTab.url
    }
    
    public var selectedFiles: [FileItem] {
        files.filter { selectedItemIDs.contains($0.id) }
    }
    
    public var canGoBack: Bool {
        guard !tabs.isEmpty, activeTabIndex < tabs.count else { return false }
        return tabs[activeTabIndex].historyIndex > 0
    }
    
    public var canGoForward: Bool {
        guard !tabs.isEmpty, activeTabIndex < tabs.count else { return false }
        return tabs[activeTabIndex].historyIndex < tabs[activeTabIndex].history.count - 1
    }
    
    public var canGoUp: Bool {
        return currentURL.path != "/" && currentURL.path != ""
    }
    
    public init(initialURL: URL = FileManager.default.homeDirectoryForCurrentUser) {
        let firstTab = TabItem(url: initialURL)
        self.tabs = [firstTab]
        self.activeTabIndex = 0
        self.refresh()
    }
    
    // MARK: - Navigation
    
    public func navigateTo(url: URL) {
        let standardURL = url.standardizedFileURL
        guard activeTabIndex >= 0, activeTabIndex < tabs.count else { return }
        
        var tab = tabs[activeTabIndex]
        // If navigating to different URL, trim forward history and append
        if tab.url.path != standardURL.path {
            if tab.historyIndex < tab.history.count - 1 {
                tab.history = Array(tab.history.prefix(tab.historyIndex + 1))
            }
            tab.history.append(standardURL)
            tab.historyIndex = tab.history.count - 1
            tab.url = standardURL
            tab.title = standardURL.lastPathComponent.isEmpty ? "/" : standardURL.lastPathComponent
            tabs[activeTabIndex] = tab
        }
        
        selectedItemIDs.removeAll()
        refresh()
    }
    
    public func goBack() {
        guard canGoBack else { return }
        tabs[activeTabIndex].historyIndex -= 1
        let prevURL = tabs[activeTabIndex].history[tabs[activeTabIndex].historyIndex]
        tabs[activeTabIndex].url = prevURL
        tabs[activeTabIndex].title = prevURL.lastPathComponent.isEmpty ? "/" : prevURL.lastPathComponent
        selectedItemIDs.removeAll()
        refresh()
    }
    
    public func goForward() {
        guard canGoForward else { return }
        tabs[activeTabIndex].historyIndex += 1
        let nextURL = tabs[activeTabIndex].history[tabs[activeTabIndex].historyIndex]
        tabs[activeTabIndex].url = nextURL
        tabs[activeTabIndex].title = nextURL.lastPathComponent.isEmpty ? "/" : nextURL.lastPathComponent
        selectedItemIDs.removeAll()
        refresh()
    }
    
    public func goUp() {
        guard canGoUp else { return }
        let parentURL = currentURL.deletingLastPathComponent()
        navigateTo(url: parentURL)
    }
    
    public func refresh() {
        let url = currentURL
        isLoading = true
        
        Task {
            do {
                let items = try FileSystemService.shared.contentsOfDirectory(
                    at: url,
                    showHidden: self.showHiddenFiles,
                    sortField: self.sortField,
                    sortAscending: self.sortAscending,
                    filter: self.filterQuery.isEmpty ? nil : self.filterQuery
                )
                
                let diskSpace = FileSystemService.shared.getDiskSpace(for: url)
                
                await MainActor.run {
                    self.files = items
                    self.isLoading = false
                    self.updateStatusMessage(freeSpaceStr: diskSpace.formattedFree)
                }
            } catch {
                await MainActor.run {
                    self.files = []
                    self.isLoading = false
                    self.statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func reloadSort() {
        self.files = FileSystemService.shared.sortItems(self.files, by: self.sortField, ascending: self.sortAscending)
    }
    
    public func updateStatusMessage(freeSpaceStr: String? = nil) {
        let totalCount = files.count
        let selCount = selectedItemIDs.count
        let selBytes = selectedFiles.reduce(0) { $0 + $1.size }
        let selSizeStr = ByteCountFormatter.string(fromByteCount: selBytes, countStyle: .file)
        
        let freeStr = freeSpaceStr ?? FileSystemService.shared.getDiskSpace(for: currentURL).formattedFree
        
        if selCount > 0 {
            statusMessage = "\(totalCount) \(L10n("status.items")) | \(selCount) \(L10n("status.selected")) (\(selSizeStr)) | \(L10n("status.free")): \(freeStr)"
        } else {
            statusMessage = "\(totalCount) \(L10n("status.items")) | \(L10n("status.free")): \(freeStr)"
        }
    }
    
    // MARK: - Tab Management
    
    public func addTab(url: URL? = nil) {
        let targetURL = url ?? currentURL
        let newTab = TabItem(url: targetURL)
        tabs.append(newTab)
        activeTabIndex = tabs.count - 1
        refresh()
    }
    
    public func closeTab(at index: Int) {
        guard tabs.count > 1, index >= 0, index < tabs.count else { return }
        tabs.remove(at: index)
        if activeTabIndex >= tabs.count {
            activeTabIndex = tabs.count - 1
        }
        refresh()
    }
    
    public func selectTab(at index: Int) {
        guard index >= 0, index < tabs.count else { return }
        activeTabIndex = index
        refresh()
    }
    
    // MARK: - Selection
    
    public func selectAll() {
        selectedItemIDs = Set(files.map { $0.id })
        updateStatusMessage()
    }
    
    public func clearSelection() {
        selectedItemIDs.removeAll()
        updateStatusMessage()
    }
    
    public func invertSelection() {
        let allIDs = Set(files.map { $0.id })
        selectedItemIDs = allIDs.subtracting(selectedItemIDs)
        updateStatusMessage()
    }
}
