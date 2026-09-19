import Foundation

public enum FileComparisonMode: String, CaseIterable, Identifiable, Sendable, Codable {
    case metadata
    case content
    case smart

    public var id: String { rawValue }
}

public struct FileContentCompareOptions: Sendable, Hashable {
    public var chunkSize: Int

    public init(chunkSize: Int = 64 * 1024) {
        self.chunkSize = max(4 * 1024, chunkSize)
    }
}

public enum FileContentComparison: Sendable, Equatable {
    case equal
    case different
}
