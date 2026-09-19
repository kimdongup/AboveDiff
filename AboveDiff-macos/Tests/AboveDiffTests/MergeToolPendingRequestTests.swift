import XCTest
@testable import AboveDiffCore

final class MergeToolPendingRequestTests: XCTestCase {
    func testPendingRequestDisappearsAfterResult() throws {
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

        XCTAssertEqual(
            try store.pendingRequests().map(\.id),
            [request.id]
        )

        try store.writeResult(
            MergeToolSessionResult(
                sessionID: request.id,
                outcome: .resolved,
                exitStatus: .success
            )
        )

        XCTAssertTrue(
            try store.pendingRequests().isEmpty
        )
    }
}
