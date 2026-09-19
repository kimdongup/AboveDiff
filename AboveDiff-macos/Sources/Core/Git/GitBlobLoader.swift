import Foundation

public struct GitBlob: Sendable, Hashable {
    public let revision: GitRevision
    public let relativePath: String
    public let data: Data

    public init(
        revision: GitRevision,
        relativePath: String,
        data: Data
    ) {
        self.revision = revision
        self.relativePath = relativePath
        self.data = data
    }

    public var isBinary: Bool {
        data.prefix(8_192).contains(0)
    }

    public var utf8Text: String? {
        String(
            data: data,
            encoding: .utf8
        )
    }
}

public enum GitBlobError: LocalizedError, Sendable, Equatable {
    case workingTreeFileMissing(String)
    case binaryFile(String)
    case unsupportedRevision(GitRevision)

    public var errorDescription: String? {
        switch self {
        case .workingTreeFileMissing(let path):
            return "Working tree file does not exist: \(path)"

        case .binaryFile(let path):
            return "Binary Git blob cannot be opened as text: \(path)"

        case .unsupportedRevision(let revision):
            return "Unsupported Git revision: \(revision.displayName)"
        }
    }
}

public protocol GitBlobLoading: Sendable {
    func load(
        repositoryRoot: URL,
        relativePath: String,
        revision: GitRevision
    ) throws -> GitBlob
}

public final class GitBlobLoader:
    @unchecked Sendable,
    GitBlobLoading {

    public static let shared =
        GitBlobLoader()

    private let runner:
        any GitCommandRunning

    public init(
        runner:
            any GitCommandRunning =
                GitCommandRunner.shared
    ) {
        self.runner = runner
    }

    public func load(
        repositoryRoot: URL,
        relativePath: String,
        revision: GitRevision
    ) throws -> GitBlob {
        switch revision {
        case .workingTree:
            let url =
                repositoryRoot
                .appendingPathComponent(
                    relativePath
                )

            guard FileManager.default
                .fileExists(
                    atPath: url.path
                )
            else {
                throw GitBlobError
                    .workingTreeFileMissing(
                        relativePath
                    )
            }

            return GitBlob(
                revision: revision,
                relativePath: relativePath,
                data: try Data(
                    contentsOf: url
                )
            )

        case .index:
            return try gitShow(
                spec: ":\(relativePath)",
                repositoryRoot:
                    repositoryRoot,
                relativePath:
                    relativePath,
                revision:
                    revision
            )

        case .head:
            return try gitShow(
                spec: "HEAD:\(relativePath)",
                repositoryRoot:
                    repositoryRoot,
                relativePath:
                    relativePath,
                revision:
                    revision
            )

        case .mergeBase:
            return try gitShow(
                spec: ":1:\(relativePath)",
                repositoryRoot:
                    repositoryRoot,
                relativePath:
                    relativePath,
                revision:
                    revision
            )

        case .ours:
            return try gitShow(
                spec: ":2:\(relativePath)",
                repositoryRoot:
                    repositoryRoot,
                relativePath:
                    relativePath,
                revision:
                    revision
            )

        case .theirs:
            return try gitShow(
                spec: ":3:\(relativePath)",
                repositoryRoot:
                    repositoryRoot,
                relativePath:
                    relativePath,
                revision:
                    revision
            )

        case .custom(let value):
            return try gitShow(
                spec:
                    "\(value):\(relativePath)",
                repositoryRoot:
                    repositoryRoot,
                relativePath:
                    relativePath,
                revision:
                    revision
            )
        }
    }

    private func gitShow(
        spec: String,
        repositoryRoot: URL,
        relativePath: String,
        revision: GitRevision
    ) throws -> GitBlob {
        let result = try runner.run(
            arguments: [
                "-C",
                repositoryRoot.path,
                "show",
                "--no-ext-diff",
                spec
            ],
            currentDirectory: nil,
            allowFailure: false
        )

        return GitBlob(
            revision: revision,
            relativePath: relativePath,
            data: result.stdout
        )
    }
}
