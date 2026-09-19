import XCTest
@testable import fxfileCore

final class DiffEditEngineTests:
    XCTestCase {
    private let diffEngine =
        LineDiffEngine()

    private let editEngine =
        DiffEditEngine()

    func testReplaceLeftToRight()
        throws {
        let left =
            "a\nleft\nc\n"
        let right =
            "a\nright\nc\n"

        let result =
            try diffEngine.compare(
                left:
                    DiffDocument(
                        text: left
                    ),
                right:
                    DiffDocument(
                        text: right
                    ),
                options:
                    DiffOptions()
            )

        let chunk =
            try XCTUnwrap(
                result.changes.first
            )

        let edited =
            try editEngine.apply(
                chunk: chunk,
                from: .left,
                leftText: left,
                rightText: right
            )

        XCTAssertEqual(
            edited.rightText,
            left
        )
    }

    func testReplaceRightToLeft()
        throws {
        let left =
            "a\nleft\nc\n"
        let right =
            "a\nright\nc\n"

        let result =
            try diffEngine.compare(
                left:
                    DiffDocument(
                        text: left
                    ),
                right:
                    DiffDocument(
                        text: right
                    ),
                options:
                    DiffOptions()
            )

        let chunk =
            try XCTUnwrap(
                result.changes.first
            )

        let edited =
            try editEngine.apply(
                chunk: chunk,
                from: .right,
                leftText: left,
                rightText: right
            )

        XCTAssertEqual(
            edited.leftText,
            right
        )
    }

    func testInsertLeftToRight()
        throws {
        let left =
            "a\nb\nc\n"
        let right =
            "a\nc\n"

        let result =
            try diffEngine.compare(
                left:
                    DiffDocument(
                        text: left
                    ),
                right:
                    DiffDocument(
                        text: right
                    ),
                options:
                    DiffOptions()
            )

        let chunk =
            try XCTUnwrap(
                result.changes.first
            )

        let edited =
            try editEngine.apply(
                chunk: chunk,
                from: .left,
                leftText: left,
                rightText: right
            )

        XCTAssertEqual(
            edited.rightText,
            left
        )
    }
}
