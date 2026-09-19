import XCTest
@testable import AboveDiffCore

final class BatchRenameTests: XCTestCase {
    var tempDirectory: URL!
    
    override func setUpWithError() throws {
        let tempBase = FileManager.default.temporaryDirectory
        tempDirectory = tempBase.appendingPathComponent("fxfile_rename_tests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
    }
    
    private func createTestFiles(_ names: [String]) throws -> [FileItem] {
        var items: [FileItem] = []
        for name in names {
            let fileURL = tempDirectory.appendingPathComponent(name)
            try "sample content".write(to: fileURL, atomically: true, encoding: .utf8)
            items.append(FileItem(url: fileURL))
        }
        return items
    }
    
    // MARK: - Find and Replace
    
    func testFindAndReplaceCaseSensitive() throws {
        let files = try createTestFiles(["Document_Draft_v1.txt", "document_final_v1.txt"])
        
        let rules: [BatchRenameRule] = [
            .replaceText(find: "Document", replaceWith: "Report", caseSensitive: true)
        ]
        
        let previews = BatchRenameEngine.shared.generatePreview(files: files, rules: rules)
        XCTAssertEqual(previews[0].fullNewName, "Report_Draft_v1.txt")
        XCTAssertEqual(previews[1].fullNewName, "document_final_v1.txt") // Case mismatch, unchanged
    }
    
    func testFindAndReplaceCaseInsensitive() throws {
        let files = try createTestFiles(["Document_Draft_v1.txt", "document_final_v1.txt"])
        
        let rules: [BatchRenameRule] = [
            .replaceText(find: "document", replaceWith: "Report", caseSensitive: false)
        ]
        
        let previews = BatchRenameEngine.shared.generatePreview(files: files, rules: rules)
        XCTAssertEqual(previews[0].fullNewName, "Report_Draft_v1.txt")
        XCTAssertEqual(previews[1].fullNewName, "Report_final_v1.txt")
    }
    
    // MARK: - Regex Replacement
    
    func testRegexReplacementWithCaptureGroups() throws {
        let files = try createTestFiles(["IMG_20230821_001.jpg", "IMG_20230822_002.jpg"])
        
        // Pattern matches IMG_(date)_(seq) -> Vacation_$1_Seq$2
        let rules: [BatchRenameRule] = [
            .replaceRegex(pattern: #"IMG_(\d+)_(\d+)"#, template: "Vacation_$1_Seq$2")
        ]
        
        let previews = BatchRenameEngine.shared.generatePreview(files: files, rules: rules)
        XCTAssertEqual(previews[0].fullNewName, "Vacation_20230821_Seq001.jpg")
        XCTAssertEqual(previews[1].fullNewName, "Vacation_20230822_Seq002.jpg")
    }
    
    // MARK: - Prefix and Suffix
    
    func testAddPrefixAndSuffix() throws {
        let files = try createTestFiles(["photo.png", "video.mov"])
        
        let rules: [BatchRenameRule] = [
            .addPrefix(prefix: "2026_"),
            .addSuffix(suffix: "_archive")
        ]
        
        let previews = BatchRenameEngine.shared.generatePreview(files: files, rules: rules)
        XCTAssertEqual(previews[0].fullNewName, "2026_photo_archive.png")
        XCTAssertEqual(previews[1].fullNewName, "2026_video_archive.mov")
    }
    
    // MARK: - Insert and Delete Range
    
    func testInsertAtIndex() throws {
        let files = try createTestFiles(["abcde.txt"])
        
        // Insert at beginning (0)
        var previews = BatchRenameEngine.shared.generatePreview(files: files, rules: [.insertAt(text: "START_", index: 0)])
        XCTAssertEqual(previews[0].fullNewName, "START_abcde.txt")
        
        // Insert in middle (2)
        previews = BatchRenameEngine.shared.generatePreview(files: files, rules: [.insertAt(text: "_X_", index: 2)])
        XCTAssertEqual(previews[0].fullNewName, "ab_X_cde.txt")
        
        // Insert at end (out of bounds)
        previews = BatchRenameEngine.shared.generatePreview(files: files, rules: [.insertAt(text: "_END", index: 999)])
        XCTAssertEqual(previews[0].fullNewName, "abcde_END.txt")
    }
    
    func testDeleteRangeOperations() throws {
        let files = try createTestFiles(["ABC_TEST_XYZ.txt"])
        
        // Delete first 4 chars ("ABC_")
        var previews = BatchRenameEngine.shared.generatePreview(files: files, rules: [.deleteRange(fromStart: 0, count: 4)])
        XCTAssertEqual(previews[0].fullNewName, "TEST_XYZ.txt")
        
        // Delete last 4 chars ("_XYZ")
        previews = BatchRenameEngine.shared.generatePreview(files: files, rules: [.deleteFromEnd(count: 4)])
        XCTAssertEqual(previews[0].fullNewName, "ABC_TEST.txt")
        
        // Delete more characters than name length
        previews = BatchRenameEngine.shared.generatePreview(files: files, rules: [.deleteFromEnd(count: 50)])
        XCTAssertEqual(previews[0].fullNewName, "ABC_TEST_XYZ.txt") // Falls back to original base if empty
    }
    
    // MARK: - Case Transformations
    
    func testCaseTransformations() throws {
        let files = try createTestFiles(["hello world.txt", "THE QUICK FOX.txt"])
        
        // Lowercase
        var previews = BatchRenameEngine.shared.generatePreview(files: files, rules: [.changeCase(option: .lowercase)])
        XCTAssertEqual(previews[1].fullNewName, "the quick fox.txt")
        
        // Uppercase
        previews = BatchRenameEngine.shared.generatePreview(files: files, rules: [.changeCase(option: .uppercase)])
        XCTAssertEqual(previews[0].fullNewName, "HELLO WORLD.txt")
        
        // TitleCase
        previews = BatchRenameEngine.shared.generatePreview(files: files, rules: [.changeCase(option: .titleCase)])
        XCTAssertEqual(previews[0].fullNewName, "Hello World.txt")
        
        // Capitalized
        previews = BatchRenameEngine.shared.generatePreview(files: files, rules: [.changeCase(option: .capitalized)])
        XCTAssertEqual(previews[0].fullNewName, "Hello world.txt")
    }
    
    // MARK: - Sequential Numbering
    
    func testSequentialNumbering() throws {
        let files = try createTestFiles(["TrackA.mp3", "TrackB.mp3", "TrackC.mp3"])
        
        // Prefix with 3 digits, start 10, step 5 -> 010TrackA.mp3, 015TrackB.mp3, 020TrackC.mp3
        let prefixRules: [BatchRenameRule] = [
            .numbering(position: .prefix, start: 10, step: 5, digits: 3)
        ]
        var previews = BatchRenameEngine.shared.generatePreview(files: files, rules: prefixRules)
        XCTAssertEqual(previews[0].fullNewName, "010TrackA.mp3")
        XCTAssertEqual(previews[1].fullNewName, "015TrackB.mp3")
        XCTAssertEqual(previews[2].fullNewName, "020TrackC.mp3")
        
        // Suffix numbering
        let suffixRules: [BatchRenameRule] = [
            .numbering(position: .suffix, start: 1, step: 1, digits: 2)
        ]
        previews = BatchRenameEngine.shared.generatePreview(files: files, rules: suffixRules)
        XCTAssertEqual(previews[0].fullNewName, "TrackA01.mp3")
        XCTAssertEqual(previews[1].fullNewName, "TrackB02.mp3")
        
        // Replace base name with numbering
        let replaceRules: [BatchRenameRule] = [
            .numbering(position: .replace, start: 1, step: 1, digits: 4)
        ]
        previews = BatchRenameEngine.shared.generatePreview(files: files, rules: replaceRules)
        XCTAssertEqual(previews[0].fullNewName, "0001.mp3")
        XCTAssertEqual(previews[1].fullNewName, "0002.mp3")
    }
    
    // MARK: - Extension Changes
    
    func testExtensionChanges() throws {
        let files = try createTestFiles(["document.TXT", "script.PY"])
        
        // Lowercase extension
        var previews = BatchRenameEngine.shared.generatePreview(files: files, rules: [.changeExtension(newExt: "", remove: false, lowercase: true)])
        XCTAssertEqual(previews[0].fullNewName, "document.txt")
        XCTAssertEqual(previews[1].fullNewName, "script.py")
        
        // Change extension to .md
        previews = BatchRenameEngine.shared.generatePreview(files: files, rules: [.changeExtension(newExt: "md", remove: false, lowercase: true)])
        XCTAssertEqual(previews[0].fullNewName, "document.md")
        XCTAssertEqual(previews[1].fullNewName, "script.md")
        
        // Remove extension
        previews = BatchRenameEngine.shared.generatePreview(files: files, rules: [.changeExtension(newExt: "", remove: true, lowercase: false)])
        XCTAssertEqual(previews[0].fullNewName, "document")
        XCTAssertEqual(previews[1].fullNewName, "script")
    }
    
    // MARK: - Conflict & Collision Detection
    
    func testDuplicateNameInBatchConflict() throws {
        let files = try createTestFiles(["file1.txt", "file2.txt"])
        
        // Rule replaces whole base name with constant string "fixed"
        let rules: [BatchRenameRule] = [
            .replaceRegex(pattern: ".*", template: "fixed")
        ]
        
        let previews = BatchRenameEngine.shared.generatePreview(files: files, rules: rules)
        XCTAssertFalse(previews[0].hasConflict)
        XCTAssertTrue(previews[1].hasConflict)
        XCTAssertEqual(previews[1].errorMessage, "Duplicate filename in batch")
    }
    
    func testTargetAlreadyExistsOnDiskConflict() throws {
        let files = try createTestFiles(["alpha.txt", "beta.txt", "existing.txt"])
        
        // Rename alpha.txt -> existing.txt
        let rules: [BatchRenameRule] = [
            .replaceText(find: "alpha", replaceWith: "existing", caseSensitive: true)
        ]
        
        let previews = BatchRenameEngine.shared.generatePreview(files: files, rules: rules)
        let alphaPreview = previews.first { $0.originalName == "alpha" }!
        XCTAssertTrue(alphaPreview.hasConflict)
        XCTAssertEqual(alphaPreview.errorMessage, "File already exists on disk")
    }
    
    // MARK: - Execution Tests
    
    func testExecuteRenameStandard() throws {
        let files = try createTestFiles(["item_A.txt", "item_B.txt"])
        let rules: [BatchRenameRule] = [
            .replaceText(find: "item_", replaceWith: "data_", caseSensitive: true)
        ]
        
        let previews = BatchRenameEngine.shared.generatePreview(files: files, rules: rules)
        let resultMap = try BatchRenameEngine.shared.executeRename(previews: previews)
        
        XCTAssertEqual(resultMap.count, 2)
        XCTAssertFalse(FileManager.default.fileExists(atPath: files[0].path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: files[1].path))
        
        let expectedURLA = tempDirectory.appendingPathComponent("data_A.txt")
        let expectedURLB = tempDirectory.appendingPathComponent("data_B.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedURLA.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedURLB.path))
    }
    
    func testExecuteRenameCaseOnlyChange() throws {
        let files = try createTestFiles(["UPPERCASE.txt"])
        let rules: [BatchRenameRule] = [
            .changeCase(option: .lowercase)
        ]
        
        let previews = BatchRenameEngine.shared.generatePreview(files: files, rules: rules)
        let resultMap = try BatchRenameEngine.shared.executeRename(previews: previews)
        
        XCTAssertEqual(resultMap.count, 1)
        let finalURL = tempDirectory.appendingPathComponent("uppercase.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: finalURL.path))
    }
}
