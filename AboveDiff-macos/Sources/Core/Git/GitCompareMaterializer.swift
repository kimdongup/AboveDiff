import Foundation

public struct GitMaterializedFile: Sendable, Hashable {
    public let url: URL
    public let revision: GitRevision

    public init(
        url: URL,
        revision: GitRevision
    ) {
        self.url = url
        self.revision = revision
    }
}

public final class GitCompareMaterializer:
    @unchecked Sendable {

    public static let shared =
        GitCompareMaterializer()

    private let blobLoader:
        any GitBlobLoading

    public init(
        blobLoader:
            any GitBlobLoading =
                GitBlobLoader.shared
    ) {
        self.blobLoader =
            blobLoader
    }

    public func materialize(
        repositoryRoot: URL,
        relativePath: String,
        revision: GitRevision
    ) throws -> GitMaterializedFile {
        if revision == .workingTree {
            return GitMaterializedFile(
                url:
                    repositoryRoot
                    .appendingPathComponent(
                        relativePath
                    ),
                revision: revision
            )
        }

        let blob = try blobLoader.load(
            repositoryRoot:
                repositoryRoot,
            relativePath:
                relativePath,
            revision:
                revision
        )

        if blob.isBinary {
            throw GitBlobError
                .binaryFile(
                    relativePath
                )
        }

        let temporaryRoot =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "abovediff-git",
                isDirectory: true
            )

        try FileManager.default
            .createDirectory(
                at: temporaryRoot,
                withIntermediateDirectories:
                    true
            )

        let safeRevision =
            revision.displayName
            .replacingOccurrences(
                of: "/",
                with: "-"
            )
            .replacingOccurrences(
                of: " ",
                with: "-"
            )

        let filename =
            "\(safeRevision)-" +
            URL(
                fileURLWithPath:
                    relativePath
            ).lastPathComponent

        let url =
            temporaryRoot
            .appendingPathComponent(
                UUID().uuidString + "-" + filename
            )

        try blob.data.write(
            to: url,
            options: .atomic
        )

        return GitMaterializedFile(
            url: url,
            revision: revision
        )
    }

    public func materializeConflict(
        repositoryRoot: URL,
        relativePath: String
    ) throws -> (
        local: URL,
        base: URL,
        remote: URL
    ) {
        let base = try materialize(
            repositoryRoot:
                repositoryRoot,
            relativePath:
                relativePath,
            revision:
                .mergeBase
        )

        let local = try materialize(
            repositoryRoot:
                repositoryRoot,
            relativePath:
                relativePath,
            revision:
                .ours
        )

        let remote = try materialize(
            repositoryRoot:
                repositoryRoot,
            relativePath:
                relativePath,
            revision:
                .theirs
        )

        return (
            local.url,
            base.url,
            remote.url
        )
    }
}
