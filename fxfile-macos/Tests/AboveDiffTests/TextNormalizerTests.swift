import XCTest
@testable import AboveDiffCore

final class TextNormalizerTests: XCTestCase {
    func testIgnoreBlankLines() throws {
        let normalizer = TextNormalizer()

        let result = try normalizer.normalize(
            text: "a\n\nb\n",
            options: TextNormalizationOptions(
                ignoreBlankLines: true
            )
        )

        XCTAssertEqual(
            result.lines,
            ["a", "b"]
        )

        XCTAssertEqual(
            result.originalLineIndices,
            [0, 2]
        )
    }

    func testRegexFilter() throws {
        let normalizer = TextNormalizer()

        let result = try normalizer.normalize(
            text: "time=123\nvalue=1\n",
            options: TextNormalizationOptions(
                regexFilters: [
                    RegexTextFilter(
                        pattern: #"time=\d+"#,
                        replacement: "time=<ignored>"
                    )
                ]
            )
        )

        XCTAssertEqual(
            result.lines.first,
            "time=<ignored>"
        )
    }

    func testInvalidRegex() {
        XCTAssertThrowsError(
            try TextNormalizer().normalize(
                text: "x",
                options: TextNormalizationOptions(
                    regexFilters: [
                        RegexTextFilter(
                            pattern: "["
                        )
                    ]
                )
            )
        )
    }
}
