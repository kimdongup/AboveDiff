import Foundation

public protocol DirectoryComparing: Sendable {
    func compare(
        request: DirectoryCompareRequest,
        progress: (@Sendable (Double, String) -> Void)?
    ) throws -> [DirectoryCompareItem]
}

public final class DirectoryCompareEngine: @unchecked Sendable, DirectoryComparing {
    public static let shared = DirectoryCompareEngine()

    private let fileComparator: any FileContentComparing
    private let fileManager: FileManager

    public init(
        fileComparator: any FileContentComparing = FileContentComparator(),
        fileManager: FileManager = .default
    ) {
        self.fileComparator = fileComparator
        self.fileManager = fileManager
    }

    public func compare(
        request: DirectoryCompareRequest,
        progress: (@Sendable (Double, String) -> Void)? = nil
    ) throws -> [DirectoryCompareItem] {
        try checkCancellation()

        progress?(0.05, "Scanning left folder...")
        let leftEntries = try scan(
            root: request.leftRoot,
            options: request.options
        )

        try checkCancellation()

        progress?(0.35, "Scanning right folder...")
        let rightEntries = try scan(
            root: request.rightRoot,
            options: request.options
        )

        let allPaths = Set(leftEntries.keys)
            .union(rightEntries.keys)
            .sorted()

        var result: [DirectoryCompareItem] = []
        result.reserveCapacity(allPaths.count)

        for (index, path) in allPaths.enumerated() {
            if index % 50 == 0 {
                try checkCancellation()
            }

            guard request.options.nameFilter.matches(
                relativePath: path
            ) else {
                continue
            }

            let left = leftEntries[path]
            let right = rightEntries[path]

            let item: DirectoryCompareItem

            switch (left, right) {
            case let (.some(l), .none):
                item = DirectoryCompareItem(
                    relativePath: path,
                    left: l,
                    right: nil,
                    status: .leftOnly
                )

            case let (.none, .some(r)):
                item = DirectoryCompareItem(
                    relativePath: path,
                    left: nil,
                    right: r,
                    status: .rightOnly
                )

            case let (.some(l), .some(r)):
                item = comparePair(
                    relativePath: path,
                    left: l,
                    right: r,
                    options: request.options
                )

            case (.none, .none):
                continue
            }

            result.append(item)

            if !allPaths.isEmpty,
               index % 50 == 0 {
                let fraction =
                    0.5 +
                    0.5 *
                    (Double(index) /
                     Double(allPaths.count))

                progress?(
                    fraction,
                    "Comparing items..."
                )
            }
        }

        try checkCancellation()
        progress?(1.0, "Comparison complete")
        return result
    }

    private func scan(
        root: URL,
        options: DirectoryCompareOptions
    ) throws -> [String: DirectoryEntryMetadata] {
        let rootValues = try root.resourceValues(
            forKeys: [.isDirectoryKey]
        )

        guard rootValues.isDirectory == true else {
            throw DirectoryCompareError
                .rootIsNotDirectory(root)
        }

        var enumerationOptions:
            FileManager.DirectoryEnumerationOptions = []

        if !options.includeHiddenFiles {
            enumerationOptions.insert(
                .skipsHiddenFiles
            )
        }

        if !options.recursive {
            enumerationOptions.insert(
                .skipsSubdirectoryDescendants
            )
        }

        let keys: [URLResourceKey] = [
            .isDirectoryKey,
            .isRegularFileKey,
            .fileSizeKey,
            .contentModificationDateKey
        ]

        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: keys,
            options: enumerationOptions,
            errorHandler: { _, _ in true }
        ) else {
            throw DirectoryCompareError
                .enumerationFailed(root)
        }

        let rootPath =
            root.standardizedFileURL.path

        var entries:
            [String: DirectoryEntryMetadata] = [:]

        var scanned = 0

        for case let url as URL in enumerator {
            scanned += 1

            if scanned % 100 == 0 {
                try checkCancellation()
            }

            let values = try url.resourceValues(
                forKeys: Set(keys)
            )

            let filePath =
                url.standardizedFileURL.path

            guard filePath.hasPrefix(rootPath) else {
                continue
            }

            var relativePath =
                String(
                    filePath.dropFirst(
                        rootPath.count
                    )
                )

            if relativePath.hasPrefix("/") {
                relativePath.removeFirst()
            }

            guard !relativePath.isEmpty else {
                continue
            }

            entries[relativePath] =
                DirectoryEntryMetadata(
                    url: url,
                    isDirectory:
                        values.isDirectory ?? false,
                    size:
                        Int64(values.fileSize ?? 0),
                    modificationDate:
                        values.contentModificationDate
                )
        }

        return entries
    }

    private func comparePair(
        relativePath: String,
        left: DirectoryEntryMetadata,
        right: DirectoryEntryMetadata,
        options: DirectoryCompareOptions
    ) -> DirectoryCompareItem {
        guard left.isDirectory ==
              right.isDirectory else {
            return DirectoryCompareItem(
                relativePath: relativePath,
                left: left,
                right: right,
                status: .typeMismatch
            )
        }

        if left.isDirectory {
            return DirectoryCompareItem(
                relativePath: relativePath,
                left: left,
                right: right,
                status: .same
            )
        }

        do {
            let same: Bool

            switch options.comparisonMode {
            case .metadata:
                same = metadataEqual(
                    left,
                    right,
                    tolerance:
                        options.metadataTimeTolerance
                )

            case .content:
                same = try fileComparator.compare(
                    left.url,
                    right.url,
                    options: FileContentCompareOptions()
                ) == .equal

            case .smart:
                if left.size != right.size {
                    same = false
                } else {
                    same = try fileComparator.compare(
                        left.url,
                        right.url,
                        options: FileContentCompareOptions()
                    ) == .equal
                }
            }

            return DirectoryCompareItem(
                relativePath: relativePath,
                left: left,
                right: right,
                status: same ? .same : .modified
            )
        } catch {
            return DirectoryCompareItem(
                relativePath: relativePath,
                left: left,
                right: right,
                status: .error,
                errorDescription:
                    error.localizedDescription
            )
        }
    }

    private func metadataEqual(
        _ left: DirectoryEntryMetadata,
        _ right: DirectoryEntryMetadata,
        tolerance: TimeInterval
    ) -> Bool {
        guard left.size == right.size else {
            return false
        }

        switch (
            left.modificationDate,
            right.modificationDate
        ) {
        case let (.some(l), .some(r)):
            return abs(
                l.timeIntervalSince(r)
            ) <= tolerance

        case (.none, .none):
            return true

        default:
            return false
        }
    }

    private func checkCancellation() throws {
        if Task.isCancelled {
            throw CancellationError()
        }
    }
}

public enum DirectoryCompareError: Error, Sendable, Equatable {
    case rootIsNotDirectory(URL)
    case enumerationFailed(URL)
}
