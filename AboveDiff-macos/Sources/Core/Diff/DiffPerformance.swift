import Foundation

public struct DiffLargeFilePolicy: Sendable, Hashable {
    public var characterThreshold: Int
    public var lineThreshold: Int

    public init(
        characterThreshold: Int = 1_000_000,
        lineThreshold: Int = 100_000
    ) {
        self.characterThreshold = max(1, characterThreshold)
        self.lineThreshold = max(1, lineThreshold)
    }

    public func isLarge(text: String) -> Bool {
        if text.count >= characterThreshold {
            return true
        }

        var lineCount = 1
        for character in text where character == "\n" {
            lineCount += 1
            if lineCount >= lineThreshold {
                return true
            }
        }

        return false
    }
}

public final class DiffResultCache: @unchecked Sendable {
    public static let shared = DiffResultCache()

    private struct Key: Hashable {
        let leftHash: Int
        let rightHash: Int
        let leftCount: Int
        let rightCount: Int
        let options: DiffOptions
    }

    private let lock = NSLock()
    private var storage: [Key: DiffResult] = [:]
    private var order: [Key] = []
    private let capacity: Int

    public init(capacity: Int = 32) {
        self.capacity = max(1, capacity)
    }

    public func value(
        leftText: String,
        rightText: String,
        options: DiffOptions
    ) -> DiffResult? {
        let key = makeKey(
            leftText: leftText,
            rightText: rightText,
            options: options
        )

        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }

    public func insert(
        _ result: DiffResult,
        leftText: String,
        rightText: String,
        options: DiffOptions
    ) {
        let key = makeKey(
            leftText: leftText,
            rightText: rightText,
            options: options
        )

        lock.lock()
        defer { lock.unlock() }

        if storage[key] == nil {
            order.append(key)
        }

        storage[key] = result

        while order.count > capacity {
            let oldest = order.removeFirst()
            storage.removeValue(forKey: oldest)
        }
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
        order.removeAll()
    }

    private func makeKey(
        leftText: String,
        rightText: String,
        options: DiffOptions
    ) -> Key {
        Key(
            leftHash: leftText.hashValue,
            rightHash: rightText.hashValue,
            leftCount: leftText.count,
            rightCount: rightText.count,
            options: options
        )
    }
}
