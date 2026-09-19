import Foundation

public enum DirectorySyncPolicy: Sendable, Hashable {
    case leftToRightUpdate
    case leftToRightMirror
    case rightToLeft
    case bidirectional
}

public enum DirectorySyncOperationKind: String, Sendable, Codable {
    case copyLeftToRight
    case copyRightToLeft
    case deleteLeft
    case deleteRight
}

public struct DirectorySyncOperation: Identifiable, Sendable, Hashable {
    public let id: String
    public let relativePath: String
    public let kind: DirectorySyncOperationKind
    public let isDirectory: Bool

    public init(
        relativePath: String,
        kind: DirectorySyncOperationKind,
        isDirectory: Bool
    ) {
        self.id = "\(kind.rawValue):\(relativePath)"
        self.relativePath = relativePath
        self.kind = kind
        self.isDirectory = isDirectory
    }
}

public struct DirectorySyncPlan: Sendable, Hashable {
    public let operations: [DirectorySyncOperation]

    public init(operations: [DirectorySyncOperation]) {
        self.operations = operations
    }
}

public struct DirectorySyncPlanner: Sendable {
    public init() {}

    public func makePlan(
        items: [DirectoryCompareItem],
        policy: DirectorySyncPolicy
    ) -> DirectorySyncPlan {
        var operations: [DirectorySyncOperation] = []

        for item in items {
            switch (item.status, policy) {
            case (.same, _), (.error, _), (.typeMismatch, _):
                continue

            case (.leftOnly, .leftToRightUpdate),
                 (.leftOnly, .leftToRightMirror),
                 (.leftOnly, .bidirectional):
                operations.append(operation(item, .copyLeftToRight))

            case (.leftOnly, .rightToLeft):
                continue

            case (.rightOnly, .leftToRightUpdate):
                continue

            case (.rightOnly, .leftToRightMirror):
                operations.append(operation(item, .deleteRight))

            case (.rightOnly, .rightToLeft),
                 (.rightOnly, .bidirectional):
                operations.append(operation(item, .copyRightToLeft))

            case (.modified, .leftToRightUpdate),
                 (.modified, .leftToRightMirror):
                operations.append(operation(item, .copyLeftToRight))

            case (.modified, .rightToLeft):
                operations.append(operation(item, .copyRightToLeft))

            case (.modified, .bidirectional):
                if let leftDate = item.left?.modificationDate,
                   let rightDate = item.right?.modificationDate,
                   rightDate > leftDate {
                    operations.append(operation(item, .copyRightToLeft))
                } else {
                    operations.append(operation(item, .copyLeftToRight))
                }
            }
        }

        return DirectorySyncPlan(operations: operations)
    }

    private func operation(
        _ item: DirectoryCompareItem,
        _ kind: DirectorySyncOperationKind
    ) -> DirectorySyncOperation {
        DirectorySyncOperation(
            relativePath: item.relativePath,
            kind: kind,
            isDirectory: item.isDirectory
        )
    }
}
