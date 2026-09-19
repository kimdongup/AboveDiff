import Foundation

public protocol ThreeWayMerging: Sendable {
    func initialMerge(
        localText: String,
        baseText: String,
        remoteText: String,
        diff: ThreeWayDiffResult
    ) -> ThreeWayMergeResult

    func resolve(
        localText: String,
        baseText: String,
        remoteText: String,
        diff: ThreeWayDiffResult,
        states: [MergeChunkState]
    ) -> ThreeWayMergeResult
}

public struct ThreeWayMergeEngine: ThreeWayMerging {
    public init() {}

    public func initialMerge(
        localText: String,
        baseText: String,
        remoteText: String,
        diff: ThreeWayDiffResult
    ) -> ThreeWayMergeResult {
        let states = diff.chunks.map { chunk -> MergeChunkState in
            switch chunk.kind {
            case .equal:
                return MergeChunkState(
                    chunkID: chunk.id,
                    decision: .useBase,
                    isResolved: true
                )
            case .localOnly:
                return MergeChunkState(
                    chunkID: chunk.id,
                    decision: .useLocal,
                    isResolved: true
                )
            case .remoteOnly:
                return MergeChunkState(
                    chunkID: chunk.id,
                    decision: .useRemote,
                    isResolved: true
                )
            case .sameChange:
                return MergeChunkState(
                    chunkID: chunk.id,
                    decision: .useLocal,
                    isResolved: true
                )
            case .conflict:
                return MergeChunkState(
                    chunkID: chunk.id,
                    decision: nil,
                    isResolved: false
                )
            }
        }

        return resolve(
            localText: localText,
            baseText: baseText,
            remoteText: remoteText,
            diff: diff,
            states: states
        )
    }

    public func resolve(
        localText: String,
        baseText: String,
        remoteText: String,
        diff: ThreeWayDiffResult,
        states: [MergeChunkState]
    ) -> ThreeWayMergeResult {
        let localLines = splitLines(localText)
        let baseLines = splitLines(baseText)
        let remoteLines = splitLines(remoteText)

        let stateByChunk = Dictionary(
            uniqueKeysWithValues: states.map {
                ($0.chunkID, $0)
            }
        )

        var output: [String] = []

        for chunk in diff.chunks {
            let state = stateByChunk[chunk.id]

            guard let decision = state?.decision else {
                // unresolved conflict: keep BASE in result until user resolves
                output.append(
                    contentsOf: slice(
                        baseLines,
                        range: chunk.base.range
                    )
                )
                continue
            }

            switch decision {
            case .useLocal:
                output.append(
                    contentsOf: slice(
                        localLines,
                        range: chunk.local.range
                    )
                )

            case .useRemote:
                output.append(
                    contentsOf: slice(
                        remoteLines,
                        range: chunk.remote.range
                    )
                )

            case .useBase:
                output.append(
                    contentsOf: slice(
                        baseLines,
                        range: chunk.base.range
                    )
                )

            case .useBothLocalThenRemote:
                output.append(
                    contentsOf: slice(
                        localLines,
                        range: chunk.local.range
                    )
                )
                output.append(
                    contentsOf: slice(
                        remoteLines,
                        range: chunk.remote.range
                    )
                )

            case .useBothRemoteThenLocal:
                output.append(
                    contentsOf: slice(
                        remoteLines,
                        range: chunk.remote.range
                    )
                )
                output.append(
                    contentsOf: slice(
                        localLines,
                        range: chunk.local.range
                    )
                )
            }
        }

        let unresolved = states.filter {
            !$0.isResolved
        }.count

        return ThreeWayMergeResult(
            text: joinLines(output),
            chunkStates: states,
            unresolvedConflictCount: unresolved
        )
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

    private func joinLines(
        _ lines: [String]
    ) -> String {
        guard !lines.isEmpty else {
            return ""
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private func slice(
        _ lines: [String],
        range: Range<Int>
    ) -> [String] {
        guard !range.isEmpty,
              range.lowerBound < lines.count
        else {
            return []
        }

        let lower = min(
            max(0, range.lowerBound),
            lines.count
        )

        let upper = min(
            max(lower, range.upperBound),
            lines.count
        )

        return Array(lines[lower..<upper])
    }
}
