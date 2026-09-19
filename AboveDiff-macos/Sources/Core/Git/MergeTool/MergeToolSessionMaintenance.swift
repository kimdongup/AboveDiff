import Foundation

public struct MergeToolSessionMaintenance: Sendable {
    public let sessionStore: MergeToolSessionStore
    public let staleAge: TimeInterval

    public init(
        sessionStore: MergeToolSessionStore,
        staleAge: TimeInterval = 24 * 60 * 60
    ) {
        self.sessionStore = sessionStore
        self.staleAge = staleAge
    }

    @discardableResult
    public func removeStaleSessions(
        now: Date = Date(),
        fileManager: FileManager = .default
    ) throws -> Int {
        guard fileManager.fileExists(
            atPath: sessionStore.rootDirectory.path
        ) else {
            return 0
        }

        let children = try fileManager.contentsOfDirectory(
            at: sessionStore.rootDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        var removed = 0

        for directory in children {
            let values = try directory.resourceValues(
                forKeys: [.contentModificationDateKey]
            )

            guard let modified = values.contentModificationDate else {
                continue
            }

            if now.timeIntervalSince(modified) >= staleAge {
                try? fileManager.removeItem(at: directory)
                removed += 1
            }
        }

        return removed
    }
}
