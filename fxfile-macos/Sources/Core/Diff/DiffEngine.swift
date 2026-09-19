import Foundation

public enum DiffKind: String, Sendable, Codable, CaseIterable {
    case equal
    case insert
    case delete
    case replace
}

public struct DiffLineRange: Sendable, Hashable, Codable {
    public let lowerBound: Int
    public let upperBound: Int

    public init(_ range: Range<Int>) {
        self.lowerBound = range.lowerBound
        self.upperBound = range.upperBound
    }

    public init(lowerBound: Int, upperBound: Int) {
        precondition(lowerBound >= 0)
        precondition(upperBound >= lowerBound)
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }

    public var range: Range<Int> {
        lowerBound..<upperBound
    }

    public var count: Int {
        upperBound - lowerBound
    }

    public var isEmpty: Bool {
        lowerBound == upperBound
    }
}

public struct DiffChunk: Identifiable, Sendable, Hashable, Codable {
    public let id: Int
    public let kind: DiffKind
    public let left: DiffLineRange
    public let right: DiffLineRange

    public init(
        id: Int,
        kind: DiffKind,
        left: DiffLineRange,
        right: DiffLineRange
    ) {
        self.id = id
        self.kind = kind
        self.left = left
        self.right = right
    }

    public var isChange: Bool {
        kind != .equal
    }
}

public struct DiffStatistics: Sendable, Hashable, Codable {
    public let equalChunks: Int
    public let insertedLines: Int
    public let deletedLines: Int
    public let replacedChunks: Int

    public init(
        equalChunks: Int = 0,
        insertedLines: Int = 0,
        deletedLines: Int = 0,
        replacedChunks: Int = 0
    ) {
        self.equalChunks = equalChunks
        self.insertedLines = insertedLines
        self.deletedLines = deletedLines
        self.replacedChunks = replacedChunks
    }
}

public struct DiffResult: Sendable, Hashable, Codable {
    public let chunks: [DiffChunk]
    public let leftLineCount: Int
    public let rightLineCount: Int
    public let statistics: DiffStatistics

    public init(
        chunks: [DiffChunk],
        leftLineCount: Int,
        rightLineCount: Int,
        statistics: DiffStatistics
    ) {
        self.chunks = chunks
        self.leftLineCount = leftLineCount
        self.rightLineCount = rightLineCount
        self.statistics = statistics
    }

    public var changes: [DiffChunk] {
        chunks.filter(\.isChange)
    }

    public var isIdentical: Bool {
        changes.isEmpty
    }
}

public struct DiffDocument: Sendable, Hashable {
    public let identifier: String?
    public let text: String

    public init(
        identifier: String? = nil,
        text: String
    ) {
        self.identifier = identifier
        self.text = text
    }
}

public struct DiffOptions: Sendable, Hashable {
    public var normalizeLineEndings: Bool
    public var ignoreTrailingNewlineDifference: Bool
    public var ignoreBlankLines: Bool
    public var regexFilters: [RegexTextFilter]
    public var syncPoints: [DiffSyncPoint]
    public var useCache: Bool

    public init(
        normalizeLineEndings: Bool = true,
        ignoreTrailingNewlineDifference: Bool = true,
        ignoreBlankLines: Bool = false,
        regexFilters: [RegexTextFilter] = [],
        syncPoints: [DiffSyncPoint] = [],
        useCache: Bool = true
    ) {
        self.normalizeLineEndings = normalizeLineEndings
        self.ignoreTrailingNewlineDifference =
            ignoreTrailingNewlineDifference
        self.ignoreBlankLines = ignoreBlankLines
        self.regexFilters = regexFilters
        self.syncPoints = syncPoints
        self.useCache = useCache
    }
}

public protocol DiffEngine: Sendable {
    func compare(
        left: DiffDocument,
        right: DiffDocument,
        options: DiffOptions
    ) throws -> DiffResult
}

public enum DiffEngineError: Error, Sendable, Equatable {
    case invalidSyncPoint
    case internalInvariant(String)
}

public struct LineDiffEngine: DiffEngine {
    private let normalizer = TextNormalizer()
    private let cache = DiffResultCache.shared

    public init() {}

