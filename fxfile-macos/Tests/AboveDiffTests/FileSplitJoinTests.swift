import XCTest
@testable import AboveDiffCore

final class FileSplitJoinTests: XCTestCase {
    var tempDirectory: URL!
    
    override func setUpWithError() throws {
        let tempBase = FileManager.default.temporaryDirectory
        tempDirectory = tempBase.appendingPathComponent("fxfile_splitjoin_tests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
    }
    
    // MARK: - Helper Methods
    
    private final class ProgressTracker: @unchecked Sendable {
        var updates: [Double] = []
    }
    
    private func createBinaryFile(name: String, sizeInBytes: Int) throws -> URL {
        let fileURL = tempDirectory.appendingPathComponent(name)
        var data = Data(count: sizeInBytes)
        for i in 0..<sizeInBytes {
            data[i] = UInt8((i * 47 + 101) % 256)
        }
        try data.write(to: fileURL)
        return fileURL
    }
    
    // MARK: - Split and Join Large Binary File (> 1MB)
    
    func testSplitAndJoinLargeBinaryFile() throws {
        let engine = FileSplitJoinEngine.shared
        let checksumService = ChecksumService.shared
        
        // Create 1.25 MB binary file (1280 KB)
        let originalSize = 1280 * 1024
        let originalURL = try createBinaryFile(name: "archive_data.tar", sizeInBytes: originalSize)
        let originalSHA256 = try checksumService.calculateChecksum(for: originalURL, algorithm: .sha256)
        
        let splitDir = tempDirectory.appendingPathComponent("parts_output")
        try FileManager.default.createDirectory(at: splitDir, withIntermediateDirectories: true)
        
        // Split into 256 KB chunks (should create exactly 5 parts: 5 x 256 KB = 1280 KB)
        let chunkSize: Int64 = 256 * 1024
        let splitTracker = ProgressTracker()
        let splitConfig = SplitConfig(
            sourceURL: originalURL,
            destinationDirectory: splitDir,
            chunkSize: chunkSize,
            generateChecksum: true
        )
        
        let parts = try engine.splitFile(config: splitConfig) { prog, msg in
            splitTracker.updates.append(prog)
        }
        
        XCTAssertEqual(parts.count, 5)
        XCTAssertFalse(splitTracker.updates.isEmpty)
        XCTAssertEqual(parts[0].lastPathComponent, "archive_data.tar.001")
        XCTAssertEqual(parts[1].lastPathComponent, "archive_data.tar.002")
        XCTAssertEqual(parts[2].lastPathComponent, "archive_data.tar.003")
        XCTAssertEqual(parts[3].lastPathComponent, "archive_data.tar.004")
        XCTAssertEqual(parts[4].lastPathComponent, "archive_data.tar.005")
        
        // Verify .sfv checksum file was created
        let sfvURL = splitDir.appendingPathComponent("archive_data.tar.sfv")
        XCTAssertTrue(FileManager.default.fileExists(atPath: sfvURL.path))
        let sfvContent = try String(contentsOf: sfvURL, encoding: .utf8)
        XCTAssertTrue(sfvContent.contains("archive_data.tar.001"))
        XCTAssertTrue(sfvContent.contains("archive_data.tar.005"))
        
        // Join parts back
        let joinDir = tempDirectory.appendingPathComponent("joined_output")
        try FileManager.default.createDirectory(at: joinDir, withIntermediateDirectories: true)
        
        let joinTracker = ProgressTracker()
        let joinConfig = JoinConfig(
            firstPartURL: parts[0],
            destinationDirectory: joinDir,
            customOutputName: "reconstructed_archive.tar"
        )
        
        let joinedURL = try engine.joinFiles(config: joinConfig) { prog, msg in
            joinTracker.updates.append(prog)
        }
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: joinedURL.path))
        XCTAssertFalse(joinTracker.updates.isEmpty)
        
        let joinedAttrs = try FileManager.default.attributesOfItem(atPath: joinedURL.path)
        let joinedSize = (joinedAttrs[.size] as? NSNumber)?.intValue
        XCTAssertEqual(joinedSize, originalSize)
        
