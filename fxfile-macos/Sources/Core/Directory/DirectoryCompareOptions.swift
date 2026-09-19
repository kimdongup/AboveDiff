import Foundation

public struct DirectoryCompareOptions: Sendable, Hashable {
    public var recursive: Bool
    public var includeHiddenFiles: Bool
    public var comparisonMode: FileComparisonMode
    public var metadataTimeTolerance: TimeInterval
    public var nameFilter: DirectoryNameFilter

    public init(
        recursive: Bool = true,
        includeHiddenFiles: Bool = false,
        comparisonMode: FileComparisonMode = .smart,
        metadataTimeTolerance: TimeInterval = 2.0,
        nameFilter: DirectoryNameFilter = DirectoryNameFilter()
    ) {
        self.recursive = recursive
        self.includeHiddenFiles = includeHiddenFiles
        self.comparisonMode = comparisonMode
        self.metadataTimeTolerance = max(0, metadataTimeTolerance)
        self.nameFilter = nameFilter
    }
}

public struct DirectoryCompareRequest: Sendable, Hashable {
    public let leftRoot: URL
    public let rightRoot: URL
    public let options: DirectoryCompareOptions

    public init(
        leftRoot: URL,
        rightRoot: URL,
        options: DirectoryCompareOptions = DirectoryCompareOptions()
    ) {
        self.leftRoot = leftRoot
        self.rightRoot = rightRoot
        self.options = options
    }
}
