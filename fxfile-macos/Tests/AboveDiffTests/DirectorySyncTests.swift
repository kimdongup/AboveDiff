import XCTest
@testable import AboveDiffCore

final class DirectorySyncTests: XCTestCase {
    var tempDirectory: URL!
    var sourceDir: URL!
    var targetDir: URL!
    
    override func setUpWithError() throws {
        let tempBase = FileManager.default.temporaryDirectory
        tempDirectory = tempBase.appendingPathComponent("fxfile_sync_tests_\(UUID().uuidString)")
        sourceDir = tempDirectory.appendingPathComponent("source")
        targetDir = tempDirectory.appendingPathComponent("target")
        
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
    }
    
    private func setupComplexDirectoryScenario() throws {
        let fm = FileManager.default
        
        // 1. Identical file (same content, same modification date)
        let sharedSrc = sourceDir.appendingPathComponent("identical.txt")
        let sharedTgt = targetDir.appendingPathComponent("identical.txt")
        try "identical content".write(to: sharedSrc, atomically: true, encoding: .utf8)
        try "identical content".write(to: sharedTgt, atomically: true, encoding: .utf8)
        let baseDate = Date(timeIntervalSince1970: 1700000000)
        try fm.setAttributes([.modificationDate: baseDate], ofItemAtPath: sharedSrc.path)
        try fm.setAttributes([.modificationDate: baseDate], ofItemAtPath: sharedTgt.path)
        
        // 2. Newer in source
        let newerSrc = sourceDir.appendingPathComponent("source_newer.txt")
        let olderInTgt = targetDir.appendingPathComponent("source_newer.txt")
        try "source content new".write(to: newerSrc, atomically: true, encoding: .utf8)
        try "target content old".write(to: olderInTgt, atomically: true, encoding: .utf8)
        try fm.setAttributes([.modificationDate: Date(timeIntervalSince1970: 1700005000)], ofItemAtPath: newerSrc.path)
        try fm.setAttributes([.modificationDate: Date(timeIntervalSince1970: 1700001000)], ofItemAtPath: olderInTgt.path)
        
        // 3. Newer in target
        let olderInSrc = sourceDir.appendingPathComponent("target_newer.txt")
        let newerTgt = targetDir.appendingPathComponent("target_newer.txt")
        try "source content old".write(to: olderInSrc, atomically: true, encoding: .utf8)
        try "target content new".write(to: newerTgt, atomically: true, encoding: .utf8)
        try fm.setAttributes([.modificationDate: Date(timeIntervalSince1970: 1700001000)], ofItemAtPath: olderInSrc.path)
        try fm.setAttributes([.modificationDate: Date(timeIntervalSince1970: 1700005000)], ofItemAtPath: newerTgt.path)
        
        // 4. Missing in target
        let srcOnly = sourceDir.appendingPathComponent("only_in_source.txt")
        try "source only payload".write(to: srcOnly, atomically: true, encoding: .utf8)
        
        // 5. Missing in source
        let tgtOnly = targetDir.appendingPathComponent("only_in_target.txt")
        try "target only payload".write(to: tgtOnly, atomically: true, encoding: .utf8)
        
        // 6. Nested subdirectories
        let subSrc = sourceDir.appendingPathComponent("nested_folder")
        let subTgt = targetDir.appendingPathComponent("nested_folder")
        try fm.createDirectory(at: subSrc, withIntermediateDirectories: true)
        try fm.createDirectory(at: subTgt, withIntermediateDirectories: true)
        
        let nestedSrc = subSrc.appendingPathComponent("nested_file.txt")
        try "nested payload".write(to: nestedSrc, atomically: true, encoding: .utf8)
    }
    
    // MARK: - Comparison Classification Tests
    
    func testCompareDirectoriesClassification() throws {
        try setupComplexDirectoryScenario()
        let engine = DirectorySyncEngine.shared
        
        let results = try engine.compareDirectories(
            source: sourceDir,
            target: targetDir,
            direction: .sourceToTargetUpdate
        )
        
        let itemMap = Dictionary(uniqueKeysWithValues: results.map { ($0.relativePath, $0) })
        
        // Assert identical
        XCTAssertEqual(itemMap["identical.txt"]?.status, .equal)
        XCTAssertEqual(itemMap["identical.txt"]?.action, .skip)
        
        // Assert newer in source
        XCTAssertEqual(itemMap["source_newer.txt"]?.status, .newerInSource)
        XCTAssertEqual(itemMap["source_newer.txt"]?.action, .copyToTarget)
        
        // Assert newer in target
        XCTAssertEqual(itemMap["target_newer.txt"]?.status, .newerInTarget)
        XCTAssertEqual(itemMap["target_newer.txt"]?.action, .copyToTarget) // In sourceToTargetUpdate, source overwrites target
        
        // Assert missing in target
        XCTAssertEqual(itemMap["only_in_source.txt"]?.status, .missingInTarget)
        XCTAssertEqual(itemMap["only_in_source.txt"]?.action, .copyToTarget)
        
        // Assert missing in source
        XCTAssertEqual(itemMap["only_in_target.txt"]?.status, .missingInSource)
        XCTAssertEqual(itemMap["only_in_target.txt"]?.action, .skip) // Update ignores files only in target
        
        // Assert nested file
        XCTAssertEqual(itemMap["nested_folder/nested_file.txt"]?.status, .missingInTarget)
        XCTAssertEqual(itemMap["nested_folder/nested_file.txt"]?.action, .copyToTarget)
    }
    
