import XCTest
@testable import AboveDiffCore

final class FileSystemTests: XCTestCase {
    var tempDirectory: URL!
    let service = FileSystemService.shared
    
    override func setUpWithError() throws {
        let tempBase = FileManager.default.temporaryDirectory
        tempDirectory = tempBase.appendingPathComponent("abovediff_fs_tests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
    }
    
    // MARK: - FileItem Formatting & Permissions
    
    func testFileItemFormattingAndPermissions() throws {
        let testFile = tempDirectory.appendingPathComponent("sample_document.markdown")
        let text = "# Hello AboveDiff Test"
        try text.write(to: testFile, atomically: true, encoding: .utf8)
        
        let item = FileItem(url: testFile)
        XCTAssertEqual(item.name, "sample_document.markdown")
        XCTAssertEqual(item.fileExtension, "markdown")
        XCTAssertFalse(item.isDirectory)
        XCTAssertEqual(item.size, Int64(text.utf8.count))
        XCTAssertFalse(item.formattedSize.isEmpty)
        XCTAssertFalse(item.formattedDate.isEmpty)
        XCTAssertFalse(item.permissionsString.isEmpty)
        XCTAssertFalse(item.octalPermissionsString.isEmpty)
    }
    
    func testPosixPermissionsFormatVectors() {
        XCTAssertEqual(FileItem.formatPosixPermissions(0o777), "rwxrwxrwx")
        XCTAssertEqual(FileItem.formatPosixPermissions(0o755), "rwxr-xr-x")
        XCTAssertEqual(FileItem.formatPosixPermissions(0o644), "rw-r--r--")
        XCTAssertEqual(FileItem.formatPosixPermissions(0o700), "rwx------")
        XCTAssertEqual(FileItem.formatPosixPermissions(0o600), "rw-------")
        XCTAssertEqual(FileItem.formatPosixPermissions(0o000), "---------")
    }
    
    // MARK: - Directory Scanning & Filtering
    
    func testDirectoryContentsAndHiddenFiltering() throws {
        let visibleFile = tempDirectory.appendingPathComponent("visible.txt")
        let hiddenFile = tempDirectory.appendingPathComponent(".hidden_file")
        let subFolder = tempDirectory.appendingPathComponent("MySubFolder")
        
        try "vis".write(to: visibleFile, atomically: true, encoding: .utf8)
        try "hid".write(to: hiddenFile, atomically: true, encoding: .utf8)
        try FileManager.default.createDirectory(at: subFolder, withIntermediateDirectories: true)
        
        // Default: hide hidden files
        let visibleItems = try service.contentsOfDirectory(at: tempDirectory, showHidden: false)
        XCTAssertFalse(visibleItems.contains { $0.name.hasPrefix(".") })
        XCTAssertTrue(visibleItems.contains { $0.name == "visible.txt" })
        XCTAssertTrue(visibleItems.contains { $0.name == "MySubFolder" })
        
        // Show hidden files
        let allItems = try service.contentsOfDirectory(at: tempDirectory, showHidden: true)
        XCTAssertTrue(allItems.contains { $0.name == ".hidden_file" })
        
        // Filter by string query
        let filtered = try service.contentsOfDirectory(at: tempDirectory, showHidden: true, filter: "hidden")
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, ".hidden_file")
    }
    
    // MARK: - Sorting Tests
    
    func testSortingInvariantsAndFields() throws {
        let f1 = tempDirectory.appendingPathComponent("Zebra.txt")
        let f2 = tempDirectory.appendingPathComponent("Apple.txt")
        let dirA = tempDirectory.appendingPathComponent("Folder_Z")
        let dirB = tempDirectory.appendingPathComponent("Folder_A")
        
        try "small".write(to: f1, atomically: true, encoding: .utf8)
        try "much longer text payload".write(to: f2, atomically: true, encoding: .utf8)
        try FileManager.default.createDirectory(at: dirA, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dirB, withIntermediateDirectories: true)
        
        let items = [
            FileItem(url: f1),
            FileItem(url: f2),
            FileItem(url: dirA),
            FileItem(url: dirB)
        ]
        
        // Sort by Name Ascending: Directories first (Folder_A, Folder_Z), then files (Apple.txt, Zebra.txt)
        let sortedByNameAsc = service.sortItems(items, by: .name, ascending: true)
        XCTAssertTrue(sortedByNameAsc[0].isDirectory)
        XCTAssertEqual(sortedByNameAsc[0].name, "Folder_A")
        XCTAssertEqual(sortedByNameAsc[1].name, "Folder_Z")
        XCTAssertFalse(sortedByNameAsc[2].isDirectory)
        XCTAssertEqual(sortedByNameAsc[2].name, "Apple.txt")
        XCTAssertEqual(sortedByNameAsc[3].name, "Zebra.txt")
        
        // Sort by Size Descending: Folders still first, then largest file to smallest
        let sortedBySizeDesc = service.sortItems(items, by: .size, ascending: false)
        XCTAssertTrue(sortedBySizeDesc[0].isDirectory)
        XCTAssertTrue(sortedBySizeDesc[1].isDirectory)
        XCTAssertFalse(sortedBySizeDesc[2].isDirectory)
        XCTAssertEqual(sortedBySizeDesc[2].name, "Apple.txt")
        XCTAssertEqual(sortedBySizeDesc[3].name, "Zebra.txt")
    }
    