        // Compare SHA-256 Checksums
        let joinedSHA256 = try checksumService.calculateChecksum(for: joinedURL, algorithm: .sha256)
        XCTAssertEqual(joinedSHA256, originalSHA256)
    }
    
    // MARK: - Single Chunk Split
    
    func testSingleChunkSplit() throws {
        let engine = FileSplitJoinEngine.shared
        let originalURL = try createBinaryFile(name: "small_doc.pdf", sizeInBytes: 10 * 1024)
        
        let splitDir = tempDirectory.appendingPathComponent("single_split")
        try FileManager.default.createDirectory(at: splitDir, withIntermediateDirectories: true)
        
        // Chunk size larger than file (64 KB > 10 KB)
        let config = SplitConfig(sourceURL: originalURL, destinationDirectory: splitDir, chunkSize: 64 * 1024, generateChecksum: false)
        let parts = try engine.splitFile(config: config)
        
        XCTAssertEqual(parts.count, 1)
        XCTAssertEqual(parts[0].lastPathComponent, "small_doc.pdf.001")
        
        // Join with default suggested name
        let joinDir = tempDirectory.appendingPathComponent("single_join")
        try FileManager.default.createDirectory(at: joinDir, withIntermediateDirectories: true)
        
        let joinConfig = JoinConfig(firstPartURL: parts[0], destinationDirectory: joinDir)
        let joinedURL = try engine.joinFiles(config: joinConfig)
        
        XCTAssertEqual(joinedURL.lastPathComponent, "small_doc.pdf")
        XCTAssertEqual(try Data(contentsOf: joinedURL).count, 10 * 1024)
    }
    
    // MARK: - Sequential Parts Helper Detection
    
    func testFindSequentialParts() throws {
        let engine = FileSplitJoinEngine.shared
        let partDir = tempDirectory.appendingPathComponent("seq_parts")
        try FileManager.default.createDirectory(at: partDir, withIntermediateDirectories: true)
        
        let p1 = partDir.appendingPathComponent("movie.iso.001")
        let p2 = partDir.appendingPathComponent("movie.iso.002")
        let p3 = partDir.appendingPathComponent("movie.iso.003")
        
        try "p1".write(to: p1, atomically: true, encoding: .utf8)
        try "p2".write(to: p2, atomically: true, encoding: .utf8)
        try "p3".write(to: p3, atomically: true, encoding: .utf8)
        
        let found = engine.findSequentialParts(firstPartURL: p1)
        XCTAssertEqual(found.count, 3)
        XCTAssertEqual(found[0], p1)
        XCTAssertEqual(found[1], p2)
        XCTAssertEqual(found[2], p3)
        
        // Suggested name
        XCTAssertEqual(engine.suggestedJoinedName(firstPartURL: p1), "movie.iso")
        
        // Non-part file
        let regularFile = partDir.appendingPathComponent("standalone.txt")
        try "data".write(to: regularFile, atomically: true, encoding: .utf8)
        let singleResult = engine.findSequentialParts(firstPartURL: regularFile)
        XCTAssertEqual(singleResult.count, 1)
        XCTAssertEqual(engine.suggestedJoinedName(firstPartURL: regularFile), "joined_standalone.txt")
    }
    
    // MARK: - Preset Sizes
    
    func testSplitPresetSizes() {
        XCTAssertEqual(SplitPresetSize.floppy144.rawValue, 1457664)
        XCTAssertEqual(SplitPresetSize.zip100.rawValue, 104857600)
        XCTAssertEqual(SplitPresetSize.cd650.rawValue, 681574400)
        XCTAssertEqual(SplitPresetSize.cd700.rawValue, 734003200)
        XCTAssertEqual(SplitPresetSize.dvd43.rawValue, 4700000000)
        XCTAssertEqual(SplitPresetSize.custom1GB.rawValue, 1073741824)
        XCTAssertFalse(SplitPresetSize.floppy144.displayName.isEmpty)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testEmptySourceFileError() throws {
        let engine = FileSplitJoinEngine.shared
        let emptyFile = tempDirectory.appendingPathComponent("empty.txt")
        try "".write(to: emptyFile, atomically: true, encoding: .utf8)
        
        let outDir = tempDirectory.appendingPathComponent("empty_out")
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
        
        let config = SplitConfig(sourceURL: emptyFile, destinationDirectory: outDir, chunkSize: 1024)
        XCTAssertThrowsError(try engine.splitFile(config: config))
    }
    
    func testMinimumChunkSizeCap() {
        let dummyURL = tempDirectory.appendingPathComponent("dummy.txt")
        let config = SplitConfig(sourceURL: dummyURL, destinationDirectory: tempDirectory, chunkSize: 50)
        XCTAssertEqual(config.chunkSize, 1024, "Chunk size should be clamped to minimum 1 KB (1024 bytes)")
    }
}
