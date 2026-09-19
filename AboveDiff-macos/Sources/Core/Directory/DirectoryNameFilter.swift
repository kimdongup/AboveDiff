import Foundation

public struct DirectoryNameFilter: Sendable, Hashable {
    public var includePattern: String
    public var excludePattern: String
    public var useRegex: Bool

    public init(
        includePattern: String = "",
        excludePattern: String = "",
        useRegex: Bool = false
    ) {
        self.includePattern = includePattern
        self.excludePattern = excludePattern
        self.useRegex = useRegex
    }

    public var isEmpty: Bool {
        includePattern.isEmpty && excludePattern.isEmpty
    }

    public func matches(relativePath: String) -> Bool {
        let name = URL(fileURLWithPath: relativePath).lastPathComponent

        let included: Bool
        if includePattern.isEmpty {
            included = true
        } else {
            included = matches(
                name,
                pattern: includePattern
            )
        }

        guard included else {
            return false
        }

        if excludePattern.isEmpty {
            return true
        }

        return !matches(
            name,
            pattern: excludePattern
        )
    }

    private func matches(
        _ value: String,
        pattern: String
    ) -> Bool {
        if useRegex {
            return value.range(
                of: pattern,
                options: .regularExpression
            ) != nil
        }

        let escaped = NSRegularExpression
            .escapedPattern(for: pattern)
            .replacingOccurrences(of: "\\*", with: ".*")
            .replacingOccurrences(of: "\\?", with: ".")

        return value.range(
            of: "^\(escaped)$",
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }
}
