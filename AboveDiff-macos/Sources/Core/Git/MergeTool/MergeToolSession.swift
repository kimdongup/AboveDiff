import Foundation

public struct MergeToolSessionRequest: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public let createdAt: Date
    public let arguments: GitMergeToolArguments

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        arguments: GitMergeToolArguments
    ) {
        self.id = id
        self.createdAt = createdAt
        self.arguments = arguments
    }
}

public enum MergeToolSessionOutcome: String, Sendable, Hashable, Codable {
    case resolved
    case cancelled
    case failed
}

public struct MergeToolSessionResult: Sendable, Hashable, Codable {
    public let sessionID: UUID
    public let outcome: MergeToolSessionOutcome
    public let exitStatus: GitMergeToolExitStatus
    public let message: String?

    public init(
        sessionID: UUID,
        outcome: MergeToolSessionOutcome,
        exitStatus: GitMergeToolExitStatus,
        message: String? = nil
    ) {
        self.sessionID = sessionID
        self.outcome = outcome
        self.exitStatus = exitStatus
        self.message = message
    }
}

public enum MergeToolSessionStoreError: LocalizedError, Sendable {
    case unableToResolveCacheDirectory
    case requestMissing(UUID)
    case resultMissing(UUID)

    public var errorDescription: String? {
        switch self {
        case .unableToResolveCacheDirectory:
            return "Unable to resolve the AboveDiff merge-session cache directory."
        case .requestMissing(let id):
            return "Merge session request is missing: \(id.uuidString)"
        case .resultMissing(let id):
            return "Merge session result is missing: \(id.uuidString)"
        }
    }
}

public struct MergeToolSessionStore: Sendable {
    public let rootDirectory: URL

    public init(
        rootDirectory: URL? = nil,
        fileManager: FileManager = .default
    ) throws {
        if let rootDirectory {
            self.rootDirectory = rootDirectory
            return
        }

        guard let caches = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first else {
            throw MergeToolSessionStoreError.unableToResolveCacheDirectory
        }

        self.rootDirectory = caches
            .appendingPathComponent("AboveDiff", isDirectory: true)
            .appendingPathComponent("MergeSessions", isDirectory: true)
    }

    public func sessionDirectory(
        for id: UUID
    ) -> URL {
        rootDirectory
            .appendingPathComponent(id.uuidString, isDirectory: true)
    }

    public func requestURL(
        for id: UUID
    ) -> URL {
        sessionDirectory(for: id)
            .appendingPathComponent("request.json")
    }

    public func resultURL(
        for id: UUID
    ) -> URL {
        sessionDirectory(for: id)
            .appendingPathComponent("result.json")
    }

    public func writeRequest(
        _ request: MergeToolSessionRequest,
        fileManager: FileManager = .default
    ) throws {
        let directory = sessionDirectory(for: request.id)

        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        try encoder.encode(request).write(
            to: requestURL(for: request.id),
            options: .atomic
        )
    }

    public func readRequest(
        sessionID: UUID,
        fileManager: FileManager = .default
    ) throws -> MergeToolSessionRequest {
        let url = requestURL(for: sessionID)

        guard fileManager.fileExists(atPath: url.path) else {
            throw MergeToolSessionStoreError.requestMissing(sessionID)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(
            MergeToolSessionRequest.self,
            from: Data(contentsOf: url)
        )
    }

    public func writeResult(
        _ result: MergeToolSessionResult,
        fileManager: FileManager = .default
    ) throws {
        let directory = sessionDirectory(for: result.sessionID)

        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        try encoder.encode(result).write(
            to: resultURL(for: result.sessionID),
            options: .atomic
        )
    }

    public func readResult(
        sessionID: UUID,
        fileManager: FileManager = .default
    ) throws -> MergeToolSessionResult {
        let url = resultURL(for: sessionID)

        guard fileManager.fileExists(atPath: url.path) else {
            throw MergeToolSessionStoreError.resultMissing(sessionID)
        }

        return try JSONDecoder().decode(
            MergeToolSessionResult.self,
            from: Data(contentsOf: url)
        )
    }

    public func pendingRequests(
        fileManager: FileManager = .default
    ) throws -> [MergeToolSessionRequest] {
        guard fileManager.fileExists(atPath: rootDirectory.path) else {
            return []
        }

        let children = try fileManager.contentsOfDirectory(
            at: rootDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        var requests: [MergeToolSessionRequest] = []

        for directory in children {
            guard
                let id = UUID(uuidString: directory.lastPathComponent),
                fileManager.fileExists(atPath: requestURL(for: id).path),
                !fileManager.fileExists(atPath: resultURL(for: id).path)
            else {
                continue
            }

            if let request = try? readRequest(
                sessionID: id,
                fileManager: fileManager
            ) {
                requests.append(request)
            }
        }

        return requests.sorted {
            $0.createdAt < $1.createdAt
        }
    }

    public func removeSession(
        sessionID: UUID,
        fileManager: FileManager = .default
    ) throws {
        let directory = sessionDirectory(for: sessionID)

        if fileManager.fileExists(atPath: directory.path) {
            try fileManager.removeItem(at: directory)
        }
    }
}
