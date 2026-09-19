import Foundation

public protocol ThreeWayDiffing: Sendable {
    func compare(
        local: ThreeWayDocument,
        base: ThreeWayDocument,
        remote: ThreeWayDocument,
        options: ThreeWayDiffOptions
    ) throws -> ThreeWayDiffResult
}

public struct ThreeWayDiffEngine: ThreeWayDiffing {
    private let diffEngine: any DiffEngine

    public init(
        diffEngine: any DiffEngine = LineDiffEngine()
    ) {
        self.diffEngine = diffEngine
    }

    public func compare(
        local: ThreeWayDocument,
        base: ThreeWayDocument,
        remote: ThreeWayDocument,
        options: ThreeWayDiffOptions = ThreeWayDiffOptions()
    ) throws -> ThreeWayDiffResult {
        if Task.isCancelled {
            throw CancellationError()
        }

        let baseToLocal = try diffEngine.compare(
            left: DiffDocument(
                identifier: base.identifier,
                text: base.text
            ),
            right: DiffDocument(
                identifier: local.identifier,
                text: local.text
            ),
            options: options.diffOptions
        )

        if Task.isCancelled {
            throw CancellationError()
        }

        let baseToRemote = try diffEngine.compare(
            left: DiffDocument(
                identifier: base.identifier,
                text: base.text
            ),
            right: DiffDocument(
                identifier: remote.identifier,
                text: remote.text
            ),
            options: options.diffOptions
        )

        let localChanges = baseToLocal.changes
        let remoteChanges = baseToRemote.changes

        var boundaries = Set<Int>()
        boundaries.insert(0)
        boundaries.insert(baseToLocal.leftLineCount)

        for chunk in localChanges {
            boundaries.insert(chunk.left.lowerBound)
            boundaries.insert(chunk.left.upperBound)
        }

        for chunk in remoteChanges {
            boundaries.insert(chunk.left.lowerBound)
            boundaries.insert(chunk.left.upperBound)
        }

        let ordered = boundaries.sorted()

        var chunks: [ThreeWayDiffChunk] = []

        if ordered.count <= 1 {
            let kind = classifyWholeDocument(
                local: local.text,
                base: base.text,
                remote: remote.text
            )

            let chunk = ThreeWayDiffChunk(
                id: 0,
                kind: kind,
                base: DiffLineRange(
                    lowerBound: 0,
                    upperBound: baseToLocal.leftLineCount
                ),
                local: DiffLineRange(
                    lowerBound: 0,
                    upperBound: baseToLocal.rightLineCount
                ),
                remote: DiffLineRange(
                    lowerBound: 0,
                    upperBound: baseToRemote.rightLineCount
                )
            )

            chunks = [chunk]
        } else {
            for index in 0..<(ordered.count - 1) {
                if Task.isCancelled {
                    throw CancellationError()
                }

                let baseRange =
                    ordered[index]..<ordered[index + 1]

                guard !baseRange.isEmpty else {
                    continue
                }

                let localChunk = overlappingChange(
                    baseRange: baseRange,
                    changes: localChanges
                )

                let remoteChunk = overlappingChange(
                    baseRange: baseRange,
                    changes: remoteChanges
                )

                let localRange = mappedRange(
                    baseRange: baseRange,
                    using: localChunk,
                    fullDiff: baseToLocal
                )

                let remoteRange = mappedRange(
                    baseRange: baseRange,
                    using: remoteChunk,
                    fullDiff: baseToRemote
                )

                let kind = classify(
                    baseRange: baseRange,
                    localRange: localRange,
                    remoteRange: remoteRange,
                    baseText: base.text,
                    localText: local.text,
                    remoteText: remote.text,
                    localChanged: localChunk != nil,
                    remoteChanged: remoteChunk != nil
                )

                chunks.append(
                    ThreeWayDiffChunk(
                        id: chunks.count,
                        kind: kind,
                        base: DiffLineRange(baseRange),
                        local: DiffLineRange(localRange),
                        remote: DiffLineRange(remoteRange)
                    )
                )
            }

            chunks = coalesce(chunks)
        }

        var statistics = ThreeWayDiffStatistics()

        var equal = 0
        var localOnly = 0
        var remoteOnly = 0
        var sameChange = 0
        var conflict = 0

        for chunk in chunks {
            switch chunk.kind {
            case .equal:
                equal += 1
            case .localOnly:
                localOnly += 1
            case .remoteOnly:
                remoteOnly += 1
            case .sameChange:
                sameChange += 1
            case .conflict:
                conflict += 1
            }
        }

        statistics = ThreeWayDiffStatistics(
            equalChunks: equal,
            localOnlyChunks: localOnly,
            remoteOnlyChunks: remoteOnly,
            sameChangeChunks: sameChange,
            conflictChunks: conflict
        )

        return ThreeWayDiffResult(
            chunks: chunks,
            baseLineCount: baseToLocal.leftLineCount,
            localLineCount: baseToLocal.rightLineCount,
            remoteLineCount: baseToRemote.rightLineCount,
            statistics: statistics
        )
    }

    private func classifyWholeDocument(
        local: String,
        base: String,
        remote: String
    ) -> ThreeWayDiffKind {
        if local == base && remote == base {
            return .equal
        }

        if local != base && remote == base {
            return .localOnly
        }

        if local == base && remote != base {
            return .remoteOnly
        }

        if local == remote {
            return .sameChange
        }

        return .conflict
    }

