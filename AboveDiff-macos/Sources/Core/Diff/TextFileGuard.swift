import Foundation

public struct TextFileGuardPolicy: Sendable, Hashable {
    public var maximumBytes: Int
    public var binaryProbeBytes: Int

    public init(
        maximumBytes: Int = 8 * 1024 * 1024,
        binaryProbeBytes: Int = 8_192
    ) {
        self.maximumBytes = max(1, maximumBytes)
        self.binaryProbeBytes = max(1, binaryProbeBytes)
    }
}

public enum TextFileGuardResult: Sendable, Hashable {
    case text
    case tooLarge(byteCount: Int)
    case binary
}

public struct TextFileGuard: Sendable {
    public let policy: TextFileGuardPolicy

    public init(
        policy: TextFileGuardPolicy = TextFileGuardPolicy()
    ) {
        self.policy = policy
    }

    public func inspect(data: Data) -> TextFileGuardResult {
        if data.count > policy.maximumBytes {
            return .tooLarge(
                byteCount: data.count
            )
        }

        let probe = data.prefix(
            policy.binaryProbeBytes
        )

        if probe.contains(0) {
            return .binary
        }

        return .text
    }

    public func inspect(url: URL) throws -> TextFileGuardResult {
        let values = try url.resourceValues(
            forKeys: [.fileSizeKey]
        )

        let size = values.fileSize ?? 0

        if size > policy.maximumBytes {
            return .tooLarge(
                byteCount: size
            )
        }

        let handle = try FileHandle(
            forReadingFrom: url
        )

        defer {
            try? handle.close()
        }

        let data = try handle.read(
            upToCount: policy.binaryProbeBytes
        ) ?? Data()

        if data.contains(0) {
            return .binary
        }

        return .text
    }
}
