import Foundation

public enum GitFileStatus: String, Sendable, Hashable, Codable {
    case clean
    case modified
    case added
    case deleted
    case renamed
    case untracked
    case conflicted
    case unknown
}

public struct GitStatusItem: Sendable, Hashable, Identifiable {
    public var id: String {
        relativePath
    }

    public let relativePath: String
    public let indexStatus: GitFileStatus
    public let workTreeStatus: GitFileStatus
    public let isConflicted: Bool

    public init(
        relativePath: String,
        indexStatus: GitFileStatus,
        workTreeStatus: GitFileStatus,
        isConflicted: Bool
    ) {
        self.relativePath = relativePath
        self.indexStatus = indexStatus
        self.workTreeStatus = workTreeStatus
        self.isConflicted = isConflicted
    }

    public var isStaged: Bool {
        indexStatus != .clean &&
        indexStatus != .untracked &&
        indexStatus != .unknown
    }

    public var isModifiedInWorkingTree: Bool {
        workTreeStatus != .clean &&
        workTreeStatus != .unknown
    }
}
