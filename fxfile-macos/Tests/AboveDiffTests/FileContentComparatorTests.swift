import XCTest
@testable import AboveDiffCore

final class FileContentComparatorTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("fxfile_content_compare_\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func testEqualFiles() throws {
        let a = tempDirectory.appendingPathComponent("a.txt")
        let b = tempDirectory.appendingPathComponent("b.txt")
        try "same".write(to: a, atomically: true, encoding: .utf8)
        try "same".write(to: b, atomically: true, encoding: .utf8)

        XCTAssertEqual(
            try FileContentComparator().compare(a, b),
            .equal
        )
    }

    func testSameSizeDifferentContent() throws {
        let a = tempDirectory.appendingPathComponent("a.txt")
        let b = tempDirectory.appendingPathComponent("b.txt")
        try "AAAA".write(to: a, atomically: true, encoding: .utf8)
        try "BBBB".write(to: b, atomically: true, encoding: .utf8)

        XCTAssertEqual(
            try FileContentComparator().compare(a, b),
            .different
        )
    }

    func testDifferentSizesShortCircuit() throws {
        let a = tempDirectory.appendingPathComponent("a.txt")
        let b = tempDirectory.appendingPathComponent("b.txt")
        try "A".write(to: a, atomically: true, encoding: .utf8)
        try "BBBB".write(to: b, atomically: true, encoding: .utf8)

        XCTAssertEqual(
            try FileContentComparator().compare(a, b),
            .different
        )
    }
}