    // MARK: - CRUD File Operations
    
    func testCreateFolderAndAutoNumbering() throws {
        let folder1 = try service.createFolder(at: tempDirectory, name: "Projects")
        XCTAssertEqual(folder1.lastPathComponent, "Projects")
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder1.path))
        
        // Collision should append counter " 1"
        let folder2 = try service.createFolder(at: tempDirectory, name: "Projects")
        XCTAssertEqual(folder2.lastPathComponent, "Projects 1")
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder2.path))
    }
    
    func testCreateTextFileAndContent() throws {
        let file1 = try service.createTextFile(at: tempDirectory, name: "Note.txt", content: "Hello Test")
        XCTAssertEqual(file1.lastPathComponent, "Note.txt")
        XCTAssertEqual(try String(contentsOf: file1, encoding: .utf8), "Hello Test")
        
        // Collision should append counter
        let file2 = try service.createTextFile(at: tempDirectory, name: "Note.txt", content: "Second Note")
        XCTAssertEqual(file2.lastPathComponent, "Note 1.txt")
    }
    
    func testCopyAndMoveOperations() throws {
        let sourceFile = try service.createTextFile(at: tempDirectory, name: "source.txt", content: "data")
        let subDir = try service.createFolder(at: tempDirectory, name: "SubDir")
        
        // Copy item
        let copiedURL = subDir.appendingPathComponent("source.txt")
        try service.copyItem(at: sourceFile, to: copiedURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: sourceFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: copiedURL.path))
        
        // Move item
        let movedURL = subDir.appendingPathComponent("moved.txt")
        try service.moveItem(at: sourceFile, to: movedURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: sourceFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: movedURL.path))
    }
    
    func testDuplicateItem() throws {
        let original = try service.createTextFile(at: tempDirectory, name: "Report.docx", content: "doc data")
        
        let dup1 = try service.duplicateItem(at: original)
        XCTAssertEqual(dup1.lastPathComponent, "Report copy.docx")
        XCTAssertTrue(FileManager.default.fileExists(atPath: dup1.path))
        
        let dup2 = try service.duplicateItem(at: original)
        XCTAssertEqual(dup2.lastPathComponent, "Report copy 2.docx")
        XCTAssertTrue(FileManager.default.fileExists(atPath: dup2.path))
    }
    
    func testRenameItem() throws {
        let file = try service.createTextFile(at: tempDirectory, name: "old_name.txt", content: "rename test")
        
        // Valid rename
        let renamed = try service.renameItem(at: file, newName: "  new_name.txt  ")
        XCTAssertEqual(renamed.lastPathComponent, "new_name.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: renamed.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        
        // Empty rename error
        XCTAssertThrowsError(try service.renameItem(at: renamed, newName: "   "))
    }
    
    func testDeleteOperations() throws {
        let file = try service.createTextFile(at: tempDirectory, name: "delete_me.txt", content: "trash")
        
        // Permanent delete
        try service.deleteItemPermanently(at: file)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }
    
    // MARK: - Volumes & Disk Space
    
    func testDiskSpaceQuery() {
        let space = service.getDiskSpace(for: tempDirectory)
        XCTAssertGreaterThan(space.total, 0)
        XCTAssertGreaterThan(space.free, 0)
        XCTAssertFalse(space.formattedTotal.isEmpty)
        XCTAssertFalse(space.formattedFree.isEmpty)
    }
}
