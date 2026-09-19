import Foundation

public protocol FileContentComparing: Sendable {
    func compare(
        _ lhs: URL,
        _ rhs: URL,
        options: FileContentCompareOptions
    ) throws -> FileContentComparison
}

public struct FileContentComparator: FileContentComparing {
    public init() {}

    public func compare(
        _ lhs: URL,
        _ rhs: URL,
        options: FileContentCompareOptions = FileContentCompareOptions()
    ) throws -> FileContentComparison {
        let lhsValues = try lhs.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        let rhsValues = try rhs.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])

        guard lhsValues.isRegularFile == true, rhsValues.isRegularFile == true else {
            throw FileContentComparatorError.notRegularFile
        }

        if lhsValues.fileSize != rhsValues.fileSize {
            return .different
        }

        guard
            let leftStream = InputStream(url: lhs),
            let rightStream = InputStream(url: rhs)
        else {
            throw FileContentComparatorError.openFailed
        }

        leftStream.open()
        rightStream.open()
        defer {
            leftStream.close()
            rightStream.close()
        }

        let size = options.chunkSize
        let leftBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        let rightBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        defer {
            leftBuffer.deallocate()
            rightBuffer.deallocate()
        }

        while true {
            let leftCount = leftStream.read(leftBuffer, maxLength: size)
            let rightCount = rightStream.read(rightBuffer, maxLength: size)

            if leftCount < 0 {
                throw leftStream.streamError ?? FileContentComparatorError.readFailed
            }
            if rightCount < 0 {
                throw rightStream.streamError ?? FileContentComparatorError.readFailed
            }

            if leftCount != rightCount {
                return .different
            }
            if leftCount == 0 {
                return .equal
            }

            if memcmp(leftBuffer, rightBuffer, leftCount) != 0 {
                return .different
            }
        }
    }
}

public enum FileContentComparatorError: Error, Sendable, Equatable {
    case notRegularFile
    case openFailed
    case readFailed
}
