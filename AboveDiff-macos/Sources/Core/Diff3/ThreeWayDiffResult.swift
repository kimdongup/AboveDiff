import Foundation

public struct ThreeWayDiffStatistics: Sendable, Hashable, Codable {
    public let equalChunks: Int
    public let localOnlyChunks: Int
    public let remoteOnlyChunks: Int
    public let sameChangeChunks: Int
    public let conflictChunks: Int

    public init(
        equalChunks: Int = 0,
        localOnlyChunks: Int = 0,
        remoteOnlyChunks: Int = 0,
        sameChangeChunks: Int = 0,
        conflictChunks: Int = 0
    ) {
        self.equalChunks = equalChunks
        self.localOnlyChunks = localOnlyChunks
        self.remoteOnlyChunks = remoteOnlyChunks
        self.sameChangeChunks = sameChangeChunks
        self.conflictChunks = conflictChunks
    }
}

public struct ThreeWayDiffResult: Sendable, Hashable, Codable {
    public let chunks: [ThreeWayDiffChunk]

    public let baseLineCount: Int
    public let localLineCount: Int
    public let remoteLineCount: Int

    public let statistics: ThreeWayDiffStatistics

    public init(
        chunks: [ThreeWayDiffChunk],
        baseLineCount: Int,
        localLineCount: Int,
        remoteLineCount: Int,
        statistics: ThreeWayDiffStatistics
    ) {
        self.chunks = chunks
        self.baseLineCount = baseLineCount
        self.localLineCount = localLineCount
        self.remoteLineCount = remoteLineCount
        self.statistics = statistics
    }

    public var changes: [ThreeWayDiffChunk] {
        chunks.filter(\.isChange)
    }

    public var conflicts: [ThreeWayDiffChunk] {
        chunks.filter(\.isConflict)
    }

    public var isIdentical: Bool {
        changes.isEmpty
    }
}
