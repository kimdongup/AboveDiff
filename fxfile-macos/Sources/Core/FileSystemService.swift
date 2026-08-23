import Foundation
import AppKit

public struct VolumeItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let url: URL
    public let totalSpace: Int64
    public let freeSpace: Int64
    public let isRemovable: Bool
    public let isRoot: Bool
    
    public init(
        id: String,
        name: String,
        url: URL,
        totalSpace: Int64,
        freeSpace: Int64,
        isRemovable: Bool,
        isRoot: Bool
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.totalSpace = totalSpace
        self.freeSpace = freeSpace
        self.isRemovable = isRemovable
        self.isRoot = isRoot
    }
    
    public var formattedFreeSpace: String {
        ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file)
    }
    
    public var formattedTotalSpace: String {
        ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file)
    }
    
    public var usagePercentage: Double {
        guard totalSpace > 0 else { return 0 }
        let used = Double(totalSpace - freeSpace)
        return min(max(used / Double(totalSpace), 0.0), 1.0)
    }
}

public final class FileSystemService: @unchecked Sendable {
    public static let shared = FileSystemService()
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - Directory Scanning
    
    public func contentsOfDirectory(
        at url: URL,
        showHidden: Bool = false,
        sortField: FileSortField = .name,
        sortAscending: Bool = true,
        filter: String? = nil
    ) throws -> [FileItem] {
        let keys: [URLResourceKey] = [
            .nameKey,
            .isDirectoryKey,
            .isPackageKey,
            .isSymbolicLinkKey,
            .isHiddenKey,
            .fileSizeKey,
            .totalFileSizeKey,
            .contentModificationDateKey,
            .creationDateKey,
            .contentAccessDateKey,
            .localizedTypeDescriptionKey,
            .isReadableKey,
            .isWritableKey,
            .isExecutableKey
        ]
        
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: keys,
            options: showHidden ? [] : [.skipsHiddenFiles]
        )
        
        var items: [FileItem] = []
        items.reserveCapacity(contents.count)
        
        for fileURL in contents {
            if !showHidden && fileURL.lastPathComponent.hasPrefix(".") {
                continue
            }
            
            let res = try? fileURL.resourceValues(forKeys: Set(keys))
            let item = FileItem(url: fileURL, resourceValues: res)
            
            if let filter = filter, !filter.trimmingCharacters(in: .whitespaces).isEmpty {
                let query = filter.lowercased()
                if !item.name.lowercased().contains(query) && !item.fileExtension.contains(query) {
                    continue
                }
            }
            
            items.append(item)
        }
        