    private func overlappingChange(
        baseRange: Range<Int>,
        changes: [DiffChunk]
    ) -> DiffChunk? {
        changes.first {
            rangesOverlap(
                $0.left.range,
                baseRange
            ) ||
            (
                $0.left.isEmpty &&
                $0.left.lowerBound >= baseRange.lowerBound &&
                $0.left.lowerBound <= baseRange.upperBound
            )
        }
    }

    private func mappedRange(
        baseRange: Range<Int>,
        using chunk: DiffChunk?,
        fullDiff: DiffResult
    ) -> Range<Int> {
        if let chunk {
            if chunk.left.isEmpty {
                return chunk.right.range
            }

            let leftSpan = max(1, chunk.left.count)
            let rightSpan = chunk.right.count

            let relativeLower =
                max(0, baseRange.lowerBound - chunk.left.lowerBound)

            let relativeUpper =
                max(0, baseRange.upperBound - chunk.left.lowerBound)

            let mappedLower =
                chunk.right.lowerBound +
                Int(
                    (Double(relativeLower) /
                     Double(leftSpan)) *
                    Double(rightSpan)
                )

            let mappedUpper =
                chunk.right.lowerBound +
                Int(
                    (Double(relativeUpper) /
                     Double(leftSpan)) *
                    Double(rightSpan)
                )

            return min(mappedLower, fullDiff.rightLineCount)
                ..<
                min(max(mappedLower, mappedUpper),
                    fullDiff.rightLineCount)
        }

        let delta = lineDelta(
            beforeBaseLine: baseRange.lowerBound,
            chunks: fullDiff.chunks
        )

        let lower =
            max(0, baseRange.lowerBound + delta)

        let upper =
            max(lower, baseRange.upperBound + delta)

        return min(lower, fullDiff.rightLineCount)
            ..<
            min(upper, fullDiff.rightLineCount)
    }

    private func lineDelta(
        beforeBaseLine line: Int,
        chunks: [DiffChunk]
    ) -> Int {
        var delta = 0

        for chunk in chunks where chunk.isChange {
            if chunk.left.upperBound <= line {
                delta += chunk.right.count - chunk.left.count
            }
        }

        return delta
    }

    private func classify(
        baseRange: Range<Int>,
        localRange: Range<Int>,
        remoteRange: Range<Int>,
        baseText: String,
        localText: String,
        remoteText: String,
        localChanged: Bool,
        remoteChanged: Bool
    ) -> ThreeWayDiffKind {
        if !localChanged && !remoteChanged {
            return .equal
        }

        if localChanged && !remoteChanged {
            return .localOnly
        }

        if !localChanged && remoteChanged {
            return .remoteOnly
        }

        let localSegment = lines(
            from: localText,
            range: localRange
        )

        let remoteSegment = lines(
            from: remoteText,
            range: remoteRange
        )

        if localSegment == remoteSegment {
            return .sameChange
        }

        return .conflict
    }

    private func lines(
        from text: String,
        range: Range<Int>
    ) -> [String] {
        let lines = splitLines(text)

        guard !range.isEmpty,
              range.lowerBound < lines.count
        else {
            return []
        }

        let lower = min(range.lowerBound, lines.count)
        let upper = min(range.upperBound, lines.count)

        guard lower <= upper else {
            return []
        }

        return Array(lines[lower..<upper])
    }

    private func splitLines(
        _ text: String
    ) -> [String] {
        if text.isEmpty {
            return []
        }

        var lines = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")

        if lines.last == "" {
            lines.removeLast()
        }

        return lines
    }

    private func rangesOverlap(
        _ lhs: Range<Int>,
        _ rhs: Range<Int>
    ) -> Bool {
        lhs.lowerBound < rhs.upperBound &&
        rhs.lowerBound < lhs.upperBound
    }

    private func coalesce(
        _ source: [ThreeWayDiffChunk]
    ) -> [ThreeWayDiffChunk] {
        var output: [ThreeWayDiffChunk] = []

        for chunk in source {
            if let last = output.last,
               last.kind == chunk.kind,
               last.base.upperBound == chunk.base.lowerBound,
               last.local.upperBound == chunk.local.lowerBound,
               last.remote.upperBound == chunk.remote.lowerBound {
                output.removeLast()

                output.append(
                    ThreeWayDiffChunk(
                        id: last.id,
                        kind: last.kind,
                        base: DiffLineRange(
                            lowerBound: last.base.lowerBound,
                            upperBound: chunk.base.upperBound
                        ),
                        local: DiffLineRange(
                            lowerBound: last.local.lowerBound,
                            upperBound: chunk.local.upperBound
                        ),
                        remote: DiffLineRange(
                            lowerBound: last.remote.lowerBound,
                            upperBound: chunk.remote.upperBound
                        )
                    )
                )
            } else {
                output.append(chunk)
            }
        }

        return output.enumerated().map { index, chunk in
            ThreeWayDiffChunk(
                id: index,
                kind: chunk.kind,
                base: chunk.base,
                local: chunk.local,
                remote: chunk.remote
            )
        }
    }
}
