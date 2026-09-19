import XCTest
@testable import AboveDiffCore

final class ThreeWayDiffEngineTests: XCTestCase {
    private let engine = ThreeWayDiffEngine()

    func testAllEqual() throws {
        let result = try compare(
            local: "a\nb\n",
            base: "a\nb\n",
            remote: "a\nb\n"
        )

        XCTAssertTrue(result.isIdentical)
        XCTAssertEqual(
            result.statistics.conflictChunks,
            0
        )
    }

    func testLocalOnlyChange() throws {
        let result = try compare(
            local: "a\nLOCAL\n",
            base: "a\nb\n",
            remote: "a\nb\n"
        )

        XCTAssertTrue(
            result.changes.contains {
                $0.kind == .localOnly
            }
        )
    }

    func testRemoteOnlyChange() throws {
        let result = try compare(
            local: "a\nb\n",
            base: "a\nb\n",
            remote: "a\nREMOTE\n"
        )

        XCTAssertTrue(
            result.changes.contains {
                $0.kind == .remoteOnly
            }
        )
    }

    func testSameChange() throws {
        let result = try compare(
            local: "a\nX\n",
            base: "a\nb\n",
            remote: "a\nX\n"
        )

        XCTAssertTrue(
            result.changes.contains {
                $0.kind == .sameChange
            }
        )
    }

    func testConflict() throws {
        let result = try compare(
            local: "a\nLOCAL\n",
            base: "a\nb\n",
            remote: "a\nREMOTE\n"
        )

        XCTAssertTrue(
            result.changes.contains {
                $0.kind == .conflict
            }
        )

        XCTAssertEqual(
            result.statistics.conflictChunks,
            1
        )
    }

    func testUnicodeConflict() throws {
        let result = try compare(
            local: "가\n로컬\n",
            base: "가\n기준\n",
            remote: "가\n원격\n"
        )

        XCTAssertTrue(
            result.changes.contains {
                $0.kind == .conflict
            }
        )
    }

    private func compare(
        local: String,
        base: String,
        remote: String
    ) throws -> ThreeWayDiffResult {
        try engine.compare(
            local: ThreeWayDocument(text: local),
            base: ThreeWayDocument(text: base),
            remote: ThreeWayDocument(text: remote),
            options: ThreeWayDiffOptions()
        )
    }
}
