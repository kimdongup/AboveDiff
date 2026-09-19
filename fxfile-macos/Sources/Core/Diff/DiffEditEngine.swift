import Foundation

public protocol DiffEditing: Sendable {
    func apply(
        chunk: DiffChunk,
        from source: DiffSide,
        leftText: String,
        rightText: String
    ) throws -> DiffEditResult
}

public struct DiffEditEngine: DiffEditing {
    public init() {}

    public func apply(
        chunk: DiffChunk,
        from source: DiffSide,
        leftText: String,
        rightText: String
    ) throws -> DiffEditResult {
        let leftLines = splitPreservingTrailingState(leftText)
        let rightLines = splitPreservingTrailingState(rightText)

        switch source {
        case .left:
            let replacement = Array(
                safeSlice(
                    leftLines.lines,
                    range: chunk.left.range
                )
            )

            var newRight = rightLines.lines
            replace(
                lines: &newRight,
                range: chunk.right.range,
                with: replacement
            )

            return DiffEditResult(
                leftText: leftText,
                rightText: join(
                    newRight,
                    hadTrailingNewline: rightLines.hadTrailingNewline
                )
            )

        case .right:
            let replacement = Array(
                safeSlice(
                    rightLines.lines,
                    range: chunk.right.range
                )
            )

            var newLeft = leftLines.lines
            replace(
                lines: &newLeft,
                range: chunk.left.range,
                with: replacement
            )

            return DiffEditResult(
                leftText: join(
                    newLeft,
                    hadTrailingNewline: leftLines.hadTrailingNewline
                ),
                rightText: rightText
            )
        }
    }

    private func safeSlice(
        _ lines: [String],
        range: Range<Int>
    ) -> ArraySlice<String> {
        let lower = min(
            max(0, range.lowerBound),
            lines.count
        )
        let upper = min(
            max(lower, range.upperBound),
            lines.count
        )

        return lines[lower..<upper]
    }

    private func replace(
        lines: inout [String],
        range: Range<Int>,
        with replacement: [String]
    ) {
        let lower = min(
            max(0, range.lowerBound),
            lines.count
        )
        let upper = min(
            max(lower, range.upperBound),
            lines.count
        )

        lines.replaceSubrange(
            lower..<upper,
            with: replacement
        )
    }

    private func splitPreservingTrailingState(
        _ text: String
    ) -> (
        lines: [String],
        hadTrailingNewline: Bool
    ) {
        let normalized = text
            .replacingOccurrences(
                of: "\r\n",
                with: "\n"
            )
            .replacingOccurrences(
                of: "\r",
                with: "\n"
            )

        if normalized.isEmpty {
            return ([], false)
        }

        let trailing = normalized.hasSuffix("\n")
        var lines = normalized.components(
            separatedBy: "\n"
        )

        if trailing,
           lines.last == "" {
            lines.removeLast()
        }

        return (lines, trailing)
    }

    private func join(
        _ lines: [String],
        hadTrailingNewline: Bool
    ) -> String {
        let base = lines.joined(separator: "\n")

        if hadTrailingNewline,
           !lines.isEmpty {
            return base + "\n"
        }

        return base
    }
}
