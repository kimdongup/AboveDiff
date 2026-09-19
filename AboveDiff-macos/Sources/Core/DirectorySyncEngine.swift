import Foundation

public enum SyncStatus: String, CaseIterable, Identifiable, Sendable {
    case missingInTarget = "Missing in Target"
    case missingInSource = "Missing in Source"
    case newerInSource = "Newer in Source"
    case newerInTarget = "Newer in Target"
    case differentSize = "Different Size"
    case equal = "Equal"

    public var id: String { rawValue }
}

public enum SyncAction: String, CaseIterable, Identifiable, Sendable {
    case copyToTarget = "Copy to Target"
    case copyToSource = "Copy to Source"
    case deleteFromTarget = "Delete from Target"
    case deleteFromSource = "Delete from Source"
    case skip = "Skip"

    public var id: String { rawValue }
}

public enum SyncDirection: String, CaseIterable, Identifiable, Sendable {
    case sourceToTargetUpdate = "Source -> Target (Update)"
    case sourceToTargetMirror = "Source -> Target (Mirror)"
    case targetToSource = "Target -> Source"
    case bidirectional = "Two-Way Bidirectional"

    public var id: String { rawValue }
}

public struct SyncItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let relativePath: String
    public let sourceURL: URL?
    public let targetURL: URL?
    public let isDirectory: Bool
    public var status: SyncStatus
    public var action: SyncAction
    public var isSelected: Bool
    public let sourceSize: Int64?
    public let targetSize: Int64?
    public let sourceDate: Date?
    public let targetDate: Date?

    public init(
        relativePath: String,
        sourceURL: URL?,
        targetURL: URL?,
        isDirectory: Bool,
        status: SyncStatus,
        action: SyncAction,
        isSelected: Bool = true,
        sourceSize: Int64? = nil,
        targetSize: Int64? = nil,
        sourceDate: Date? = nil,
        targetDate: Date? = nil
    ) {
        self.id = relativePath
        self.relativePath = relativePath
        self.sourceURL = sourceURL
        self.targetURL = targetURL
        self.isDirectory = isDirectory
        self.status = status
        self.action = action
        self.isSelected = isSelected
        self.sourceSize = sourceSize
        self.targetSize = targetSize
        self.sourceDate = sourceDate
        self.targetDate = targetDate
    }
}

/// Compatibility facade for the original sync API.
/// New code should use DirectoryCompareEngine -> DirectorySyncPlanner -> DirectorySyncExecutor.
public final class DirectorySyncEngine: @unchecked Sendable {
    public static let shared = DirectorySyncEngine()

    private let compareEngine: DirectoryCompareEngine
    private let executor: DirectorySyncExecutor

    public init(
        compareEngine: DirectoryCompareEngine = .shared,
        executor: DirectorySyncExecutor = DirectorySyncExecutor()
    ) {
        self.compareEngine = compareEngine
        self.executor = executor
    }

    // Existing API preserved exactly for legacy callers/tests.
    public func compareDirectories(
        source: URL,
        target: URL,
        direction: SyncDirection = .sourceToTargetUpdate,
        recursive: Bool = true,
        compareChecksum: Bool = false,
        progress: (@Sendable (Double, String) -> Void)? = nil
    ) throws -> [SyncItem] {
        try compareDirectoriesWithMode(
            source: source,
            target: target,
            direction: direction,
            recursive: recursive,
            comparisonMode: compareChecksum ? .content : .metadata,
            progress: progress
        )
    }

    // New unambiguous API for state/UI orchestration.
    public func compareDirectoriesWithMode(
        source: URL,
        target: URL,
        direction: SyncDirection = .sourceToTargetUpdate,
        recursive: Bool = true,
        comparisonMode: FileComparisonMode = .smart,
        progress: (@Sendable (Double, String) -> Void)? = nil
    ) throws -> [SyncItem] {
        let request = DirectoryCompareRequest(
            leftRoot: source,
            rightRoot: target,
            options: DirectoryCompareOptions(
                recursive: recursive,
                includeHiddenFiles: false,
                comparisonMode: comparisonMode
            )
        )

        let compared = try compareEngine.compare(
            request: request,
            progress: progress
        )

        return compared.map {
            legacyItem(from: $0, direction: direction)
        }
    }

    public func executeSync(
        items: [SyncItem],
        sourceBase: URL,
        targetBase: URL,
        progress: (@Sendable (Int, Int, String) -> Void)? = nil
    ) throws {
        let operations: [DirectorySyncOperation] = items.compactMap { item in
            guard item.isSelected, item.action != .skip else { return nil }

            return DirectorySyncOperation(
                relativePath: item.relativePath,
                kind: operationKind(for: item.action),
                isDirectory: item.isDirectory
            )
        }

        try executor.execute(
            plan: DirectorySyncPlan(operations: operations),
            leftRoot: sourceBase,
            rightRoot: targetBase,
            progress: progress
        )
    }

    private func legacyItem(
        from item: DirectoryCompareItem,
        direction: SyncDirection
    ) -> SyncItem {
        let status = legacyStatus(for: item)
        let action = legacyAction(for: item, direction: direction)

        return SyncItem(
            relativePath: item.relativePath,
            sourceURL: item.left?.url,
            targetURL: item.right?.url,
            isDirectory: item.isDirectory,
            status: status,
            action: action,
            isSelected: action != .skip,
            sourceSize: item.left?.size,
            targetSize: item.right?.size,
            sourceDate: item.left?.modificationDate,
            targetDate: item.right?.modificationDate
        )
    }

    private func legacyStatus(for item: DirectoryCompareItem) -> SyncStatus {
        switch item.status {
        case .same:
            return .equal
        case .leftOnly:
            return .missingInTarget
        case .rightOnly:
            return .missingInSource
        case .typeMismatch, .error:
            return .differentSize
        case .modified:
            if let leftSize = item.left?.size,
               let rightSize = item.right?.size,
               leftSize != rightSize {
                return .differentSize
            }

            if let leftDate = item.left?.modificationDate,
               let rightDate = item.right?.modificationDate {
                return leftDate >= rightDate ? .newerInSource : .newerInTarget
            }

            return .differentSize
        }
    }

    private func legacyAction(
        for item: DirectoryCompareItem,
        direction: SyncDirection
    ) -> SyncAction {
        switch item.status {
        case .same, .error, .typeMismatch:
            return .skip

        case .leftOnly:
            switch direction {
            case .sourceToTargetUpdate, .sourceToTargetMirror, .bidirectional:
                return .copyToTarget
            case .targetToSource:
                return .skip
            }

        case .rightOnly:
            switch direction {
            case .sourceToTargetMirror:
                return .deleteFromTarget
            case .targetToSource, .bidirectional:
                return .copyToSource
            case .sourceToTargetUpdate:
                return .skip
            }

        case .modified:
            switch direction {
            case .sourceToTargetUpdate, .sourceToTargetMirror:
                return .copyToTarget
            case .targetToSource:
                return .copyToSource
            case .bidirectional:
                if let leftDate = item.left?.modificationDate,
                   let rightDate = item.right?.modificationDate,
                   rightDate > leftDate {
                    return .copyToSource
                }
                return .copyToTarget
            }
        }
    }

    private func operationKind(for action: SyncAction) -> DirectorySyncOperationKind {
        switch action {
        case .copyToTarget:
            return .copyLeftToRight
        case .copyToSource:
            return .copyRightToLeft
        case .deleteFromTarget:
            return .deleteRight
        case .deleteFromSource:
            return .deleteLeft
        case .skip:
            preconditionFailure("skip actions must be filtered before execution")
        }
    }
}
