import Foundation

public enum MergeDecision: String, Sendable, Codable, CaseIterable {
    case useLocal
    case useRemote
    case useBase
    case useBothLocalThenRemote
    case useBothRemoteThenLocal
}
