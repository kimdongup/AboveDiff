import Foundation
import AppKit
import AboveDiffCore

@MainActor
public final class MergeToolSessionCoordinator: ObservableObject {
    public static let shared = MergeToolSessionCoordinator()

    private var timer: Timer?
    private var activeSessionIDs: Set<UUID> = []

    private init() {}

    public func start() {

        if timer != nil {
            scan()
            return
        }

        scan()

        let timer = Timer(
            timeInterval: 0.5,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.scan()
            }
        }

        RunLoop.main.add(
            timer,
            forMode: .common
        )

        self.timer = timer

    }

    public func stop() {

        timer?.invalidate()
        timer = nil
    }

    public func scanNow() {
        scan()
    }

    private func scan() {
        do {
            let store = try MergeToolSessionStore()


            let requests = try store.pendingRequests()


            for request in requests {

                guard !activeSessionIDs.contains(request.id) else {
                    continue
                }

                activeSessionIDs.insert(request.id)


                ExternalMergeToolWindowPresenter.open(
                    request: request,
                    sessionStore: store
                ) { [weak self] in

                    self?.activeSessionIDs.remove(
                        request.id
                    )
                }
            }
        } catch {
        }
    }
}
