import XCTest
@testable import fxfileCore

final class ThreeWayMergeEngineTests: XCTestCase {
    private let diffEngine = ThreeWayDiffEngine()
    private let mergeEngine = ThreeWayMergeEngine()

    func testAutoMergeLocalOnly() throws {
        let diff = try makeDiff(
            local: "a\nL\n",
            base: "a\nb\n",
            remote: "a\nb\n"
        )

        let merge = mergeEngine.initialMerge(
            localText: "a\nL\n",
            baseText: "a\nb\n",
            remoteText: "a\nb\n",
            diff: diff
        )

        XCTAssertEqual(merge.unresolvedConflictCount, 0)
        XCTAssertTrue(merge.text.contains("L"))
    }

    func testAutoMergeRemoteOnly() throws {
        let diff = try makeDiff(
            local: "a\nb\n",
            base: "a\nb\n",
            remote: "a\nR\n"
        )

        let merge = mergeEngine.initialMerge(
            localText: "a\nb\n",
            baseText: "a\nb\n",
            remoteText: "a\nR\n",
            diff: diff
        )

        XCTAssertEqual(merge.unresolvedConflictCount, 0)
        XCTAssertTrue(merge.text.contains("R"))
    }

    func testConflictStartsUnresolved() throws {
        let diff = try makeDiff(
            local: "a\nL\n",
            base: "a\nb\n",
            remote: "a\nR\n"
        )

        let merge = mergeEngine.initialMerge(
            localText: "a\nL\n",
            baseText: "a\nb\n",
            remoteText: "a\nR\n",
            diff: diff
        )

        XCTAssertEqual(merge.unresolvedConflictCount, 1)
    }

    func testResolveUseLocal() throws {
        let local = "a\nL\n"
        let base = "a\nb\n"
        let remote = "a\nR\n"

        let diff = try makeDiff(
            local: local,
            base: base,
            remote: remote
        )

        let initial = mergeEngine.initialMerge(
            localText: local,
            baseText: base,
            remoteText: remote,
            diff: diff
        )

        guard let conflict = diff.conflicts.first else {
            XCTFail("Expected conflict")
            return
        }

        var states = initial.chunkStates

        guard let index = states.firstIndex(
            where: { $0.chunkID == conflict.id }
        ) else {
            XCTFail("Missing conflict state")
            return
        }

        states[index].decision = .useLocal
        states[index].isResolved = true

        let resolved = mergeEngine.resolve(
            localText: local,
            baseText: base,
            remoteText: remote,
            diff: diff,
            states: states
        )

        XCTAssertEqual(resolved.unresolvedConflictCount, 0)
        XCTAssertTrue(resolved.text.contains("L"))
    }

    func testResolveBothOrders() throws {
        let local = "a\nL\n"
        let base = "a\nb\n"
        let remote = "a\nR\n"

        let diff = try makeDiff(
            local: local,
            base: base,
            remote: remote
        )

        guard let conflict = diff.conflicts.first else {
            XCTFail("Expected conflict")
            return
        }

        var states = mergeEngine.initialMerge(
            localText: local,
            baseText: base,
            remoteText: remote,
            diff: diff
        ).chunkStates

        guard let index = states.firstIndex(
            where: { $0.chunkID == conflict.id }
        ) else {
            XCTFail("Missing conflict state")
            return
        }

        states[index].decision = .useBothLocalThenRemote
        states[index].isResolved = true

        let merge = mergeEngine.resolve(
            localText: local,
            baseText: base,
            remoteText: remote,
            diff: diff,
            states: states
        )

        XCTAssertTrue(merge.text.contains("L\nR"))
    }

    private func makeDiff(
        local: String,
        base: String,
        remote: String
    ) throws -> ThreeWayDiffResult {
        try diffEngine.compare(
            local: ThreeWayDocument(text: local),
            base: ThreeWayDocument(text: base),
            remote: ThreeWayDocument(text: remote),
            options: ThreeWayDiffOptions()
        )
    }
}
