import Foundation
import AppKit
import fxfileCore

@MainActor
public enum GitCompareLauncher {
    public static func compareWorkingTreeWithHEAD(
        fileURL: URL
    ) {
        compare(
            fileURL: fileURL,
            left: .head,
            right: .workingTree
        )
    }

    public static func compareStagedWithHEAD(
        fileURL: URL
    ) {
        compare(
            fileURL: fileURL,
            left: .head,
            right: .index
        )
    }

    public static func compareWorkingTreeWithStaged(
        fileURL: URL
    ) {
        compare(
            fileURL: fileURL,
            left: .index,
            right: .workingTree
        )
    }

    public static func resolveConflict(
        fileURL: URL
    ) {
        do {
            let descriptor =
                try GitConflictService
                .shared
                .prepare(
                    fileURL:
                        fileURL
                )

            GitConflictMergeWindowPresenter
                .open(
                    descriptor:
                        descriptor
                )
        } catch {
            presentError(
                error
                    .localizedDescription
            )
        }
    }

    private static func compare(
        fileURL: URL,
        left: GitRevision,
        right: GitRevision
    ) {
        do {
            let service =
                GitRepositoryService
                .shared

            guard let root =
                try service
                .repositoryRoot(
                    for:
                        fileURL
                )
            else {
                presentError(
                    "The selected file is not inside a Git repository."
                )
                return
            }

            let relative =
                try service
                .relativePath(
                    for:
                        fileURL,
                    repositoryRoot:
                        root
                )

            let materializer =
                GitCompareMaterializer
                .shared

            let leftFile =
                try materializer
                .materialize(
                    repositoryRoot:
                        root,
                    relativePath:
                        relative,
                    revision:
                        left
                )

            let rightFile =
                try materializer
                .materialize(
                    repositoryRoot:
                        root,
                    relativePath:
                        relative,
                    revision:
                        right
                )

            FileDiffWindowPresenter
                .open(
                    leftURL:
                        leftFile.url,
                    rightURL:
                        rightFile.url
                )
        } catch {
            presentError(
                error
                    .localizedDescription
            )
        }
    }

    private static func presentError(
        _ message: String
    ) {
        let alert =
            NSAlert()

        alert.alertStyle =
            .warning
        alert.messageText =
            "Git Compare"
        alert.informativeText =
            message

        alert.runModal()
    }
}
