import XCTest
@testable import AboveDiffCore

final class MergeToolSessionMaintenanceTests:
    XCTestCase {

    func testRemovesStaleSession()
        throws {
        let root =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory:
                    true
            )

        defer {
            try? FileManager
                .default
                .removeItem(
                    at: root
                )
        }

        let store =
            try MergeToolSessionStore(
                rootDirectory:
                    root
            )

        let request =
            MergeToolSessionRequest(
                arguments:
                    GitMergeToolArguments(
                        baseURL:
                            URL(
                                fileURLWithPath:
                                    "/tmp/base"
                            ),
                        localURL:
                            URL(
                                fileURLWithPath:
                                    "/tmp/local"
                            ),
                        remoteURL:
                            URL(
                                fileURLWithPath:
                                    "/tmp/remote"
                            ),
                        mergedURL:
                            URL(
                                fileURLWithPath:
                                    "/tmp/merged"
                            )
                    )
            )

        try store.writeRequest(
            request
        )

        let directory =
            store.sessionDirectory(
                for: request.id
            )

        let oldDate =
            Date()
            .addingTimeInterval(
                -3600
            )

        try FileManager.default
            .setAttributes(
                [
                    .modificationDate:
                        oldDate
                ],
                ofItemAtPath:
                    directory.path
            )

        let maintenance =
            MergeToolSessionMaintenance(
                sessionStore:
                    store,
                staleAge:
                    60
            )

        let count =
            try maintenance
            .removeStaleSessions()

        XCTAssertEqual(
            count,
            1
        )

        XCTAssertFalse(
            FileManager.default
                .fileExists(
                    atPath:
                        directory.path
                )
        )
    }
}
