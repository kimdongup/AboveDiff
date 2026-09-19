import Foundation

public struct RegexTextFilter: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public var pattern: String
    public var replacement: String
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        pattern: String,
        replacement: String = "",
        isEnabled: Bool = true
    ) {
        self.id = id
        self.pattern = pattern
        self.replacement = replacement
        self.isEnabled = isEnabled
    }
}

public enum DiffFilterError: LocalizedError, Sendable {
    case invalidRegularExpression(String)

    public var errorDescription: String? {
        switch self {
        case .invalidRegularExpression(let pattern):
            return "Invalid regular expression: \(pattern)"
        }
    }
}
