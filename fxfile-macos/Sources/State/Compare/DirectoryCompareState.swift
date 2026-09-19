import Foundation
import fxfileCore

@MainActor
public final class DirectoryCompareState: ObservableObject {
    @Published public var sourceURL: URL?
    @Published public var targetURL: URL?
    @Published public var direction: SyncDirection = .sourceToTargetUpdate
    @Published public var recursive: Bool = true
    @Published public var comparisonMode: FileComparisonMode = .smart

    @Published public private(set) var syncItems: [SyncItem] = []
    @Published public private(set) var isComparing = false
    @Published public private(set) var isSyncing = false
    @Published public private(set) var progressValue = 0.0
    @Published public private(set) var statusMessage = ""

    private let facade: DirectorySyncEngine

    public init(
        sourceURL: URL?,
        targetURL: URL?,
        facade: DirectorySyncEngine = .shared
    ) {
        self.sourceURL = sourceURL
        self.targetURL = targetURL
        self.facade = facade
    }

    public var activeCount: Int {
        syncItems.filter { $0.isSelected && $0.action != .skip }.count
    }

    public func setSelected(_ selected: Bool, id: String) {
        guard let index = syncItems.firstIndex(where: { $0.id == id }) else {
            return
        }
        syncItems[index].isSelected = selected
    }

    public func selectAll() {
        for index in syncItems.indices {
            syncItems[index].isSelected = true
        }
    }

    public func deselectAll() {
        for index in syncItems.indices {
            syncItems[index].isSelected = false
        }
    }

    public func compare() {
        guard let sourceURL, let targetURL else { return }

        isComparing = true
        progressValue = 0
        statusMessage = ""
        syncItems = []

        let direction = self.direction
        let recursive = self.recursive
        let comparisonMode = self.comparisonMode
        let facade = self.facade

        Task.detached {
            do {
                let items = try facade.compareDirectoriesWithMode(
                    source: sourceURL,
                    target: targetURL,
                    direction: direction,
                    recursive: recursive,
                    comparisonMode: comparisonMode
                ) { fraction, message in
                    Task { @MainActor in
                        self.progressValue = fraction
                        self.statusMessage = message
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

    public func sync(onCompleted: @escaping @MainActor () -> Void) {
        guard let sourceURL, let targetURL else { return }

        isSyncing = true
        progressValue = 0

        let items = syncItems
        let facade = self.facade

        Task.detached {
            do {
                try facade.executeSync(
                    items: items,
                    sourceBase: sourceURL,
                    targetBase: targetURL
                ) { current, total, message in
                    Task { @MainActor in
                        self.progressValue = total > 0
                            ? Double(current) / Double(total)
                            : 1
                        self.statusMessage = message
                    }
                }

                await MainActor.run {
                    self.isSyncing = false
                    onCompleted()
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