        return sortItems(items, by: sortField, ascending: sortAscending)
    }
    
    public func sortItems(_ items: [FileItem], by field: FileSortField, ascending: Bool) -> [FileItem] {
        return items.sorted { lhs, rhs in
            // Always sort folders before files
            if lhs.isDirectory != rhs.isDirectory {
                return lhs.isDirectory
            }
            
            let comparison: Bool
            switch field {
            case .name:
                comparison = lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            case .size:
                comparison = lhs.size < rhs.size
            case .kind:
                comparison = lhs.kind.localizedStandardCompare(rhs.kind) == .orderedAscending
            case .dateModified:
                let lDate = lhs.modificationDate ?? Date.distantPast
                let rDate = rhs.modificationDate ?? Date.distantPast
                comparison = lDate < rDate
            case .permissions:
                comparison = (lhs.posixPermissions ?? 0) < (rhs.posixPermissions ?? 0)
            }
            return ascending ? comparison : !comparison
        }
    }
    
    // MARK: - File Operations
    
    @discardableResult
    public func createFolder(at parentURL: URL, name: String) throws -> URL {
        var folderName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if folderName.isEmpty {
            folderName = "New Folder"
        }
        var targetURL = parentURL.appendingPathComponent(folderName, isDirectory: true)
        var counter = 1
        while fileManager.fileExists(atPath: targetURL.path) {
            targetURL = parentURL.appendingPathComponent("\(folderName) \(counter)", isDirectory: true)
            counter += 1
        }
        try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: true, attributes: nil)
        return targetURL
    }
    
    @discardableResult
    public func createTextFile(at parentURL: URL, name: String, content: String = "") throws -> URL {
        var fileName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if fileName.isEmpty {
            fileName = "New File.txt"
        }
        var targetURL = parentURL.appendingPathComponent(fileName)
        var counter = 1
        let nameWithoutExt = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        
        while fileManager.fileExists(atPath: targetURL.path) {
            let nextName = ext.isEmpty ? "\(nameWithoutExt) \(counter)" : "\(nameWithoutExt) \(counter).\(ext)"
            targetURL = parentURL.appendingPathComponent(nextName)
            counter += 1
        }
        
        guard let data = content.data(using: .utf8) else {
            throw NSError(domain: "FileSystemService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode string content"])
        }
        try data.write(to: targetURL)
        return targetURL
    }
    
    public func copyItem(at sourceURL: URL, to destinationURL: URL, overwrite: Bool = false) throws {
        if overwrite && fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }
    
    public func copyItems(sources: [URL], destinationDirectory: URL, overwrite: Bool = false) throws {
        for source in sources {
            let dest = destinationDirectory.appendingPathComponent(source.lastPathComponent)
            try copyItem(at: source, to: dest, overwrite: overwrite)
        }
    }
    
    public func moveItem(at sourceURL: URL, to destinationURL: URL, overwrite: Bool = false) throws {
        if overwrite && fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: sourceURL, to: destinationURL)
    }
    
    public func moveItems(sources: [URL], destinationDirectory: URL, overwrite: Bool = false) throws {
        for source in sources {
            let dest = destinationDirectory.appendingPathComponent(source.lastPathComponent)
            try moveItem(at: source, to: dest, overwrite: overwrite)
        }
    }
    
    public func trashItem(at url: URL) throws {
        var resultingURL: NSURL?
        try fileManager.trashItem(at: url, resultingItemURL: &resultingURL)
    }
    
    public func trashItems(urls: [URL]) throws {
        for url in urls {
            try trashItem(at: url)
        }
    }
    
    public func deleteItemPermanently(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }
    
    public func deleteItemsPermanently(urls: [URL]) throws {
        for url in urls {
            try deleteItemPermanently(at: url)
        }
    }
    
    @discardableResult
    public func duplicateItem(at url: URL) throws -> URL {
        let parent = url.deletingLastPathComponent()
        let name = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        
        var counter = 1
        var destURL: URL
        repeat {
            let copySuffix = counter == 1 ? " copy" : " copy \(counter)"
            let newName = ext.isEmpty ? "\(name)\(copySuffix)" : "\(name)\(copySuffix).\(ext)"
            destURL = parent.appendingPathComponent(newName)
            counter += 1
        } while fileManager.fileExists(atPath: destURL.path)
        
        try fileManager.copyItem(at: url, to: destURL)
        return destURL
    }
    
    @discardableResult
    public func renameItem(at url: URL, newName: String) throws -> URL {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "FileSystemService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Name cannot be empty"])
        }
        let destinationURL = url.deletingLastPathComponent().appendingPathComponent(trimmed)
        if url.path == destinationURL.path {
            return url
        }
        try fileManager.moveItem(at: url, to: destinationURL)
        return destinationURL
    }
    
    // MARK: - Volumes & Disk Space
    
    public func listVolumes() -> [VolumeItem] {
        var results: [VolumeItem] = []
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeIsRemovableKey,
            .volumeIsRootFileSystemKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ]
        
        if let urls = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: []) {
            for url in urls {
                guard let res = try? url.resourceValues(forKeys: Set(keys)) else { continue }
                let name = res.volumeName ?? url.lastPathComponent
                let total = Int64(res.volumeTotalCapacity ?? 0)
                let free = Int64(res.volumeAvailableCapacityForImportantUsage ?? 0)
                let isRemovable = res.volumeIsRemovable ?? false
                let isRoot = res.volumeIsRootFileSystem ?? false
                
                results.append(VolumeItem(
                    id: url.path,
                    name: name,
                    url: url,
                    totalSpace: total,
                    freeSpace: free,
                    isRemovable: isRemovable,
                    isRoot: isRoot
                ))
            }
        }
        
        return results
    }
    
    public func getDiskSpace(for url: URL) -> (total: Int64, free: Int64, formattedFree: String, formattedTotal: String) {
        let keys: Set<URLResourceKey> = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ]
        var total: Int64 = 0
        var free: Int64 = 0
        
        if let res = try? url.resourceValues(forKeys: keys) {
            total = Int64(res.volumeTotalCapacity ?? 0)
            free = Int64(res.volumeAvailableCapacityForImportantUsage ?? 0)
        }
        
        return (
            total: total,
            free: free,
            formattedFree: ByteCountFormatter.string(fromByteCount: free, countStyle: .file),
            formattedTotal: ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
        )
    }
    
    // MARK: - Shell & Workspace Integrations
    
    public func revealInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    public func openTerminal(at url: URL) {
        let targetPath = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true ? url.path : url.deletingLastPathComponent().path
        let escapedPath = targetPath.replacingOccurrences(of: "'", with: "'\\''")
        let script = "tell application \"Terminal\" to do script \"cd '\(escapedPath)'\""
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
        }
    }
    
    public func openWithDefaultApp(url: URL) {
        NSWorkspace.shared.open(url)
    }
    
    public func getDirectorySize(url: URL, completion: @escaping @Sendable (Int64, Int) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var totalSize: Int64 = 0
            var count = 0
            let fm = FileManager.default
            let enumerator = fm.enumerator(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey, .totalFileSizeKey, .isDirectoryKey],
                options: [.skipsPackageDescendants]
            )
            
            while let fileURL = enumerator?.nextObject() as? URL {
                count += 1
                if let res = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .totalFileSizeKey, .isDirectoryKey]),
                   res.isDirectory != true {
                    totalSize += Int64(res.totalFileSize ?? res.fileSize ?? 0)
                }
            }
            
            completion(totalSize, count)
        }
    }
}
