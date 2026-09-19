import XCTest
@testable import fxfileCore

final class DiffEngineTests: XCTestCase {
    private let engine = LineDiffEngine()

    func testEqual() throws {
        let result = try engine.compare(
            left: DiffDocument(
                text: "a\nb\nc\n"
            ),
            right: DiffDocument(
                text: "a\nb\nc\n"
            ),
            options: DiffOptions()
        )

        XCTAssertTrue(result.isIdentical)
        XCTAssertEqual(result.chunks.count, 1)
        XCTAssertEqual(
            result.chunks.first?.kind,
            .equal
        )
    }

    func testInsert() throws {
        let result = try engine.compare(
            left: DiffDocument(
                text: "a\nc\n"
            ),
            right: DiffDocument(
                text: "a\nb\nc\n"
            ),
            options: DiffOptions()
        )

        XCTAssertEqual(
            result.changes.count,
            1
        )

        XCTAssertEqual(
            result.changes.first?.kind,
            .insert
        )

        XCTAssertEqual(
            result.changes.first?.right.count,
            1
        )
    }

    func testDelete() throws {
        let result = try engine.compare(
            left: DiffDocument(
                text: "a\nb\nc\n"
            ),
            right: DiffDocument(
                text: "a\nc\n"
            ),
            options: DiffOptions()
        )

        XCTAssertEqual(
            result.changes.count,
            1
        )

        XCTAssertEqual(
            result.changes.first?.kind,
            .delete
        )

        XCTAssertEqual(
            result.changes.first?.left.count,
            1
        )
    }

    func testReplace() throws {
        let result = try engine.compare(
            left: DiffDocument(
                text: "a\nold\nc\n"
            ),
            right: DiffDocument(
                text: "a\nnew\nc\n"
            ),
            options: DiffOptions()
        )

        XCTAssertEqual(
            result.changes.count,
            1
        )

        XCTAssertEqual(
            result.changes.first?.kind,
            .replace
        )
    }

    func testSeparatedChanges() throws {
        let result = try engine.compare(
            left: DiffDocument(
                text: "a\nold1\nc\nold2\ne\n"
            ),
            right: DiffDocument(
                text: "a\nnew1\nc\nnew2\ne\n"
            ),
            options: DiffOptions()
        )

        XCTAssertEqual(
            result.changes.count,
            2
        )
    }

    func testLineEndingNormalization() throws {
        let result = try engine.compare(
            left: DiffDocument(
                text: "a\r\nb\r\n"
            ),
            right: DiffDocument(
                text: "a\nb\n"
            ),
            options: DiffOptions()
        )

        XCTAssertTrue(result.isIdentical)
    }

    func testUnicode() throws {
        let result = try engine.compare(
            left: DiffDocument(
                text: "가\n나\n"
            ),
            right: DiffDocument(
                text: "가\n다\n"
            ),
            options: DiffOptions()
        )

        XCTAssertEqual(
            result.changes.count,
            1
        )

        XCTAssertEqual(
            result.changes.first?.kind,
            .replace
        )
    }
}
