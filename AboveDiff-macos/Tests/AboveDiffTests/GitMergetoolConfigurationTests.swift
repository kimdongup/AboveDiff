import XCTest
@testable import AboveDiffCore

final class GitMergetoolConfigurationTests: XCTestCase {
    func testDefaultConfiguration() {
        let config = GitMergetoolConfiguration()

        XCTAssertEqual(
            config.toolName,
            "abovediff"
        )

        XCTAssertTrue(
            config.command.contains(
                "--mergetool"
            )
        )

        XCTAssertTrue(
            config.command.contains(
                #""$BASE""#
            )
        )

        XCTAssertTrue(
            config.trustExitCode
        )
    }
}
