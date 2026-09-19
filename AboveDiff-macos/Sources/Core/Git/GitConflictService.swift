import Foundation

public struct GitConflictDescriptor: Sendable, Hashable {
    public let repositoryRoot: URL
    public let relativePath: String
    public let workingTreeURL: URL

    public let baseURL: URL
    public let oursURL: URL
    public let theirsURL: URL

    public init(
        repositoryRoot: URL,
        relativePath: String,
        workingTreeURL: URL,
        baseURL: URL,
        oursURL: URL,
        theirsURL: URL
    ) {
        self.repositoryRoot = repositoryRoot
        self.relativePath = relativePath
        self.workingTreeURL = workingTreeURL
        self.baseURL = baseURL
        self.oursURL = oursURL
        self.theirsURL = theirsURL
    }
}

public enum GitConflictServiceError:
    LocalizedError,
    Sendable,
    Equatable {

    case notRepository
    case notConflicted(String)

    public var errorDescription: String? {
        switch self {
        case .notRepository:
            return "The selected file is not inside a Git repository."

        case .notConflicted(let path):
            return "The selected file does not have an active Git conflict: \(path)"
        }
    }
}

public protocol GitConflictServicing: Sendable {
    func prepare(
        fileURL: URL
    ) throws -> GitConflictDescriptor

    func stageResolved(
        descriptor: GitConflictDescriptor
    ) throws

    func isStillConflicted(
        descriptor: GitConflictDescriptor
    ) throws -> Bool
}

public final class GitConflictService:
    @unchecked Sendable,
    GitConflictServicing {

    public static let shared =
        GitConflictService()

    private let repositoryService:
        any GitRepositoryServicing

    private let materializer:
        GitCompareMaterializer

    private let runner:
        any GitCommandRunning

    public init(
        repositoryService:
            any GitRepositoryServicing =
                GitRepositoryService.shared,
        materializer:
            GitCompareMaterializer =
                .shared,
        runner:
            any GitCommandRunning =
                GitCommandRunner.shared
    ) {
        self.repositoryService =
            repositoryService
        self.materializer =
            materializer
        self.runner =
            runner
    }

    public func prepare(
        fileURL: URL
    ) throws -> GitConflictDescriptor {
        guard let root =
            try repositoryService
            .repositoryRoot(
                for: fileURL
            )
        else {
            throw GitConflictServiceError
                .notRepository
        }

        let relative =
            try repositoryService
            .relativePath(
                for: fileURL,
                repositoryRoot:
                    root
            )

        let status =
            try repositoryService
            .status(
                repositoryRoot:
                    root,
                relativePath:
                    relative
            )

        guard status.first?
            .isConflicted == true
        else {
            throw GitConflictServiceError
                .notConflicted(
                    relative
                )
        }

        let materialized =
            try materializer
            .materializeConflict(
                repositoryRoot:
                    root,
                relativePath:
                    relative
            )

        return GitConflictDescriptor(
            repositoryRoot:
                root,
            relativePath:
                relative,
            workingTreeURL:
                fileURL,
            baseURL:
                materialized.base,
            oursURL:
                materialized.local,
            theirsURL:
                materialized.remote
        )
    }

    public func stageResolved(
        descriptor:
            GitConflictDescriptor
    ) throws {
        _ = try runner.run(
            arguments: [
                "-C",
                descriptor
                    .repositoryRoot
                    .path,
                "add",
                "--",
                descriptor
                    .relativePath
            ],
            currentDirectory: nil,
            allowFailure: false
        )
    }

    public func isStillConflicted(
        descriptor:
            GitConflictDescriptor
    ) throws -> Bool {
        let status =
            try repositoryService
            .status(
                repositoryRoot:
                    descriptor
                    .repositoryRoot,
                relativePath:
                    descriptor
                    .relativePath
            )

        return status.first?
            .isConflicted == true
    }
}
