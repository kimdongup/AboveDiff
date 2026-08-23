import Foundation

public enum SyncStatus: String, CaseIterable, Identifiable, Sendable {
    case missingInTarget = "Missing in Target"
    case missingInSource = "Missing in Source"
    case newerInSource = "Newer in Source"
    case newerInTarget = "Newer in Target"
    case differentSize = "Different Size"
    case equal = "Equal"
    
    public var id: String { rawValue }
}

public enum SyncAction: String, CaseIterable, Identifiable, Sendable {
    case copyToTarget = "Copy to Target"
    case copyToSource = "Copy to Source"
    case deleteFromTarget = "Delete from Target"
    case deleteFromSource = "Delete from Source"
    case skip = "Skip"
    
    public var id: String { rawValue }
}

public enum SyncDirection: String, CaseIterable, Identifiable, Sendable {
    case sourceToTargetUpdate = "Source -> Target (Update)"
    case sourceToTargetMirror = "Source -> Target (Mirror)"
    case targetToSource = "Target -> Source"
    case bidirectional = "Two-Way Bidirectional"
    
    public var id: String { rawValue }
}

public struct SyncItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let relativePath: String
    public let sourceURL: URL?
    public let targetURL: URL?
    public let isDirectory: Bool
    public var status: SyncStatus
    public var action: SyncAction
    public var isSelected: Bool
    public let sourceSize: Int64?
    public let targetSize: Int64?
    public let sourceDate: Date?
    public let targetDate: Date?
    
    public init(
        relativePath: String,
        sourceURL: URL?,
        targetURL: URL?,
        isDirectory: Bool,
        status: SyncStatus,
        action: SyncAction,
        isSelected: Bool = true,
        sourceSize: Int64? = nil,
        targetSize: Int64? = nil,
        sourceDate: Date? = nil,
        targetDate: Date? = nil
    ) {
        self.id = relativePath
        self.relativePath = relativePath
        self.sourceURL = sourceURL
        self.targetURL = targetURL
        self.isDirectory = isDirectory
        self.status = status
        self.action = action
        self.isSelected = isSelected
        self.sourceSize = sourceSize
        self.targetSize = targetSize
        self.sourceDate = sourceDate
        self.targetDate = targetDate
    }
}

public final class DirectorySyncEngine: @unchecked Sendable {
    public static let shared = DirectorySyncEngine()
    
    private init() {}
    
    // MARK: - Compare Directories
    
