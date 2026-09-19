import XCTest
@testable import AboveDiffCore

final class FileSearchTests: XCTestCase {
    var tempDirectory: URL!
    let engine = FileSearchEngine.shared
    
    private final class ResultCollector: @unchecked Sendable {
        var items: [SearchResultItem] = []
    }
    
    override func setUpWithError() throws {
        let tempBase = FileManager.default.temporaryDirectory
        tempDirectory = tempBase.appendingPathComponent("abovediff_search_tests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
    }
    
    private func setupSearchTree() throws {
        let fm = FileManager.default
        
        // Root files
        let f1 = tempDirectory.appendingPathComponent("document_alpha.txt")
        let f2 = tempDirectory.appendingPathComponent("document_beta.pdf")
        let f3 = tempDirectory.appendingPathComponent("image_001.png")
        let f4 = tempDirectory.appendingPathComponent(".hidden_config.json")
        
        try "Secret token in document alpha".write(to: f1, atomically: true, encoding: .utf8)
        try "Pdf binary content".write(to: f2, atomically: true, encoding: .utf8)
        try "Fake png data".write(to: f3, atomically: true, encoding: .utf8)
        try "{\"key\": \"secret\"}".write(to: f4, atomically: true, encoding: .utf8)
        
        // Nested directory
        let subDir = tempDirectory.appendingPathComponent("Sources/Nested")
        try fm.createDirectory(at: subDir, withIntermediateDirectories: true)
        
        let codeFile = subDir.appendingPathComponent("Service.swift")
        let codeContent = """
        import Foundation
        
        struct Service {
            let secretApiKey = "abovediff-secure-key"
        }
        """
        try codeContent.write(to: codeFile, atomically: true, encoding: .utf8)
        
        let subDoc = subDir.appendingPathComponent("notes.md")
        try "# Project notes".write(to: subDoc, atomically: true, encoding: .utf8)
    }
    
    // MARK: - Wildcard Search Tests
    
    func testWildcardPatternSearch() throws {
        try setupSearchTree()
        let collector = ResultCollector()
        
        let criteria = SearchCriteria(
            rootURL: tempDirectory,
            nameQuery: "*.txt"
        )
        
        engine.search(criteria: criteria, onResult: { collector.items.append($0) }, shouldCancel: { false })
        
        XCTAssertEqual(collector.items.count, 1)
        XCTAssertEqual(collector.items.first?.fileItem.name, "document_alpha.txt")
    }
    
    // MARK: - Content Search with Line Number & Snippet
    
    func testContentSearchSnippetAndLineNumber() throws {
        try setupSearchTree()
        let collector = ResultCollector()
        
        let criteria = SearchCriteria(
            rootURL: tempDirectory,
            contentQuery: "secretApiKey"
        )
        
        engine.search(criteria: criteria, onResult: { collector.items.append($0) }, shouldCancel: { false })
        
        XCTAssertEqual(collector.items.count, 1)
        let match = collector.items.first!
        XCTAssertEqual(match.fileItem.name, "Service.swift")
        XCTAssertEqual(match.matchLineNumber, 4)
        XCTAssertTrue(match.matchSnippet?.contains("abovediff-secure-key") == true)
    }
    
    // MARK: - Type Filter Tests
    
    func testTypeFilter() throws {
        try setupSearchTree()
        
        // Filter .code
        let codeCollector = ResultCollector()
        let codeCriteria = SearchCriteria(rootURL: tempDirectory, typeFilter: .code)
        engine.search(criteria: codeCriteria, onResult: { codeCollector.items.append($0) }, shouldCancel: { false })
        XCTAssertEqual(codeCollector.items.count, 1)
        XCTAssertEqual(codeCollector.items.first?.fileItem.name, "Service.swift")
        
        // Filter .images
        let imgCollector = ResultCollector()
        let imgCriteria = SearchCriteria(rootURL: tempDirectory, typeFilter: .images)
        engine.search(criteria: imgCriteria, onResult: { imgCollector.items.append($0) }, shouldCancel: { false })
        XCTAssertEqual(imgCollector.items.count, 1)
        XCTAssertEqual(imgCollector.items.first?.fileItem.name, "image_001.png")
    }
    
    // MARK: - Hidden Files Filter
    
    func testHiddenFileFilter() throws {
        try setupSearchTree()
        
        // Default: skip hidden
        let noHidden = ResultCollector()
        let c1 = SearchCriteria(rootURL: tempDirectory, includeHidden: false)
        engine.search(criteria: c1, onResult: { noHidden.items.append($0) }, shouldCancel: { false })
        XCTAssertFalse(noHidden.items.contains { $0.fileItem.name == ".hidden_config.json" })
        
        // Include hidden
        let withHidden = ResultCollector()
        let c2 = SearchCriteria(rootURL: tempDirectory, includeHidden: true)
        engine.search(criteria: c2, onResult: { withHidden.items.append($0) }, shouldCancel: { false })
        XCTAssertTrue(withHidden.items.contains { $0.fileItem.name == ".hidden_config.json" })
    }
    
    // MARK: - Cancellation Token
    
    func testSearchCancellation() throws {
        try setupSearchTree()
        let collector = ResultCollector()
        let criteria = SearchCriteria(rootURL: tempDirectory)
        
        engine.search(criteria: criteria, onResult: { item in
            collector.items.append(item)
        }, shouldCancel: {
            return collector.items.count >= 2 // Cancel after 2 items
        })
        
        XCTAssertEqual(collector.items.count, 2)
    }
}
