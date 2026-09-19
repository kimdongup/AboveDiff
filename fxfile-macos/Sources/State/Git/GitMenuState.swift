import Foundation
import AboveDiffCore

@MainActor
public final class GitMenuState:
    ObservableObject {

    @Published public private(set)
    var selectedURL: URL?

    @Published public private(set)
    var capabilities =
        GitSelectionCapabilities()

    @Published public private(set)
    var branchName: String?

    @Published public private(set)
    var repositoryRoot: URL?

    @Published public private(set)
    var isInspecting = false

    private let repositoryService:
        any GitRepositoryServicing

    private var inspectionTask:
        Task<Void, Never>?

    public init(
        repositoryService:
            any GitRepositoryServicing =
                GitRepositoryService.shared
    ) {
        self.repositoryService =
            repositoryService
    }

    public func inspect(
        selectedURL: URL?
    ) {
        inspectionTask?.cancel()

        self.selectedURL =
            selectedURL

        guard let selectedURL else {
            capabilities =
                GitSelectionCapabilities()
            branchName = nil
            repositoryRoot = nil
            isInspecting = false
            return
        }

        isInspecting = true

        let service =
            repositoryService

        inspectionTask = Task {
            do {
                let result =
                    try await Task.detached {
                        () -> (
                            GitSelectionCapabilities,
                            URL?,
                            String?
                        ) in

                        guard let root =
                            try service
                            .repositoryRoot(
                                for:
                                    selectedURL
                            )
                        else {
                            return (
                                GitSelectionCapabilities(),
                                nil,
                                nil
                            )
                        }

                        var isDirectory:
                            ObjCBool = false

                        let exists =
                            FileManager
                            .default
                            .fileExists(
                                atPath:
                                    selectedURL
                                    .path,
                                isDirectory:
                                    &isDirectory
                            )

                        let isFile =
                            exists &&
                            !isDirectory
                                .boolValue

                        guard isFile else {
                            let branch =
                                try service
                                .currentBranch(
                                    repositoryRoot:
                                        root
                                )

                            return (
                                GitSelectionCapabilities(
                                    isRepository:
                                        true,
                                    isFile:
                                        false
                                ),
                                root,
                                branch
                            )
                        }

                        let relative =
                            try service
                            .relativePath(
                                for:
                                    selectedURL,
                                repositoryRoot:
                                    root
                            )

                        let statuses =
                            try service
                            .status(
                                repositoryRoot:
                                    root,
                                relativePath:
                                    relative
                            )

                        let item =
                            statuses.first

                        let isUntracked =
                            item?
                            .workTreeStatus ==
                            .untracked

                        let isTracked =
                            !isUntracked

                        let capabilities =
                            GitSelectionCapabilities(
                                isRepository:
                                    true,
                                isFile:
                                    true,
                                isTracked:
                                    isTracked,
                                hasWorkingTreeChanges:
                                    item?
                                    .isModifiedInWorkingTree
                                    ?? false,
                                hasStagedChanges:
                                    item?
                                    .isStaged
                                    ?? false,
                                isConflicted:
                                    item?
                                    .isConflicted
                                    ?? false
                            )

                        let branch =
                            try service
                            .currentBranch(
                                repositoryRoot:
                                    root
                            )

                        return (
                            capabilities,
                            root,
                            branch
                        )
                    }.value

                guard !Task
                    .isCancelled
                else {
                    return
                }

                capabilities =
                    result.0
                repositoryRoot =
                    result.1
                branchName =
                    result.2
                isInspecting =
                    false
            } catch {
                guard !Task
                    .isCancelled
                else {
                    return
                }

                capabilities =
                    GitSelectionCapabilities()
                repositoryRoot =
                    nil
                branchName =
                    nil
                isInspecting =
                    false
            }
        }
    }

    public func refresh() {
        inspect(
            selectedURL:
                selectedURL
        )
    }
}
