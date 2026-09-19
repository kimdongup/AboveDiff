import XCTest
@testable import fxfileCore

final class GitConflictServiceTests:
    XCTestCase {

    func testStageResolvedRunsGitAdd()
        throws {
        let runner =
            RecordingGitRunner()

        let service =
            GitConflictService(
                repositoryService:
                    StubRepositoryService(),
                materializer:
                    GitCompareMaterializer(
                        blobLoader:
                            StubBlobLoader()
                    ),
                runner:
                    runner
            )

        let root =
            URL(
                fileURLWithPath:
                    "/tmp/repo"
            )

        let descriptor =
            GitConflictDescriptor(
                repositoryRoot:
                    root,
                relativePath:
                    "a.txt",
                workingTreeURL:
                    root
                    .appendingPathComponent(
                        "a.txt"
                    ),
                baseURL:
                    root
                    .appendingPathComponent(
                        "base"
                    ),
                oursURL:
                    root
                    .appendingPathComponent(
                        "ours"
                    ),
                theirsURL:
                    root
                    .appendingPathComponent(
                        "theirs"
                    )
            )

        try service.stageResolved(
            descriptor:
                descriptor
        )

        XCTAssertEqual(
            runner.lastArguments,
            [
                "-C",
                "/tmp/repo",
                "add",
                "--",
                "a.txt"
            ]
        )
    }
}

private final class RecordingGitRunner:
    @unchecked Sendable,
    GitCommandRunning {

    var lastArguments:
        [String] = []

    func run(
        arguments: [String],
        currentDirectory: URL?,
        allowFailure: Bool
    ) throws -> GitCommandResult {
        lastArguments =
            arguments

        return GitCommandResult(
            exitCode: 0,
            stdout: Data(),
            stderr: Data()
        )
    }
}

private struct StubRepositoryService:
    GitRepositoryServicing {

    func repositoryRoot(
        for url: URL
    ) throws -> URL? {
        URL(
            fileURLWithPath:
                "/tmp/repo"
        )
    }

    func relativePath(
        for url: URL,
        repositoryRoot: URL
    ) throws -> String {
        "a.txt"
    }

    func status(
        repositoryRoot: URL,
        relativePath: String?
    ) throws -> [GitStatusItem] {
        [
            GitStatusItem(
                relativePath:
                    "a.txt",
                indexStatus:
                    .conflicted,
                workTreeStatus:
                    .conflicted,
                isConflicted:
                    true
            )
        ]
    }

    func currentBranch(
        repositoryRoot: URL
    ) throws -> String? {
        "main"
    }
}

private struct StubBlobLoader:
    GitBlobLoading {

    func load(
        repositoryRoot: URL,
        relativePath: String,
        revision: GitRevision
    ) throws -> GitBlob {
        GitBlob(
            revision:
                revision,
            relativePath:
                relativePath,
            data:
                Data(
                    "x\n".utf8
                )
        )
    }
}
