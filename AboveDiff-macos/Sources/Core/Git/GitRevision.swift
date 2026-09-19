import Foundation

public enum GitRevision: Sendable, Hashable, Codable {
    case workingTree
    case index
    case head
    case mergeBase
    case ours
    case theirs
    case custom(String)

    public var displayName: String {
        switch self {
        case .workingTree:
            return "Working Tree"
        case .index:
            return "Staged"
        case .head:
            return "HEAD"
        case .mergeBase:
            return "BASE"
        case .ours:
            return "OURS"
        case .theirs:
            return "THEIRS"
        case .custom(let value):
            return value
        }
    }
}
