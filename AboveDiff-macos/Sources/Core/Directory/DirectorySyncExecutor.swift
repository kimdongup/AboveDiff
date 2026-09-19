import Foundation

public protocol DirectorySyncExecuting: Sendable {
    func execute(
        plan: DirectorySyncPlan,
        leftRoot: URL,
        rightRoot: URL,
        progress: (@Sendable (Int, Int, String) -> Void)?
    ) throws
}

public final class DirectorySyncExecutor: @unchecked Sendable, DirectorySyncExecuting {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func execute(
        plan: DirectorySyncPlan,
        leftRoot: URL,
        rightRoot: URL,
        progress: (@Sendable (Int, Int, String) -> Void)? = nil
    ) throws {
        let total = plan.operations.count

        for (index, operation) in plan.operations.enumerated() {
            let leftURL = leftRoot.appendingPathComponent(operation.relativePath)
            let rightURL = rightRoot.appendingPathComponent(operation.relativePath)

            progress?(
                index + 1,
                total,
                "\(operation.kind.rawValue): \(operation.relativePath)"
            )

            switch operation.kind {
            case .copyLeftToRight:
                try replaceCopy(from: leftURL, to: rightURL)

            case .copyRightToLeft:
                try replaceCopy(from: rightURL, to: leftURL)

            case .deleteLeft:
                if fileManager.fileExists(atPath: leftURL.path) {
                    try fileManager.removeItem(at: leftURL)
                }

            case .deleteRight:
                if fileManager.fileExists(atPath: rightURL.path) {
                    try fileManager.removeItem(at: rightURL)
                }
            }
        }
    }

    private func replaceCopy(from source: URL, to target: URL) throws {
        let parent = target.deletingLastPathComponent()

        if !fileManager.fileExists(atPath: parent.path) {
            try fileManager.createDirectory(
                at: parent,
                withIntermediateDirectories: true
            )
        }

        if fileManager.fileExists(atPath: target.path) {
            try fileManager.removeItem(at: target)
        }

        try fileManager.copyItem(at: source, to: target)
    }
}