    public func compareDirectories(
        source: URL,
        target: URL,
        direction: SyncDirection = .sourceToTargetUpdate,
        recursive: Bool = true,
        compareChecksum: Bool = false,
        progress: (@Sendable (Double, String) -> Void)? = nil
    ) throws -> [SyncItem] {
        let fm = FileManager.default
        var sourceEntries: [String: (url: URL, isDir: Bool, size: Int64, date: Date?)] = [:]
        var targetEntries: [String: (url: URL, isDir: Bool, size: Int64, date: Date?)] = [:]
        
        func scan(root: URL, storage: inout [String: (url: URL, isDir: Bool, size: Int64, date: Date?)]) {
            let options: FileManager.DirectoryEnumerationOptions = recursive ? [.skipsHiddenFiles] : [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            guard let enumerator = fm.enumerator(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: options
            ) else { return }
            
            let rootPath = root.standardizedFileURL.path
            for case let fileURL as URL in enumerator {
                let filePath = fileURL.standardizedFileURL.path
                guard filePath.hasPrefix(rootPath) else { continue }
                var rel = String(filePath.dropFirst(rootPath.count))
                if rel.hasPrefix("/") { rel = String(rel.dropFirst()) }
                if rel.isEmpty { continue }
                
                let res = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                let isDir = res?.isDirectory ?? false
                let size = Int64(res?.fileSize ?? 0)
                let date = res?.contentModificationDate
                storage[rel] = (url: fileURL, isDir: isDir, size: size, date: date)
            }
        }
        
        progress?(0.1, "Scanning source folder...")
        scan(root: source, storage: &sourceEntries)
        progress?(0.4, "Scanning target folder...")
        scan(root: target, storage: &targetEntries)
        
        let allRelPaths = Set(sourceEntries.keys).union(targetEntries.keys).sorted()
        var items: [SyncItem] = []
        
        let count = Double(allRelPaths.count)
        for (i, rel) in allRelPaths.enumerated() {
            let src = sourceEntries[rel]
            let tgt = targetEntries[rel]
            
            let isDir = (src?.isDir ?? false) || (tgt?.isDir ?? false)
            let srcURL = src?.url ?? source.appendingPathComponent(rel)
            let tgtURL = tgt?.url ?? target.appendingPathComponent(rel)
            
            var status: SyncStatus
            var action: SyncAction
            
            if src != nil && tgt == nil {
                status = .missingInTarget
                switch direction {
                case .sourceToTargetUpdate, .sourceToTargetMirror, .bidirectional:
                    action = .copyToTarget
                case .targetToSource:
                    action = .skip
                }
            } else if src == nil && tgt != nil {
                status = .missingInSource
                switch direction {
                case .sourceToTargetMirror:
                    action = .deleteFromTarget
                case .bidirectional, .targetToSource:
                    action = .copyToSource
                case .sourceToTargetUpdate:
                    action = .skip
                }
            } else if let s = src, let t = tgt {
                if isDir {
                    status = .equal
                    action = .skip
                } else {
                    let sDate = s.date ?? Date.distantPast
                    let tDate = t.date ?? Date.distantPast
                    let dateDiff = sDate.timeIntervalSince(tDate)
                    
                    if abs(dateDiff) < 2.0 && s.size == t.size {
                        status = .equal
                        action = .skip
                    } else if sDate > tDate {
                        status = .newerInSource
                        switch direction {
                        case .sourceToTargetUpdate, .sourceToTargetMirror, .bidirectional:
                            action = .copyToTarget
                        case .targetToSource:
                            action = .copyToSource
                        }
                    } else if tDate > sDate {
                        status = .newerInTarget
                        switch direction {
                        case .targetToSource, .bidirectional:
                            action = .copyToSource
                        case .sourceToTargetUpdate, .sourceToTargetMirror:
                            action = .copyToTarget
                        }
                    } else {
                        status = .differentSize
                        action = .copyToTarget
                    }
                }
            } else {
                status = .equal
                action = .skip
            }
            
            let item = SyncItem(
                relativePath: rel,
                sourceURL: src != nil ? srcURL : nil,
                targetURL: tgt != nil ? tgtURL : nil,
                isDirectory: isDir,
                status: status,
                action: action,
                isSelected: action != .skip,
                sourceSize: src?.size,
                targetSize: tgt?.size,
                sourceDate: src?.date,
                targetDate: tgt?.date
            )
            items.append(item)
            
            if count > 0 && i % 50 == 0 {
                progress?(0.5 + 0.5 * (Double(i) / count), "Comparing items...")
            }
        }
        
        progress?(1.0, "Comparison complete")
        return items
    }
    
    // MARK: - Execute Sync
    
    public func executeSync(
        items: [SyncItem],
        sourceBase: URL,
        targetBase: URL,
        progress: (@Sendable (Int, Int, String) -> Void)? = nil
    ) throws {
        let fm = FileManager.default
        let activeItems = items.filter { $0.isSelected && $0.action != .skip }
        let total = activeItems.count
        
        for (index, item) in activeItems.enumerated() {
            let rel = item.relativePath
            let sURL = sourceBase.appendingPathComponent(rel)
            let tURL = targetBase.appendingPathComponent(rel)
            
            progress?(index + 1, total, "\(item.action.rawValue): \(rel)")
            
            switch item.action {
            case .copyToTarget:
                let targetParent = tURL.deletingLastPathComponent()
                if !fm.fileExists(atPath: targetParent.path) {
                    try fm.createDirectory(at: targetParent, withIntermediateDirectories: true)
                }
                if fm.fileExists(atPath: tURL.path) {
                    try fm.removeItem(at: tURL)
                }
                try fm.copyItem(at: sURL, to: tURL)
                
            case .copyToSource:
                let sourceParent = sURL.deletingLastPathComponent()
                if !fm.fileExists(atPath: sourceParent.path) {
                    try fm.createDirectory(at: sourceParent, withIntermediateDirectories: true)
                }
                if fm.fileExists(atPath: sURL.path) {
                    try fm.removeItem(at: sURL)
                }
                try fm.copyItem(at: tURL, to: sURL)
                
            case .deleteFromTarget:
                if fm.fileExists(atPath: tURL.path) {
                    try fm.removeItem(at: tURL)
                }
                
            case .deleteFromSource:
                if fm.fileExists(atPath: sURL.path) {
                    try fm.removeItem(at: sURL)
                }
                
            case .skip:
                break
            }
        }
    }
}
