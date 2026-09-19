import XCTest
@testable import fxfileCore

final class DirectoryNameFilterTests:
    XCTestCase {

    func testGlobInclude() {
        let filter =
            DirectoryNameFilter(
                includePattern:
                    "*.swift"
            )

        XCTAssertTrue(
            filter.matches(
                relativePath:
                    "Sources/App.swift"
            )
        )

        XCTAssertFalse(
            filter.matches(
                relativePath:
                    "README.md"
            )
        )
    }

    func testGlobExclude() {
        let filter =
            DirectoryNameFilter(
                excludePattern:
                    "*.tmp"
            )

        XCTAssertFalse(
            filter.matches(
                relativePath:
                    "cache/a.tmp"
            )
        )

        XCTAssertTrue(
            filter.matches(
                relativePath:
                    "cache/a.txt"
            )
        )
    }

    func testRegex() {
        let filter =
            DirectoryNameFilter(
                includePattern:
                    #"^Test.*\.swift$"#,
                useRegex: true
            )

        XCTAssertTrue(
            filter.matches(
                relativePath:
                    "Tests/TestA.swift"
            )
        )
    }
}
