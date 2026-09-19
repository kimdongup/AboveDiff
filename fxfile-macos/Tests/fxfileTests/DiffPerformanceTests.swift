import XCTest
@testable import fxfileCore

final class DiffPerformanceTests:
    XCTestCase {

    func testLargeFilePolicy() {
        let policy =
            DiffLargeFilePolicy(
                characterThreshold: 10,
                lineThreshold: 100
            )

        XCTAssertTrue(
            policy.isLarge(
                text:
                    "1234567890"
            )
        )

        XCTAssertFalse(
            policy.isLarge(
                text:
                    "short"
            )
        )
    }

    func testCacheRoundTrip()
        throws {
        let cache =
            DiffResultCache(
                capacity: 2
            )

        let options =
            DiffOptions()

        let result =
            DiffResult(
                chunks: [],
                leftLineCount: 0,
                rightLineCount: 0,
                statistics:
                    DiffStatistics()
            )

        cache.insert(
            result,
            leftText: "a",
            rightText: "b",
            options: options
        )

        XCTAssertNotNil(
            cache.value(
                leftText: "a",
                rightText: "b",
                options: options
            )
        )
    }
}
