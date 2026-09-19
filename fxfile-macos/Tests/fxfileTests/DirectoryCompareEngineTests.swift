import XCTest
@testable import fxfileCore

final class DirectoryCompareEngineTests: XCTestCase {
    private var root: URL!
    private var left: URL!
    private var right: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("fxfile_dir_compare_\(UUID().uuidString)")
        left = root.appendingPathComponent("left")
        right = root.appendingPathComponent("right")
        try FileManager.default.createDirectory(at: left, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: right, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    func testContentModeDetectsSameMetadataDifferentBytes() throws {
        let leftFile = left.appendingPathComponent("same-meta.txt")
        let rightFile = right.appendingPathComponent("same-meta.txt")

        try "AAAA".write(to: leftFile, atomically: true, encoding: .utf8)
        try "BBBB".write(to: rightFile, atomically: true, encoding: .utf8)

        let date = Date(timeIntervalSince1970: 1_700_000_000)
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: leftFile.path)
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: rightFile.path)

        let result = try DirectoryCompareEngine.shared.compare(
            request: DirectoryCompareRequest(
                leftRoot: left,
                rightRoot: right,
                options: DirectoryCompareOptions(comparisonMode: .content)
            )
        )

        XCTAssertEqual(result.first?.status, .modified)
    }

    func testMetadataModePreservesFastMetadataSemantics() throws {
        let leftFile = left.appendingPathComponent("same-meta.txt")
        let rightFile = right.appendingPathComponent("same-meta.txt")

        try "AAAA".write(to: leftFile, atomically: true, encoding: .utf8)
        try "BBBB".write(to: rightFile, atomically: true, encoding: .utf8)

        let date = Date(timeIntervalSince1970: 1_700_000_000)
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: leftFile.path)
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: rightFile.path)

        let result = try DirectoryCompareEngine.shared.compare(
            request: DirectoryCompareRequest(
                leftRoot: left,
                rightRoot: right,
                options: DirectoryCompareOptions(comparisonMode: .metadata)
            )
        )

        XCTAssertEqual(result.first?.status, .same)
    }

    func testLeftOnlyAndRightOnly() throws {
        try "L".write(
            to: left.appendingPathComponent("left.txt"),
            atomically: true,
            encoding: .utf8
        )
        try "R".write(
            to: right.appendingPathComponent("right.txt"),
            atomically: true,
            encoding: .utf8
        )

        let result = try DirectoryCompareEngine.shared.compare(
            request: DirectoryCompareRequest(leftRoot: left, rightRoot: right)
        )

        let map = Dictionary(uniqueKeysWithValues: result.map { ($0.relativePath, $0.status) })
        XCTAssertEqual(map["left.txt"], .leftOnly)
        XCTAssertEqual(map["right.txt"], .rightOnly)
    }
}
