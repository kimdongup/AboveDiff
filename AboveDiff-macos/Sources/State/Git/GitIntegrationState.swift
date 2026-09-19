import Foundation
import AboveDiffCore

@MainActor
public final class GitIntegrationState: ObservableObject {
    @Published public private(set)
    var status: GitMergetoolInstallStatus?

    @Published public private(set)
    var isRefreshing = false

    @Published public private(set)
    var message: String?

    private let statusService:
        GitMergetoolStatusService

    public init(
        statusService:
            GitMergetoolStatusService =
                GitMergetoolStatusService()
    ) {
        self.statusService = statusService
    }

    public func refresh() {
        isRefreshing = true
        message = nil

        let service = statusService

        Task.detached {
            do {
                let value = try service.inspect()

                await MainActor.run {
                    self.status = value
                    self.isRefreshing = false
                }
            } catch {
                await MainActor.run {
                    self.message =
                        error.localizedDescription
                    self.isRefreshing = false
                }
            }
        }
    }
}
