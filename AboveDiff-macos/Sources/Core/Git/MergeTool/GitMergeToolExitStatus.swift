import Foundation

public enum GitMergeToolExitStatus: Int32, Sendable, Codable, CaseIterable {
    case success = 0
    case cancelled = 1
    case invalidArguments = 2
    case fileError = 3
    case unresolvedConflict = 4
    case internalError = 5
}
