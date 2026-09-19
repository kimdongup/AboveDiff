import XCTest
@testable import AboveDiffCore

final class TextFileGuardTests:
    XCTestCase {

    func testTextData() {
        let guardService =
            TextFileGuard(
                policy:
                    TextFileGuardPolicy(
                        maximumBytes: 100
                    )
            )

        XCTAssertEqual(
            guardService.inspect(
                data: Data(
                    "hello\nworld\n".utf8
                )
            ),
            .text
        )
    }

    func testBinaryData() {
        let guardService =
            TextFileGuard()

        XCTAssertEqual(
            guardService.inspect(
                data: Data(
                    [0x41, 0x00, 0x42]
                )
            ),
            .binary
        )
    }

    func testTooLarge() {
        let guardService =
            TextFileGuard(
                policy:
                    TextFileGuardPolicy(
                        maximumBytes: 3
                    )
            )

        let result =
            guardService.inspect(
                data: Data(
                    "1234".utf8
                )
            )

        guard case .tooLarge(
            let byteCount
        ) = result
        else {
            XCTFail(
                "Expected tooLarge"
            )
            return
        }

        XCTAssertEqual(
            byteCount,
            4
        )
    }
}
