import Foundation

public struct MergeChunkState: Identifiable, Sendable, Hashable, Codable {
    public let id: Int
    public let chunkID: Int
    public var decision: MergeDecision?
    public var isResolved: Bool

    public init(
        chunkID: Int,
        decision: MergeDecision?,
        isResolved: Bool
    ) {
        self.id = chunkID
        self.chunkID = chunkID
        self.decision = decision
        self.isResolved = isResolved
    }
}

public struct ThreeWayMergeResult: Sendable, Hashable, Codable {
    public let text: String
    public let chunkStates: [MergeChunkState]
    public let unresolvedConflictCount: Int

    public init(
        text: String,
        chunkStates: [MergeChunkState],
        unresolvedConflictCount: Int
    ) {
        self.text = text
        self.chunkStates = chunkStates
        self.unresolvedConflictCount = unresolvedConflictCount
    }
}
