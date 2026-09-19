import XCTest
@testable import fxfileCore

final class GitBlobLoaderTests:
    XCTestCase {

    func testLoadHeadAndWorkingTree()
        throws {
        let root =
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

        defer {
            try? FileManager.default
                .removeItem(
                    at: root
                )
        }

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

        let file =
            root.appendingPathComponent(
                "a.txt"
            )

        try "HEAD value\n".write(
            to: file,
            atomically: true,
            encoding: .utf8
        )

        _ = try runner.run(
            arguments: [
                "-C",
                root.path,
                "add",
                "a.txt"
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

        try "working value\n".write(
            to: file,
            atomically: true,
            encoding: .utf8
        )

        let loader =
            GitBlobLoader()

        let head =
            try loader.load(
                repositoryRoot:
                    root,
                relativePath:
                    "a.txt",
                revision:
                    .head
            )

        let working =
            try loader.load(
                repositoryRoot:
                    root,
                relativePath:
                    "a.txt",
                revision:
                    .workingTree
            )

        XCTAssertEqual(
            head.utf8Text,
            "HEAD value\n"
        )

        XCTAssertEqual(
            working.utf8Text,
            "working value\n"
        )
    }
}
