import XCTest
@testable import fxfileCore

final class GitRepositoryServiceTests:
    XCTestCase {

    func testRepositoryRootAndStatus()
        throws {
        let fixture =
            try GitTestFixture()

        defer {
            fixture.cleanup()
        }

        let service =
            GitRepositoryService()

        let root =
            try service.repositoryRoot(
                for: fixture.fileURL
            )

        XCTAssertEqual(
            root?.standardizedFileURL,
            fixture.root
                .standardizedFileURL
        )

        try "changed\n".write(
            to: fixture.fileURL,
            atomically: true,
            encoding: .utf8
        )

        let items =
            try service.status(
                repositoryRoot:
                    fixture.root,
                relativePath:
                    "sample.txt"
            )

        XCTAssertEqual(
            items.first?.relativePath,
            "sample.txt"
        )

        XCTAssertEqual(
            items.first?
                .workTreeStatus,
            .modified
        )
    }

    func testNonRepositoryReturnsNil()
        throws {
        let directory =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )

        try FileManager.default
            .createDirectory(
                at: directory,
                withIntermediateDirectories:
                    true
            )

        defer {
            try? FileManager.default
                .removeItem(
                    at: directory
                )
        }

        let service =
            GitRepositoryService()

        XCTAssertNil(
            try service.repositoryRoot(
                for: directory
            )
        )
    }
}

private final class GitTestFixture {
    let root: URL
    let fileURL: URL

    init() throws {
        root =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )

        try FileManager.default
            .createDirectory(
                at: root,
                withIntermediateDirectories:
                    true
            )

        let runner =
            GitCommandRunner()

        _ = try runner.run(
            arguments: [
                "init",
                root.path
            ],
            currentDirectory: nil,
            allowFailure: false
        )

        _ = try runner.run(
            arguments: [
                "-C",
                root.path,
                "config",
                "user.email",
                "fxfile@example.test"
            ],
            currentDirectory: nil,
            allowFailure: false
        )

        _ = try runner.run(
            arguments: [
                "-C",
                root.path,
                "config",
                "user.name",
                "AboveDiff Tests"
            ],
            currentDirectory: nil,
            allowFailure: false
        )

        fileURL =
            root.appendingPathComponent(
                "sample.txt"
            )

        try "base\n".write(
            to: fileURL,
            atomically: true,
            encoding: .utf8
        )

        _ = try runner.run(
            arguments: [
                "-C",
                root.path,
                "add",
                "sample.txt"
            ],
            currentDirectory: nil,
            allowFailure: false
        )

        _ = try runner.run(
            arguments: [
                "-C",
                root.path,
                "commit",
                "-m",
                "initial"
            ],
            currentDirectory: nil,
            allowFailure: false
        )
    }

    func cleanup() {
        try? FileManager.default
            .removeItem(
                at: root
            )
    }
}
