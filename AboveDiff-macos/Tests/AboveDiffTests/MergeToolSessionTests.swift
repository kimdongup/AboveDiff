import XCTest
@testable import AboveDiffCore

final class MergeToolSessionTests: XCTestCase {
    func testRequestAndResultRoundTrip() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )

        defer {
            try? FileManager.default.removeItem(
                at: root
            )
        }

        let store = try MergeToolSessionStore(
            rootDirectory: root
        )

        let request = MergeToolSessionRequest(
            arguments: GitMergeToolArguments(
                baseURL: URL(fileURLWithPath: "/tmp/base"),
                localURL: URL(fileURLWithPath: "/tmp/local"),
                remoteURL: URL(fileURLWithPath: "/tmp/remote"),
                mergedURL: URL(fileURLWithPath: "/tmp/merged")
            )
        )

        try store.writeRequest(request)

        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: store.requestURL(
                    for: request.id
                ).path
            )
        )

        let result = MergeToolSessionResult(
            sessionID: request.id,
            outcome: .resolved,
            exitStatus: .success
        )

        try store.writeResult(result)

        let decoded = try store.readResult(
            sessionID: request.id
        )

        XCTAssertEqual(decoded, result)

        try store.removeSession(
            sessionID: request.id
        )

        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: store.sessionDirectory(
                    for: request.id
                ).path
            )
        )
    }
}
