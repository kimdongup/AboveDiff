import XCTest
@testable import fxfileCore
@testable import fxfileState

@MainActor
final class StateTests: XCTestCase {
    var tempDirectory: URL!
    var subDirA: URL!
    var subDirB: URL!
    
    override func setUpWithError() throws {
        let tempBase = FileManager.default.temporaryDirectory
        tempDirectory = tempBase.appendingPathComponent("fxfile_state_tests_\(UUID().uuidString)")
        subDirA = tempDirectory.appendingPathComponent("FolderA")
        subDirB = tempDirectory.appendingPathComponent("FolderB")
        
        try FileManager.default.createDirectory(at: subDirA, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: subDirB, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
    }
    
    // MARK: - PaneState Tests
    
    func testPaneStateTabManagement() {
        let pane = PaneState(initialURL: tempDirectory)
        XCTAssertEqual(pane.tabs.count, 1)
        XCTAssertEqual(pane.activeTabIndex, 0)
        XCTAssertEqual(pane.currentURL.standardizedFileURL.path, tempDirectory.standardizedFileURL.path)
        
        // Add tab
        pane.addTab(url: subDirA)
        XCTAssertEqual(pane.tabs.count, 2)
        XCTAssertEqual(pane.activeTabIndex, 1)
        XCTAssertEqual(pane.currentURL.standardizedFileURL.path, subDirA.standardizedFileURL.path)
        
        // Switch tab
        pane.selectTab(at: 0)
        XCTAssertEqual(pane.activeTabIndex, 0)
        XCTAssertEqual(pane.currentURL.standardizedFileURL.path, tempDirectory.standardizedFileURL.path)
        
        // Close tab
        pane.closeTab(at: 0)
        XCTAssertEqual(pane.tabs.count, 1)
        XCTAssertEqual(pane.activeTabIndex, 0)
        XCTAssertEqual(pane.currentURL.standardizedFileURL.path, subDirA.standardizedFileURL.path)
    }
    
    func testPaneStateNavigationHistory() {
        let pane = PaneState(initialURL: tempDirectory)
        XCTAssertFalse(pane.canGoBack)
        XCTAssertFalse(pane.canGoForward)
        
        // Navigate forward to subDirA
        pane.navigateTo(url: subDirA)
        XCTAssertTrue(pane.canGoBack)
        XCTAssertFalse(pane.canGoForward)
        XCTAssertEqual(pane.currentURL.standardizedFileURL.path, subDirA.standardizedFileURL.path)
        
        // Navigate forward to subDirB
        pane.navigateTo(url: subDirB)
        XCTAssertTrue(pane.canGoBack)
        XCTAssertFalse(pane.canGoForward)
        
        // Go back to subDirA
        pane.goBack()
        XCTAssertEqual(pane.currentURL.standardizedFileURL.path, subDirA.standardizedFileURL.path)
        XCTAssertTrue(pane.canGoForward)
        XCTAssertTrue(pane.canGoBack)
        
        // Go back to tempDirectory
        pane.goBack()
        XCTAssertEqual(pane.currentURL.standardizedFileURL.path, tempDirectory.standardizedFileURL.path)
        XCTAssertFalse(pane.canGoBack)
        XCTAssertTrue(pane.canGoForward)
        
        // Go forward to subDirA
        pane.goForward()
        XCTAssertEqual(pane.currentURL.standardizedFileURL.path, subDirA.standardizedFileURL.path)
        
        // Test go up
        XCTAssertTrue(pane.canGoUp)
        pane.goUp()
        XCTAssertEqual(pane.currentURL.standardizedFileURL.path, tempDirectory.standardizedFileURL.path)
    }
    
    func testPaneStateSelection() throws {
        let f1 = tempDirectory.appendingPathComponent("file1.txt")
        let f2 = tempDirectory.appendingPathComponent("file2.txt")
        let f3 = tempDirectory.appendingPathComponent("file3.txt")
        try "1".write(to: f1, atomically: true, encoding: .utf8)
        try "2".write(to: f2, atomically: true, encoding: .utf8)
        try "3".write(to: f3, atomically: true, encoding: .utf8)
        
        let pane = PaneState(initialURL: tempDirectory)
        
        let item1 = FileItem(url: f1)
        let item2 = FileItem(url: f2)
        let item3 = FileItem(url: f3)
        pane.files = [item1, item2, item3]
        
        // Select All
        pane.selectAll()
        XCTAssertEqual(pane.selectedItemIDs.count, 3)
        XCTAssertEqual(pane.selectedFiles.count, 3)
        
        // Clear selection
        pane.clearSelection()
        XCTAssertEqual(pane.selectedItemIDs.count, 0)
        XCTAssertEqual(pane.selectedFiles.count, 0)
        
        // Invert Selection
        pane.selectedItemIDs = [item1.id]
        pane.invertSelection()
        XCTAssertEqual(pane.selectedItemIDs.count, 2)
        XCTAssertTrue(pane.selectedItemIDs.contains(item2.id))
        XCTAssertTrue(pane.selectedItemIDs.contains(item3.id))
        XCTAssertFalse(pane.selectedItemIDs.contains(item1.id))
    }
    
    // MARK: - AppState Tests
    
    func testAppStatePanesAndSwitching() {
        let appState = AppState()
        XCTAssertEqual(appState.activePaneIndex, 0)
        XCTAssertTrue(appState.activePane === appState.leftPane)
        XCTAssertTrue(appState.inactivePane === appState.rightPane)
        
        // Switch active pane
        appState.switchActivePane()
        XCTAssertEqual(appState.activePaneIndex, 1)
        XCTAssertTrue(appState.activePane === appState.rightPane)
        XCTAssertTrue(appState.inactivePane === appState.leftPane)
    }
    
    func testAppStateBookmarks() {
        let appState = AppState()
        let initialCount = appState.bookmarks.count
        
        // Add bookmark
        let newURL = URL(fileURLWithPath: "/tmp/my_bookmark")
        appState.addBookmark(name: "My Bookmark", url: newURL)
        XCTAssertEqual(appState.bookmarks.count, initialCount + 1)
        
        let added = appState.bookmarks.last!
        XCTAssertEqual(added.name, "My Bookmark")
        XCTAssertEqual(added.url, newURL)
        
        // Remove bookmark
        appState.removeBookmark(id: added.id)
        XCTAssertEqual(appState.bookmarks.count, initialCount)
    }
    
    func testAppStateFileScrapBasket() throws {
        let fileA = tempDirectory.appendingPathComponent("scrapA.txt")
        let fileB = tempDirectory.appendingPathComponent("scrapB.txt")
        try "A".write(to: fileA, atomically: true, encoding: .utf8)
        try "B".write(to: fileB, atomically: true, encoding: .utf8)
        
        let itemA = FileItem(url: fileA)
        let itemB = FileItem(url: fileB)
        
        let appState = AppState()
        XCTAssertTrue(appState.fileScrapItems.isEmpty)
        
        // Add to scrap
        appState.addToScrap(files: [itemA, itemB])
        XCTAssertEqual(appState.fileScrapItems.count, 2)
        
        // Add duplicate (should not duplicate in scrap)
        appState.addToScrap(files: [itemA])
        XCTAssertEqual(appState.fileScrapItems.count, 2)
        
        // Remove from scrap
        appState.removeFromScrap(files: [itemA])
        XCTAssertEqual(appState.fileScrapItems.count, 1)
        XCTAssertEqual(appState.fileScrapItems.first?.url, fileB)
        
        // Clear scrap
        appState.clearScrap()
        XCTAssertTrue(appState.fileScrapItems.isEmpty)
    }
    
    func testAppStateClipboardOperations() throws {
        let fileA = tempDirectory.appendingPathComponent("clipA.txt")
        try "A".write(to: fileA, atomically: true, encoding: .utf8)
        let itemA = FileItem(url: fileA)
        
        let appState = AppState()
        appState.leftPane.files = [itemA]
        appState.leftPane.selectedItemIDs = [itemA.id]
        
        // Copy
        appState.performCopy()
        XCTAssertEqual(appState.clipboardURLs, [fileA])
        XCTAssertFalse(appState.clipboardIsCut)
        
        // Cut
        appState.performCut()
        XCTAssertEqual(appState.clipboardURLs, [fileA])
        XCTAssertTrue(appState.clipboardIsCut)
    }
}
