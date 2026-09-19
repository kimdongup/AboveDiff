import Foundation

public enum ThreeWayDiffKind: String, Sendable, Codable, CaseIterable {
    case equal
    case localOnly
    case remoteOnly
    case sameChange
    case conflict
}

public struct ThreeWayDiffChunk: Identifiable, Sendable, Hashable, Codable {
    public let id: Int
    public let kind: ThreeWayDiffKind

    public let base: DiffLineRange
    public let local: DiffLineRange
    public let remote: DiffLineRange

    public init(
        id: Int,
        kind: ThreeWayDiffKind,
        base: DiffLineRange,
        local: DiffLineRange,
        remote: DiffLineRange
    ) {
        self.id = id
        self.kind = kind
        self.base = base
        self.local = local
        self.remote = remote
    }

    public var isChange: Bool {
        kind != .equal
    }

    public var isConflict: Bool {
        kind == .conflict
    }
}
