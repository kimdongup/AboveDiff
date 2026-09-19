import XCTest
@testable import fxfileCore

final class DirectorySyncPlannerTests: XCTestCase {
    func testMirrorDeletesRightOnlyItem() {
        let item = DirectoryCompareItem(
            relativePath: "extra.txt",
            left: nil,
            right: DirectoryEntryMetadata(
                url: URL(fileURLWithPath: "/right/extra.txt"),
                isDirectory: false,
                size: 1,
                modificationDate: nil
            ),
            status: .rightOnly
        )

        let plan = DirectorySyncPlanner().makePlan(
            items: [item],
            policy: .leftToRightMirror
        )

        XCTAssertEqual(plan.operations.count, 1)
        XCTAssertEqual(plan.operations.first?.kind, .deleteRight)
    }

    func testUpdateIgnoresRightOnlyItem() {
        let item = DirectoryCompareItem(
            relativePath: "extra.txt",
            left: nil,
            right: DirectoryEntryMetadata(
                url: URL(fileURLWithPath: "/right/extra.txt"),
                isDirectory: false,
                size: 1,
                modificationDate: nil
            ),
            status: .rightOnly
        )

        let plan = DirectorySyncPlanner().makePlan(
            items: [item],
            policy: .leftToRightUpdate
        )

        XCTAssertTrue(plan.operations.isEmpty)
    }
}
