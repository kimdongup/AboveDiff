import XCTest
@testable import AboveDiffCore

final class ChecksumTests: XCTestCase {
    var tempDirectory: URL!
    
    override func setUpWithError() throws {
        let tempBase = FileManager.default.temporaryDirectory
        tempDirectory = tempBase.appendingPathComponent("abovediff_checksum_tests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
    }
    
    // MARK: - CRC32 Official Vectors (IEEE 802.3)
    
    func testCRC32KnownVectors() {
        let service = ChecksumService.shared
        
        // Vector 1: Empty data
        let emptyData = Data()
        XCTAssertEqual(service.calculateCRC32(data: emptyData), 0x00000000)
        XCTAssertEqual(service.calculateChecksum(data: emptyData, algorithm: .crc32), "00000000")
        
        // Vector 2: Single byte "a"
        let aData = "a".data(using: .utf8)!
        XCTAssertEqual(service.calculateCRC32(data: aData), 0xE8B7BE43)
        XCTAssertEqual(service.calculateChecksum(data: aData, algorithm: .crc32), "E8B7BE43")
        
        // Vector 3: Standard string "123456789"
        let numData = "123456789".data(using: .utf8)!
        XCTAssertEqual(service.calculateCRC32(data: numData), 0xCBF43926)
        XCTAssertEqual(service.calculateChecksum(data: numData, algorithm: .crc32), "CBF43926")
        
        // Vector 4: Pangram
        let foxData = "The quick brown fox jumps over the lazy dog".data(using: .utf8)!
        XCTAssertEqual(service.calculateCRC32(data: foxData), 0x414FA339)
        XCTAssertEqual(service.calculateChecksum(data: foxData, algorithm: .crc32), "414FA339")
    }
    
    // MARK: - MD5 RFC 1321 Vectors
    
    func testMD5KnownVectors() {
        let service = ChecksumService.shared
        
        let empty = service.calculateChecksum(data: Data(), algorithm: .md5)
        XCTAssertEqual(empty, "d41d8cd98f00b204e9800998ecf8427e")
        
        let a = service.calculateChecksum(data: "a".data(using: .utf8)!, algorithm: .md5)
        XCTAssertEqual(a, "0cc175b9c0f1b6a831c399e269772661")
        
        let abc = service.calculateChecksum(data: "abc".data(using: .utf8)!, algorithm: .md5)
        XCTAssertEqual(abc, "900150983cd24fb0d6963f7d28e17f72")
        
        let fox = service.calculateChecksum(data: "The quick brown fox jumps over the lazy dog".data(using: .utf8)!, algorithm: .md5)
        XCTAssertEqual(fox, "9e107d9d372bb6826bd81d3542a419d6")
    }
    
    // MARK: - SHA-1 RFC 3174 Vectors
    
    func testSHA1KnownVectors() {
        let service = ChecksumService.shared
        
        let empty = service.calculateChecksum(data: Data(), algorithm: .sha1)
        XCTAssertEqual(empty, "da39a3ee5e6b4b0d3255bfef95601890afd80709")
        
        let abc = service.calculateChecksum(data: "abc".data(using: .utf8)!, algorithm: .sha1)
        XCTAssertEqual(abc, "a9993e364706816aba3e25717850c26c9cd0d89d")
        
        let fox = service.calculateChecksum(data: "The quick brown fox jumps over the lazy dog".data(using: .utf8)!, algorithm: .sha1)
        XCTAssertEqual(fox, "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12")
    }
    
    // MARK: - SHA-256 FIPS 180-4 Vectors
    
    func testSHA256KnownVectors() {
        let service = ChecksumService.shared
        
        let empty = service.calculateChecksum(data: Data(), algorithm: .sha256)
        XCTAssertEqual(empty, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        
        let abc = service.calculateChecksum(data: "abc".data(using: .utf8)!, algorithm: .sha256)
        XCTAssertEqual(abc, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        
        let fox = service.calculateChecksum(data: "The quick brown fox jumps over the lazy dog".data(using: .utf8)!, algorithm: .sha256)
        XCTAssertEqual(fox, "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592")
    }
    
    // MARK: - SHA-512 FIPS 180-4 Vectors
    
    func testSHA512KnownVectors() {
        let service = ChecksumService.shared
        
        let empty = service.calculateChecksum(data: Data(), algorithm: .sha512)
        XCTAssertEqual(empty, "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e")
        
        let abc = service.calculateChecksum(data: "abc".data(using: .utf8)!, algorithm: .sha512)
        XCTAssertEqual(abc, "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f")
    }
    
    // MARK: - Streaming File Hashing Tests
    
    private final class ProgressTracker: @unchecked Sendable {
        var updates: [Double] = []
    }
    
    func testFileStreamingChecksums() throws {
        let service = ChecksumService.shared
        let testFile = tempDirectory.appendingPathComponent("sample_stream.dat")
        
        // Write 2.5 MB of structured data (to test buffer chunking > 1MB)
        let totalSize = 2500 * 1024
        var data = Data(count: totalSize)
        for i in 0..<totalSize {
            data[i] = UInt8((i * 31 + 17) % 256)
        }
        try data.write(to: testFile)
        
        for algo in ChecksumAlgorithm.allCases {
            let tracker = ProgressTracker()
            let fileHash = try service.calculateChecksum(for: testFile, algorithm: algo) { prog in
                tracker.updates.append(prog)
            }
            let dataHash = service.calculateChecksum(data: data, algorithm: algo)
            
            XCTAssertEqual(fileHash.lowercased(), dataHash.lowercased(), "Mismatch for algorithm \(algo.rawValue)")
            XCTAssertFalse(tracker.updates.isEmpty, "Progress should have been reported for \(algo.rawValue)")
            if let last = tracker.updates.last {
                XCTAssertEqual(last, 1.0, accuracy: 0.01)
            }
        }
    }
    
    // MARK: - Checksum Verification Tests
    
    func testVerifyChecksum() throws {
        let service = ChecksumService.shared
        let testFile = tempDirectory.appendingPathComponent("verify_test.txt")
        let content = "AboveDiff macOS checksum test payload"
        try content.write(to: testFile, atomically: true, encoding: .utf8)
        
        let expectedSHA256 = service.calculateChecksum(data: content.data(using: .utf8)!, algorithm: .sha256)
        
        // Exact match
        XCTAssertTrue(try service.verifyChecksum(fileURL: testFile, expectedHash: expectedSHA256, algorithm: .sha256))
        
        // Case-insensitive match (uppercase hash against lowercase)
        XCTAssertTrue(try service.verifyChecksum(fileURL: testFile, expectedHash: expectedSHA256.uppercased(), algorithm: .sha256))
        
        // Trimmed whitespace match
        XCTAssertTrue(try service.verifyChecksum(fileURL: testFile, expectedHash: "  \(expectedSHA256)\n", algorithm: .sha256))
        
        // Incorrect hash
        XCTAssertFalse(try service.verifyChecksum(fileURL: testFile, expectedHash: "0000000000000000000000000000000000000000000000000000000000000000", algorithm: .sha256))
    }
    
    // MARK: - Export Generation Tests
    
    func testChecksumExportGeneration() {
        let service = ChecksumService.shared
        let file1 = URL(fileURLWithPath: "/path/to/archive.zip")
        let file2 = URL(fileURLWithPath: "/path/to/image.png")
        
        let results = [
            ChecksumResult(algorithm: .crc32, hash: "DEADBEEF", fileURL: file1, fileSize: 1024),
            ChecksumResult(algorithm: .crc32, hash: "CAFEBABE", fileURL: file2, fileSize: 2048)
        ]
        
        // CRC32 SFV format
        let sfvExport = service.generateChecksumExport(results: results, algorithm: .crc32)
        XCTAssertTrue(sfvExport.contains("; Generated by AboveDiff (macOS)"))
        XCTAssertTrue(sfvExport.contains("archive.zip DEADBEEF"))
        XCTAssertTrue(sfvExport.contains("image.png CAFEBABE"))
        
        // SHA-256 standard export format: "<hash>  <filename>"
        let shaResults = [
            ChecksumResult(algorithm: .sha256, hash: "e3b0c442", fileURL: file1, fileSize: 1024)
        ]
        let shaExport = service.generateChecksumExport(results: shaResults, algorithm: .sha256)
        XCTAssertTrue(shaExport.hasPrefix("e3b0c442  archive.zip\n"))
    }
    
    // MARK: - Algorithm Enum Properties
    
    func testAlgorithmExtensions() {
        XCTAssertEqual(ChecksumAlgorithm.crc32.defaultExtension, "sfv")
        XCTAssertEqual(ChecksumAlgorithm.md5.defaultExtension, "md5")
        XCTAssertEqual(ChecksumAlgorithm.sha1.defaultExtension, "sha1")
        XCTAssertEqual(ChecksumAlgorithm.sha256.defaultExtension, "sha256")
        XCTAssertEqual(ChecksumAlgorithm.sha512.defaultExtension, "sha512")
        XCTAssertEqual(ChecksumAlgorithm.crc32.id, "CRC32")
    }
}