    public func compare(
        left: DiffDocument,
        right: DiffDocument,
        options: DiffOptions = DiffOptions()
    ) throws -> DiffResult {
        try checkCancellation()

        if options.useCache,
           let cached = cache.value(
                leftText: left.text,
                rightText: right.text,
                options: options
           ) {
            return cached
        }

        let normalization =
            TextNormalizationOptions(
                normalizeLineEndings:
                    options.normalizeLineEndings,
                ignoreTrailingNewlineDifference:
                    options.ignoreTrailingNewlineDifference,
                ignoreBlankLines:
                    options.ignoreBlankLines,
                regexFilters:
                    options.regexFilters
            )

        let leftText = try normalizer.normalize(
            text: left.text,
            options: normalization
        )

        try checkCancellation()

        let rightText = try normalizer.normalize(
            text: right.text,
            options: normalization
        )

        try checkCancellation()

        let chunks = try buildChunks(
            left: leftText,
            right: rightText,
            syncPoints: options.syncPoints
        )

        var equalChunks = 0
        var insertedLines = 0
        var deletedLines = 0
        var replacedChunks = 0

        for chunk in chunks {
            switch chunk.kind {
            case .equal:
                equalChunks += 1
            case .insert:
                insertedLines += chunk.right.count
            case .delete:
                deletedLines += chunk.left.count
            case .replace:
                replacedChunks += 1
                insertedLines += chunk.right.count
                deletedLines += chunk.left.count
            }
        }

        let result = DiffResult(
            chunks: chunks,
            leftLineCount: leftText.originalLineCount,
            rightLineCount: rightText.originalLineCount,
            statistics: DiffStatistics(
                equalChunks: equalChunks,
                insertedLines: insertedLines,
                deletedLines: deletedLines,
                replacedChunks: replacedChunks
            )
        )

        if options.useCache {
            cache.insert(
                result,
                leftText: left.text,
                rightText: right.text,
                options: options
            )
        }

        return result
    }

    private func buildChunks(
        left: NormalizedText,
        right: NormalizedText,
        syncPoints: [DiffSyncPoint]
    ) throws -> [DiffChunk] {
        let anchors = try normalizedAnchors(
            syncPoints,
            left: left,
            right: right
        )

        if anchors.isEmpty {
            return remapChunks(
                rawDiff(
                    left: left.lines,
                    right: right.lines
                ),
                left: left,
                right: right
            )
        }

        var result: [DiffChunk] = []
        var leftStart = 0
        var rightStart = 0

        for (leftAnchor, rightAnchor) in anchors {
            try checkCancellation()

            let before = rawDiff(
                left: Array(
                    left.lines[
                        leftStart..<leftAnchor
                    ]
                ),
                right: Array(
                    right.lines[
                        rightStart..<rightAnchor
                    ]
                ),
                leftOffset: leftStart,
                rightOffset: rightStart
            )

            result.append(
                contentsOf: remapChunks(
                    before,
                    left: left,
                    right: right
                )
            )

            let anchorKind: DiffKind =
                left.lines[leftAnchor] ==
                right.lines[rightAnchor]
                ? .equal
                : .replace

            result.append(
                DiffChunk(
                    id: 0,
                    kind: anchorKind,
                    left: DiffLineRange(
                        left.originalRange(
                            forNormalizedRange:
                                leftAnchor..<(leftAnchor + 1)
                        )
                    ),
                    right: DiffLineRange(
                        right.originalRange(
                            forNormalizedRange:
                                rightAnchor..<(rightAnchor + 1)
                        )
                    )
                )
            )

            leftStart = leftAnchor + 1
            rightStart = rightAnchor + 1
        }

        let tail = rawDiff(
            left: Array(left.lines[leftStart...]),
            right: Array(right.lines[rightStart...]),
            leftOffset: leftStart,
            rightOffset: rightStart
        )

        result.append(
            contentsOf: remapChunks(
                tail,
                left: left,
                right: right
            )
        )

        return renumberAndCoalesce(result)
    }

    private func normalizedAnchors(
        _ points: [DiffSyncPoint],
        left: NormalizedText,
        right: NormalizedText
    ) throws -> [(Int, Int)] {
        var anchors: [(Int, Int)] = []

        for point in points.sorted(
            by: {
                if $0.leftLine == $1.leftLine {
                    return $0.rightLine < $1.rightLine
                }
                return $0.leftLine < $1.leftLine
            }
        ) {
            guard
                let leftIndex =
                    left.normalizedIndex(
                        forOriginalLine: point.leftLine
                    ),
                let rightIndex =
                    right.normalizedIndex(
                        forOriginalLine: point.rightLine
                    )
            else {
                continue
            }

            if let last = anchors.last,
               (leftIndex <= last.0 ||
                rightIndex <= last.1) {
                throw DiffEngineError.invalidSyncPoint
            }

            anchors.append(
                (leftIndex, rightIndex)
            )
        }

        return anchors
    }

