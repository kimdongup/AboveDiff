import Foundation

public struct TextNormalizationOptions: Sendable, Hashable {
    public var normalizeLineEndings: Bool
    public var ignoreTrailingNewlineDifference: Bool
    public var ignoreBlankLines: Bool
    public var regexFilters: [RegexTextFilter]

    public init(
        normalizeLineEndings: Bool = true,
        ignoreTrailingNewlineDifference: Bool = true,
        ignoreBlankLines: Bool = false,
        regexFilters: [RegexTextFilter] = []
    ) {
        self.normalizeLineEndings = normalizeLineEndings
        self.ignoreTrailingNewlineDifference = ignoreTrailingNewlineDifference
        self.ignoreBlankLines = ignoreBlankLines
        self.regexFilters = regexFilters
    }
}

public struct NormalizedText: Sendable, Hashable {
    public let originalLineCount: Int
    public let lines: [String]
    public let originalLineIndices: [Int]

    public init(
        originalLineCount: Int,
        lines: [String],
        originalLineIndices: [Int]
    ) {
        self.originalLineCount = originalLineCount
        self.lines = lines
        self.originalLineIndices = originalLineIndices
    }

    public func originalRange(
        forNormalizedRange range: Range<Int>
    ) -> Range<Int> {
        if range.isEmpty {
            let boundary = originalBoundary(
                forNormalizedPosition: range.lowerBound
            )
            return boundary..<boundary
        }

        guard !originalLineIndices.isEmpty else {
            return 0..<0
        }

        let lowerPosition = min(
            max(0, range.lowerBound),
            originalLineIndices.count - 1
        )

        let upperPosition = min(
            max(lowerPosition, range.upperBound - 1),
            originalLineIndices.count - 1
        )

        let lower = originalLineIndices[lowerPosition]
        let upper = min(
            originalLineCount,
            originalLineIndices[upperPosition] + 1
        )

        return lower..<upper
    }

    public func normalizedIndex(
        forOriginalLine line: Int
    ) -> Int? {
        originalLineIndices.firstIndex(of: line)
    }

    private func originalBoundary(
        forNormalizedPosition position: Int
    ) -> Int {
        if originalLineIndices.isEmpty {
            return min(max(0, position), originalLineCount)
        }

        if position <= 0 {
            return originalLineIndices[0]
        }

        if position >= originalLineIndices.count {
            return originalLineCount
        }

        return originalLineIndices[position]
    }
}

public struct TextNormalizer: Sendable {
    public init() {}

    public func normalize(
        text: String,
        options: TextNormalizationOptions
    ) throws -> NormalizedText {
        var value = text

        if options.normalizeLineEndings {
            value = value
                .replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
        }

        if value.isEmpty {
            return NormalizedText(
                originalLineCount: 0,
                lines: [],
                originalLineIndices: []
            )
        }

        var originalLines = value.components(
            separatedBy: "\n"
        )

        if options.ignoreTrailingNewlineDifference,
           originalLines.last == "" {
            originalLines.removeLast()
        }

        let compiledFilters: [(NSRegularExpression, String)] =
            try options.regexFilters
                .filter(\.isEnabled)
                .map { filter in
                    do {
                        return (
                            try NSRegularExpression(
                                pattern: filter.pattern
                            ),
                            filter.replacement
                        )
                    } catch {
                        throw DiffFilterError
                            .invalidRegularExpression(
                                filter.pattern
                            )
                    }
                }

        var normalized: [String] = []
        var mapping: [Int] = []

        normalized.reserveCapacity(originalLines.count)
        mapping.reserveCapacity(originalLines.count)

        for (index, originalLine) in originalLines.enumerated() {
            var line = originalLine

            for (regex, replacement) in compiledFilters {
                let range = NSRange(
                    location: 0,
                    length: (line as NSString).length
                )

                line = regex.stringByReplacingMatches(
                    in: line,
                    range: range,
                    withTemplate: replacement
                )
            }

            if options.ignoreBlankLines,
               line.trimmingCharacters(
                    in: .whitespacesAndNewlines
               ).isEmpty {
                continue
            }

            normalized.append(line)
            mapping.append(index)
        }

        return NormalizedText(
            originalLineCount: originalLines.count,
            lines: normalized,
            originalLineIndices: mapping
        )
    }
}