    func testCompareDirectionsActions() throws {
        try setupComplexDirectoryScenario()
        let engine = DirectorySyncEngine.shared
        
        // 1. Mirror Sync: Missing in source should be marked for deletion from target
        let mirrorResults = try engine.compareDirectories(
            source: sourceDir,
            target: targetDir,
            direction: .sourceToTargetMirror
        )
        let mirrorMap = Dictionary(uniqueKeysWithValues: mirrorResults.map { ($0.relativePath, $0) })
        XCTAssertEqual(mirrorMap["only_in_target.txt"]?.action, .deleteFromTarget)
        XCTAssertEqual(mirrorMap["only_in_source.txt"]?.action, .copyToTarget)
        
        // 2. Bidirectional Sync: Newer in target copied to source, missing in source copied to source
        let biResults = try engine.compareDirectories(
            source: sourceDir,
            target: targetDir,
            direction: .bidirectional
        )
        let biMap = Dictionary(uniqueKeysWithValues: biResults.map { ($0.relativePath, $0) })
        XCTAssertEqual(biMap["target_newer.txt"]?.action, .copyToSource)
        XCTAssertEqual(biMap["only_in_target.txt"]?.action, .copyToSource)
        XCTAssertEqual(biMap["source_newer.txt"]?.action, .copyToTarget)
        XCTAssertEqual(biMap["only_in_source.txt"]?.action, .copyToTarget)
        
        // 3. Target to Source Sync
        let tgtSrcResults = try engine.compareDirectories(
            source: sourceDir,
            target: targetDir,
            direction: .targetToSource
        )
        let tgtSrcMap = Dictionary(uniqueKeysWithValues: tgtSrcResults.map { ($0.relativePath, $0) })
        XCTAssertEqual(tgtSrcMap["only_in_source.txt"]?.action, .skip)
        XCTAssertEqual(tgtSrcMap["only_in_target.txt"]?.action, .copyToSource)
        XCTAssertEqual(tgtSrcMap["target_newer.txt"]?.action, .copyToSource)
    }
    
    // MARK: - Execute Sync Tests
    
    func testExecuteMirrorSync() throws {
        try setupComplexDirectoryScenario()
        let engine = DirectorySyncEngine.shared
        let fm = FileManager.default
        
        let mirrorItems = try engine.compareDirectories(
            source: sourceDir,
            target: targetDir,
            direction: .sourceToTargetMirror
        )
        
        try engine.executeSync(items: mirrorItems, sourceBase: sourceDir, targetBase: targetDir)
        
        // Target should have 'only_in_source.txt' copied
        XCTAssertTrue(fm.fileExists(atPath: targetDir.appendingPathComponent("only_in_source.txt").path))
        
        // Target should have 'only_in_target.txt' deleted
        XCTAssertFalse(fm.fileExists(atPath: targetDir.appendingPathComponent("only_in_target.txt").path))
        
        // Target should have nested_folder/nested_file.txt created
        XCTAssertTrue(fm.fileExists(atPath: targetDir.appendingPathComponent("nested_folder/nested_file.txt").path))
        
        // Target's source_newer.txt should have the new content from source
        let syncedContent = try String(contentsOf: targetDir.appendingPathComponent("source_newer.txt"), encoding: .utf8)
        XCTAssertEqual(syncedContent, "source content new")
    }
    
    func testExecuteBidirectionalSync() throws {
        try setupComplexDirectoryScenario()
        let engine = DirectorySyncEngine.shared
        let fm = FileManager.default
        
        let biItems = try engine.compareDirectories(
            source: sourceDir,
            target: targetDir,
            direction: .bidirectional
        )
        
        try engine.executeSync(items: biItems, sourceBase: sourceDir, targetBase: targetDir)
        
        // Source should now have only_in_target.txt
        XCTAssertTrue(fm.fileExists(atPath: sourceDir.appendingPathComponent("only_in_target.txt").path))
        
        // Target should now have only_in_source.txt
        XCTAssertTrue(fm.fileExists(atPath: targetDir.appendingPathComponent("only_in_source.txt").path))
        
        // Source's target_newer.txt should be updated with target content
        let srcContent = try String(contentsOf: sourceDir.appendingPathComponent("target_newer.txt"), encoding: .utf8)
        XCTAssertEqual(srcContent, "target content new")
    }
}
