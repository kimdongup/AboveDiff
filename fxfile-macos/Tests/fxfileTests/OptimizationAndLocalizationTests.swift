import XCTest
@testable import fxfileCore
@testable import fxfileLocalization
@testable import fxfileState

final class OptimizationAndLocalizationTests: XCTestCase {
    var tempDirectory: URL!
    
    override func setUpWithError() throws {
        let tempBase = FileManager.default.temporaryDirectory
        tempDirectory = tempBase.appendingPathComponent("fxfile_opt_tests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
    }
    
    // MARK: - FileIconCache Tests
    
    func testFileIconCacheRetrievalAndCaching() throws {
        let folder = tempDirectory.appendingPathComponent("TestFolder")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        
        let file = tempDirectory.appendingPathComponent("test.swift")
        try "// swift code".write(to: file, atomically: true, encoding: .utf8)
        
        let folderItem = FileItem(url: folder)
        let fileItem = FileItem(url: file)
        
        let folderIcon1 = folderItem.icon
        let folderIcon2 = FileIconCache.shared.icon(for: folderItem)
        XCTAssertNotNil(folderIcon1)
        XCTAssertNotNil(folderIcon2)
        
        let fileIcon1 = fileItem.icon
        let fileIcon2 = FileIconCache.shared.icon(for: fileItem)
        XCTAssertNotNil(fileIcon1)
        XCTAssertNotNil(fileIcon2)
        
        FileIconCache.shared.clear()
        let fileIconAfterClear = FileIconCache.shared.icon(for: fileItem)
        XCTAssertNotNil(fileIconAfterClear)
    }
    
    // MARK: - Fast Resource Values Initialization
    
    func testFastFileItemInitializationWithPrefetchedResourceValues() throws {
        let file = tempDirectory.appendingPathComponent("document.pdf")
        let content = "PDF-1.4 header"
        try content.write(to: file, atomically: true, encoding: .utf8)
        
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isPackageKey,
            .isSymbolicLinkKey,
            .isHiddenKey,
            .fileSizeKey,
            .totalFileSizeKey,
            .creationDateKey,
            .contentModificationDateKey,
            .localizedTypeDescriptionKey,
            .isReadableKey,
            .isWritableKey,
            .isExecutableKey
        ]
        let res = try file.resourceValues(forKeys: keys)
        let fastItem = FileItem(url: file, resourceValues: res)
        
        XCTAssertEqual(fastItem.name, "document.pdf")
        XCTAssertEqual(fastItem.fileExtension, "pdf")
        XCTAssertFalse(fastItem.isDirectory)
        XCTAssertEqual(fastItem.size, Int64(content.utf8.count))
    }
    
    // MARK: - Localization Tests
    
    @MainActor
    func testLocalizationManagerEnglishAndKoreanStrings() {
        let loc = LocalizationManager.shared
        
        loc.currentLanguage = .english
        XCTAssertEqual(L10n("app.name"), "AboveDiff")
        XCTAssertEqual(L10n("action.open"), "Open")
        XCTAssertEqual(L10n("action.copy"), "Copy")
        XCTAssertEqual(L10n("action.delete"), "Delete")
        XCTAssertEqual(L10n("fkey.f2"), "F2 Rename")
        XCTAssertEqual(L10n("fkey.f5"), "F5 Copy")
        XCTAssertEqual(L10n("fkey.f7"), "F7 NewFolder")
        
        loc.currentLanguage = .korean
        XCTAssertEqual(L10n("app.name"), "AboveDiff")
        XCTAssertEqual(L10n("action.open"), "열기")
        XCTAssertEqual(L10n("action.copy"), "복사")
        XCTAssertEqual(L10n("action.delete"), "삭제")
        XCTAssertEqual(L10n("fkey.f2"), "F2 이름바꾸기")
        XCTAssertEqual(L10n("fkey.f5"), "F5 복사")
        XCTAssertEqual(L10n("fkey.f7"), "F7 새폴더")
        
        // Non-existent key fallback
        XCTAssertEqual(L10n("unknown.key.sample"), "unknown.key.sample")
        
        // Reset to English
        loc.currentLanguage = .english
    }
}
