import Foundation

public enum DirectoryCompareStatus: String, CaseIterable, Identifiable, Sendable, Codable {
    case same
    case modified
    case leftOnly
    case rightOnly
    case typeMismatch
    case error

    public var id: String { rawValue }
}

public struct DirectoryEntryMetadata: Sendable, Hashable {
    public let url: URL
    public let isDirectory: Bool
    public let size: Int64
    public let modificationDate: Date?

    public init(
        url: URL,
        isDirectory: Bool,
        size: Int64,
        modificationDate: Date?
    ) {
        self.url = url
        self.isDirectory = isDirectory
        self.size = size
        self.modificationDate = modificationDate
    }
}

public struct DirectoryCompareItem: Identifiable, Sendable, Hashable {
    public let id: String
    public let relativePath: String
    public let left: DirectoryEntryMetadata?
    public let right: DirectoryEntryMetadata?
    public let status: DirectoryCompareStatus
    public let errorDescription: String?

    public init(
        relativePath: String,
        left: DirectoryEntryMetadata?,
        right: DirectoryEntryMetadata?,
        status: DirectoryCompareStatus,
        errorDescription: String? = nil
    ) {
        self.id = relativePath
        self.relativePath = relativePath
        self.left = left
        self.right = right
        self.status = status
        self.errorDescription = errorDescription
    }

    public var isDirectory: Bool {
        left?.isDirectory ?? right?.isDirectory ?? false
    }
}
