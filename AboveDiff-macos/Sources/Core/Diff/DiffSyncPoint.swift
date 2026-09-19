import Foundation

public struct DiffSyncPoint: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public var leftLine: Int
    public var rightLine: Int

    public init(
        id: UUID = UUID(),
        leftLine: Int,
        rightLine: Int
    ) {
        self.id = id
        self.leftLine = max(0, leftLine)
        self.rightLine = max(0, rightLine)
    }
}
