import Foundation
import fxfileCore

@MainActor
public final class FolderCompareState: ObservableObject {
    @Published public var leftRoot: URL?
    @Published public var rightRoot: URL?

    @Published public var recursive: Bool = true
    @Published public var includeHiddenFiles: Bool = false
    @Published public var comparisonMode: FileComparisonMode = .smart

    @Published public var includePattern: String = ""
    @Published public var excludePattern: String = ""
    @Published public var useRegexNameFilter: Bool = false

    @Published public var showSame: Bool = true
    @Published public var showModified: Bool = true
    @Published public var showLeftOnly: Bool = true
    @Published public var showRightOnly: Bool = true
    @Published public var showErrors: Bool = true

    @Published public private(set) var items: [DirectoryCompareItem] = []
    @Published public var selectedIDs: Set<String> = []

    @Published public private(set) var isComparing = false
    @Published public private(set) var isApplyingAction = false
    @Published public private(set) var progressValue: Double = 0
    @Published public private(set) var statusMessage: String = ""

    private let compareEngine: DirectoryCompareEngine
    private let executor: DirectorySyncExecutor
    private var compareTask: Task<Void, Never>?

    public init(
        leftRoot: URL?,
        rightRoot: URL?,
        compareEngine: DirectoryCompareEngine = .shared,
        executor: DirectorySyncExecutor = DirectorySyncExecutor()
    ) {
        self.leftRoot = leftRoot
        self.rightRoot = rightRoot
        self.compareEngine = compareEngine
        self.executor = executor
    }

    public var filteredItems: [DirectoryCompareItem] {
        items.filter { item in
            switch item.status {
            case .same:
                return showSame
            case .modified:
                return showModified
            case .leftOnly:
                return showLeftOnly
            case .rightOnly:
                return showRightOnly
            case .typeMismatch, .error:
                return showErrors
            }
        }
    }

    public var selectedItems: [DirectoryCompareItem] {
        items.filter {
            selectedIDs.contains($0.id)
        }
    }

    public func compare() {
        guard let leftRoot,
              let rightRoot else {
            return
        }

        compareTask?.cancel()

        isComparing = true
        progressValue = 0
        statusMessage = ""
        items = []
        selectedIDs.removeAll()

        let options = DirectoryCompareOptions(
            recursive: recursive,
            includeHiddenFiles: includeHiddenFiles,
            comparisonMode: comparisonMode,
            nameFilter: DirectoryNameFilter(
                includePattern: includePattern,
                excludePattern: excludePattern,
                useRegex: useRegexNameFilter
            )
        )

        let request = DirectoryCompareRequest(
            leftRoot: leftRoot,
            rightRoot: rightRoot,
            options: options
        )

        let engine = compareEngine

        compareTask = Task {
            do {
                let result = try await Task.detached {
                    try engine.compare(
                        request: request
                    ) { fraction, message in
                        Task { @MainActor in
                            self.progressValue = fraction
                            self.statusMessage = message
                        }
                    }
                }.value

                guard !Task.isCancelled else {
                    return
                }

                self.items = result
                self.isComparing = false
                self.statusMessage =
                    "\(result.count) items compared"
            } catch is CancellationError {
                self.isComparing = false
                self.statusMessage = "Comparison cancelled"
            } catch {
                self.isComparing = false
                self.statusMessage =
                    "Error: \(error.localizedDescription)"
            }
        }
    }

    public func cancelCompare() {
        compareTask?.cancel()
    }

    public func refresh() {
        compare()
    }

    public func selectAllVisible() {
        selectedIDs.formUnion(
            filteredItems.map(\.id)
        )
    }

    public func deselectAllVisible() {
        let visible = Set(
            filteredItems.map(\.id)
        )
        selectedIDs.subtract(visible)
    }

    public func toggleSelection(id: String) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    public func copySelectedLeftToRight(
        completion: @escaping @MainActor () -> Void
    ) {
        executeSelected(
            kind: .copyLeftToRight,
            validStatuses: [.leftOnly, .modified],
            completion: completion
        )
    }

    public func copySelectedRightToLeft(
        completion: @escaping @MainActor () -> Void
    ) {
        executeSelected(
            kind: .copyRightToLeft,
            validStatuses: [.rightOnly, .modified],
            completion: completion
        )
    }

    private func executeSelected(
        kind: DirectorySyncOperationKind,
        validStatuses: Set<DirectoryCompareStatus>,
        completion: @escaping @MainActor () -> Void
    ) {
        guard let leftRoot,
              let rightRoot else {
            return
        }

        let operations =
            selectedItems.compactMap {
                item -> DirectorySyncOperation? in

                guard validStatuses
                    .contains(item.status)
                else {
                    return nil
                }

                return DirectorySyncOperation(
                    relativePath:
                        item.relativePath,
                    kind: kind,
                    isDirectory:
                        item.isDirectory
                )
            }

        guard !operations.isEmpty else {
            statusMessage =
                "No applicable selected items"
            return
        }

        isApplyingAction = true
        progressValue = 0

        let plan =
            DirectorySyncPlan(
                operations: operations
            )

        let executor = self.executor

        Task.detached {
            do {
                try executor.execute(
                    plan: plan,
                    leftRoot: leftRoot,
                    rightRoot: rightRoot
                ) { current, total, message in
                    Task { @MainActor in
                        self.progressValue =
                            total > 0
                            ? Double(current) /
                              Double(total)
                            : 1

                        self.statusMessage =
                            message
                    }
                }

                await MainActor.run {
                    self.isApplyingAction =
                        false
                    completion()
                    self.compare()
                }
            } catch {
                await MainActor.run {
                    self.isApplyingAction =
                        false
                    self.statusMessage =
                        "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
