import XCTest
@testable import AboveDiffCore

final class GitSelectionCapabilitiesTests:
    XCTestCase {

    func testConflictOnlyEnablesResolver() {
        let value =
            GitSelectionCapabilities(
                isRepository: true,
                isFile: true,
                isTracked: true,
                hasWorkingTreeChanges:
                    true,
                hasStagedChanges:
                    true,
                isConflicted:
                    true
            )

        XCTAssertTrue(
            value.canResolveConflict
        )

        XCTAssertFalse(
            value
            .canCompareWorkingTreeWithHEAD
        )

        XCTAssertFalse(
            value
            .canCompareStagedWithHEAD
        )
    }

    func testStagedTrackedFile() {
        let value =
            GitSelectionCapabilities(
                isRepository: true,
                isFile: true,
                isTracked: true,
                hasWorkingTreeChanges:
                    false,
                hasStagedChanges:
                    true,
                isConflicted:
                    false
            )

        XCTAssertTrue(
            value
            .canCompareWorkingTreeWithHEAD
        )

        XCTAssertTrue(
            value
            .canCompareStagedWithHEAD
        )

        XCTAssertTrue(
            value
            .canCompareWorkingTreeWithStaged
        )
    }

    func testUntrackedFileDisablesGitDiffs() {
        let value =
            GitSelectionCapabilities(
                isRepository: true,
                isFile: true,
                isTracked: false,
                hasWorkingTreeChanges:
                    true,
                hasStagedChanges:
                    false,
                isConflicted:
                    false
            )

        XCTAssertFalse(
            value
            .canCompareWorkingTreeWithHEAD
        )

        XCTAssertFalse(
            value
            .canCompareWorkingTreeWithStaged
        )
    }
}
