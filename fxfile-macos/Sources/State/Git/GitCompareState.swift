import Foundation
import fxfileCore

@MainActor
public final class GitCompareState:
    ObservableObject {

    @Published public private(set)
    var repositoryRoot: URL?

    @Published public private(set)
    var relativePath: String?

    @Published public private(set)
    var statusItem: GitStatusItem?

    @Published public private(set)
    var branchName: String?

    @Published public private(set)
    var isLoading = false

    @Published public private(set)
    var errorMessage: String?

    private let repositoryService:
        any GitRepositoryServicing

    public init(
        repositoryService:
            any GitRepositoryServicing =
                GitRepositoryService.shared
    ) {
        self.repositoryService =
            repositoryService
    }

    public func inspect(
        url: URL
    ) {
        isLoading = true
        errorMessage = nil

        let service =
            repositoryService

        Task.detached {
            do {
                guard let root =
                    try service
                    .repositoryRoot(
                        for: url
                    )
                else {
                    await MainActor.run {
                        self.repositoryRoot =
                            nil
                        self.relativePath =
                            nil
                        self.statusItem =
                            nil
                        self.branchName =
                            nil
                        self.isLoading =
                            false
                    }
                    return
                }

                let relative =
                    try service.relativePath(
                        for: url,
                        repositoryRoot:
                            root
                    )

                let status =
                    try service.status(
                        repositoryRoot:
                            root,
                        relativePath:
                            relative == "."
                            ? nil
                            : relative
                    )

                let branch =
                    try service
                    .currentBranch(
                        repositoryRoot:
                            root
                    )

                await MainActor.run {
                    self.repositoryRoot =
                        root
                    self.relativePath =
                        relative
                    self.statusItem =
                        status.first
                    self.branchName =
                        branch
                    self.isLoading =
                        false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage =
                        error.localizedDescription
                    self.isLoading =
                        false
                }
            }
        }
    }
}