    private func rawDiff(
        left: [String],
        right: [String],
        leftOffset: Int = 0,
        rightOffset: Int = 0
    ) -> [DiffChunk] {
        let difference =
            right.difference(from: left)

        var removals = Set<Int>()
        var insertions = Set<Int>()

        for change in difference {
            switch change {
            case .remove(let offset, _, _):
                removals.insert(offset)
            case .insert(let offset, _, _):
                insertions.insert(offset)
            }
        }

        var chunks: [DiffChunk] = []
        var leftIndex = 0
        var rightIndex = 0

        func append(
            kind: DiffKind,
            leftStart: Int,
            leftEnd: Int,
            rightStart: Int,
            rightEnd: Int
        ) {
            guard leftStart != leftEnd ||
                  rightStart != rightEnd
            else {
                return
            }

            chunks.append(
                DiffChunk(
                    id: chunks.count,
                    kind: kind,
                    left: DiffLineRange(
                        lowerBound:
                            leftStart + leftOffset,
                        upperBound:
                            leftEnd + leftOffset
                    ),
                    right: DiffLineRange(
                        lowerBound:
                            rightStart + rightOffset,
                        upperBound:
                            rightEnd + rightOffset
                    )
                )
            )
        }

        while leftIndex < left.count ||
              rightIndex < right.count {
            if (leftIndex + rightIndex) % 250 == 0 {
                if Task.isCancelled {
                    return []
                }
            }

            let leftRemoved =
                leftIndex < left.count &&
                removals.contains(leftIndex)

            let rightInserted =
                rightIndex < right.count &&
                insertions.contains(rightIndex)

            if leftRemoved || rightInserted {
                let leftStart = leftIndex
                let rightStart = rightIndex

                while leftIndex < left.count &&
                      removals.contains(leftIndex) {
                    leftIndex += 1
                }

                while rightIndex < right.count &&
                      insertions.contains(rightIndex) {
                    rightIndex += 1
                }

                let leftCount =
                    leftIndex - leftStart
                let rightCount =
                    rightIndex - rightStart

                let kind: DiffKind
                if leftCount > 0 &&
                   rightCount > 0 {
                    kind = .replace
                } else if leftCount > 0 {
                    kind = .delete
                } else {
                    kind = .insert
                }

                append(
                    kind: kind,
                    leftStart: leftStart,
                    leftEnd: leftIndex,
                    rightStart: rightStart,
                    rightEnd: rightIndex
                )
                continue
            }

            if leftIndex < left.count,
               rightIndex < right.count,
               left[leftIndex] ==
               right[rightIndex] {
                let leftStart = leftIndex
                let rightStart = rightIndex

                while leftIndex < left.count,
                      rightIndex < right.count,
                      !removals.contains(leftIndex),
                      !insertions.contains(rightIndex),
                      left[leftIndex] ==
                      right[rightIndex] {
                    leftIndex += 1
                    rightIndex += 1
                }

                append(
                    kind: .equal,
                    leftStart: leftStart,
                    leftEnd: leftIndex,
                    rightStart: rightStart,
                    rightEnd: rightIndex
                )
                continue
            }

            let leftStart = leftIndex
            let rightStart = rightIndex

            if leftIndex < left.count {
                leftIndex += 1
            }

            if rightIndex < right.count {
                rightIndex += 1
            }

            append(
                kind: .replace,
                leftStart: leftStart,
                leftEnd: leftIndex,
                rightStart: rightStart,
                rightEnd: rightIndex
            )
        }

        return renumberAndCoalesce(chunks)
    }

    private func remapChunks(
        _ chunks: [DiffChunk],
        left: NormalizedText,
        right: NormalizedText
    ) -> [DiffChunk] {
        chunks.map { chunk in
            DiffChunk(
                id: chunk.id,
                kind: chunk.kind,
                left: DiffLineRange(
                    left.originalRange(
                        forNormalizedRange:
                            chunk.left.range
                    )
                ),
                right: DiffLineRange(
                    right.originalRange(
                        forNormalizedRange:
                            chunk.right.range
                    )
                )
            )
        }
    }

    private func renumberAndCoalesce(
        _ source: [DiffChunk]
    ) -> [DiffChunk] {
        var output: [DiffChunk] = []

        for chunk in source {
            if let last = output.last,
               last.kind == chunk.kind,
               last.left.upperBound ==
                    chunk.left.lowerBound,
               last.right.upperBound ==
                    chunk.right.lowerBound {
                output.removeLast()

                output.append(
                    DiffChunk(
                        id: last.id,
                        kind: last.kind,
                        left: DiffLineRange(
                            lowerBound:
                                last.left.lowerBound,
                            upperBound:
                                chunk.left.upperBound
                        ),
                        right: DiffLineRange(
                            lowerBound:
                                last.right.lowerBound,
                            upperBound:
                                chunk.right.upperBound
                        )
                    )
                )
            } else {
                output.append(
                    DiffChunk(
                        id: output.count,
                        kind: chunk.kind,
                        left: chunk.left,
                        right: chunk.right
                    )
                )
            }
        }

        return output.enumerated().map {
            index, chunk in
            DiffChunk(
                id: index,
                kind: chunk.kind,
                left: chunk.left,
                right: chunk.right
            )
        }
    }

    private func checkCancellation() throws {
        if Task.isCancelled {
            throw CancellationError()
        }
    }
}
