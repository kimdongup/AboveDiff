import XCTest
@testable import AboveDiffCore

final class DiffOptionsTests: XCTestCase {
    private let engine = LineDiffEngine()

    func testIgnoreBlankLinesMakesDocumentsEqual() throws {
        let result = try engine.compare(
            left: DiffDocument(
                text: "a\n\nb\n"
            ),
            right: DiffDocument(
                text: "a\nb\n"
            ),
            options: DiffOptions(
                ignoreBlankLines: true
            )
        )

        XCTAssertTrue(result.isIdentical)
    }

    func testRegexFilterMakesDocumentsEqual() throws {
        let result = try engine.compare(
            left: DiffDocument(
                text: "timestamp=123\nvalue=x\n"
            ),
            right: DiffDocument(
                text: "timestamp=999\nvalue=x\n"
            ),
            options: DiffOptions(
                regexFilters: [
                    RegexTextFilter(
                        pattern: #"timestamp=\d+"#,
                        replacement: "timestamp=<ignored>"
                    )
                ]
            )
        )

        XCTAssertTrue(result.isIdentical)
    }

    func testSyncPointProducesAnchoredChunk() throws {
        let result = try engine.compare(
            left: DiffDocument(
                text: "a\nL\nx\n"
            ),
            right: DiffDocument(
                text: "a\nR\nx\n"
            ),
            options: DiffOptions(
                syncPoints: [
                    DiffSyncPoint(
                        leftLine: 1,
                        rightLine: 1
                    )
                ]
            )
        )

        XCTAssertFalse(result.isIdentical)
        XCTAssertEqual(
            result.changes.first?.kind,
            .replace
        )
    }
}
