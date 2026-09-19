import Foundation

public struct GitSelectionCapabilities:
    Sendable,
    Hashable {

    public let isRepository: Bool
    public let isFile: Bool
    public let isTracked: Bool
    public let hasWorkingTreeChanges: Bool
    public let hasStagedChanges: Bool
    public let isConflicted: Bool

    public init(
        isRepository: Bool = false,
        isFile: Bool = false,
        isTracked: Bool = false,
        hasWorkingTreeChanges: Bool = false,
        hasStagedChanges: Bool = false,
        isConflicted: Bool = false
    ) {
        self.isRepository =
            isRepository
        self.isFile =
            isFile
        self.isTracked =
            isTracked
        self.hasWorkingTreeChanges =
            hasWorkingTreeChanges
        self.hasStagedChanges =
            hasStagedChanges
        self.isConflicted =
            isConflicted
    }

    public var canCompareWorkingTreeWithHEAD: Bool {
        isRepository &&
        isFile &&
        isTracked &&
        !isConflicted
    }

    public var canCompareStagedWithHEAD: Bool {
        isRepository &&
        isFile &&
        isTracked &&
        hasStagedChanges &&
        !isConflicted
    }

    public var canCompareWorkingTreeWithStaged: Bool {
        isRepository &&
        isFile &&
        isTracked &&
        (
            hasWorkingTreeChanges ||
            hasStagedChanges
        ) &&
        !isConflicted
    }

    public var canResolveConflict: Bool {
        isRepository &&
        isFile &&
        isConflicted
    }
}
