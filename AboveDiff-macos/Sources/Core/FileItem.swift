import Foundation
import AppKit
import UniformTypeIdentifiers

public enum FileSortField: String, CaseIterable, Identifiable, Codable, Sendable {
    case name
    case size
    case kind
    case dateModified
    case permissions
    
    public var id: String { rawValue }
}

public final class FileIconCache: @unchecked Sendable {
    public static let shared = FileIconCache()
    private let cache = NSCache<NSString, NSImage>()
    
    private init() {
        cache.countLimit = 1500
    }
    
    public func icon(for file: FileItem) -> NSImage {
        let key: String
        if file.isDirectory && !file.isPackage {
            key = "__folder__"
        } else if file.isPackage {
            key = file.path
        } else if !file.fileExtension.isEmpty {
            key = "ext_\(file.fileExtension)"
        } else {
            key = "__generic_file__"
        }
        
        let nsKey = key as NSString
        if let cached = cache.object(forKey: nsKey) {
            return cached
        }
        
        let icon: NSImage
        if file.isDirectory && !file.isPackage {
            icon = NSWorkspace.shared.icon(for: .folder)
        } else if file.isPackage {
            icon = NSWorkspace.shared.icon(forFile: file.path)
        } else if !file.fileExtension.isEmpty, let uttype = UTType(filenameExtension: file.fileExtension) {
            icon = NSWorkspace.shared.icon(for: uttype)
        } else {
            icon = NSWorkspace.shared.icon(forFile: file.path)
        }
        
        cache.setObject(icon, forKey: nsKey)
        return icon
    }
    
    public func clear() {
        cache.removeAllObjects()
    }
}

public struct FileItem: Identifiable, Hashable, Equatable, @unchecked Sendable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let path: String
    public let fileExtension: String
    public let size: Int64
    public let isDirectory: Bool
    public let isPackage: Bool
    public let isSymlink: Bool
    public let isHidden: Bool
    public let isReadable: Bool
    public let isWritable: Bool
    public let isExecutable: Bool
    public let creationDate: Date?
    public let modificationDate: Date?
    public let accessDate: Date?
    public let posixPermissions: Int?
    public let ownerName: String
    public let groupName: String
    public let kind: String
    public let childCount: Int?
    
    // Cached icon
    private let _icon: NSImage?
    
    public var icon: NSImage {
        if let icon = _icon {
            return icon
        }
        return FileIconCache.shared.icon(for: self)
    }
    
    public init(
        id: UUID = UUID(),
        url: URL,
        name: String? = nil,
        size: Int64 = 0,
        isDirectory: Bool = false,
        isPackage: Bool = false,
        isSymlink: Bool = false,
        isHidden: Bool = false,
        isReadable: Bool = true,
        isWritable: Bool = true,
        isExecutable: Bool = false,
        creationDate: Date? = nil,
        modificationDate: Date? = nil,
        accessDate: Date? = nil,
        posixPermissions: Int? = 0o755,
        ownerName: String = "",
        groupName: String = "",
        kind: String = "",
        childCount: Int? = nil,
        icon: NSImage? = nil
    ) {
        self.id = id
        self.url = url
        self.name = name ?? url.lastPathComponent
        self.path = url.path
        self.fileExtension = url.pathExtension.lowercased()
        self.size = size
        self.isDirectory = isDirectory
        self.isPackage = isPackage
        self.isSymlink = isSymlink
        self.isHidden = isHidden
        self.isReadable = isReadable
        self.isWritable = isWritable
        self.isExecutable = isExecutable
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.accessDate = accessDate
        self.posixPermissions = posixPermissions
        self.ownerName = ownerName
        self.groupName = groupName
        self.kind = kind
        self.childCount = childCount
        self._icon = icon
    }
    
    public init(url: URL, resourceValues: URLResourceValues? = nil) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        self.path = url.path
        self.fileExtension = url.pathExtension.lowercased()
        
        if let res = resourceValues {
            let isDir = res.isDirectory ?? false
            let isPkg = res.isPackage ?? false
            let isSym = res.isSymbolicLink ?? false
            var isHid = url.lastPathComponent.hasPrefix(".")
            if let h = res.isHidden { isHid = isHid || h }
            let readable = res.isReadable ?? true
            let writable = res.isWritable ?? true
            let executable = res.isExecutable ?? false
            var itemSize: Int64 = 0
            if let sz = res.fileSize ?? res.totalFileSize {
                itemSize = Int64(sz)
            }
            let cDate = res.creationDate
            let mDate = res.contentModificationDate
            let aDate = res.contentAccessDate
            var kindStr = res.localizedTypeDescription ?? ""
            
            if kindStr.isEmpty {
                if isDir && !isPkg {
                    kindStr = "Folder"
                } else if let uttype = UTType(filenameExtension: url.pathExtension) {
                    kindStr = uttype.localizedDescription ?? uttype.description
                } else {
                    kindStr = url.pathExtension.isEmpty ? "Document" : url.pathExtension.uppercased() + " File"
                }
            }
            
            self.isDirectory = isDir
            self.isPackage = isPkg
            self.isSymlink = isSym
            self.isHidden = isHid
            self.isReadable = readable
            self.isWritable = writable
            self.isExecutable = executable
            self.size = itemSize
            self.creationDate = cDate
            self.modificationDate = mDate
            self.accessDate = aDate
            self.posixPermissions = 0o755
            self.ownerName = ""
            self.groupName = ""
            self.kind = kindStr
            self.childCount = nil
            self._icon = nil
        } else {
            let fm = FileManager.default
            var isDir: ObjCBool = false
            let exists = fm.fileExists(atPath: url.path, isDirectory: &isDir)
            
            var isPkg = false
            var isSym = false
            var isHid = url.lastPathComponent.hasPrefix(".")
            var readable = true
            var writable = true
            var executable = false
            var itemSize: Int64 = 0
            var cDate: Date? = nil
            var mDate: Date? = nil
            var aDate: Date? = nil
            var posix: Int? = nil
            var owner = ""
            var group = ""
            var kindStr = ""
            let count: Int? = nil
            
            if exists {
                let resKeys: Set<URLResourceKey> = [
                    .isDirectoryKey,
                    .isPackageKey,
                    .isSymbolicLinkKey,
                    .isHiddenKey,
                    .fileSizeKey,
                    .totalFileSizeKey,
                    .creationDateKey,
                    .contentModificationDateKey,
                    .contentAccessDateKey,
                    .localizedTypeDescriptionKey,
                    .isReadableKey,
                    .isWritableKey,
                    .isExecutableKey
                ]
                
                if let res = try? url.resourceValues(forKeys: resKeys) {
                    isDir = ObjCBool(res.isDirectory ?? isDir.boolValue)
                    isPkg = res.isPackage ?? false
                    isSym = res.isSymbolicLink ?? false
                    if let h = res.isHidden { isHid = isHid || h }
                    readable = res.isReadable ?? true
                    writable = res.isWritable ?? true
                    executable = res.isExecutable ?? false
                    cDate = res.creationDate
                    mDate = res.contentModificationDate
                    aDate = res.contentAccessDate
                    kindStr = res.localizedTypeDescription ?? ""
                    if let sz = res.fileSize ?? res.totalFileSize {
                        itemSize = Int64(sz)
                    }
                }
                
                if let attrs = try? fm.attributesOfItem(atPath: url.path) {
                    if itemSize == 0, let sz = attrs[.size] as? NSNumber {
                        itemSize = sz.int64Value
                    }
                    if cDate == nil { cDate = attrs[.creationDate] as? Date }
                    if mDate == nil { mDate = attrs[.modificationDate] as? Date }
                    if let p = attrs[.posixPermissions] as? NSNumber {
                        posix = p.intValue
                    }
                    if let o = attrs[.ownerAccountName] as? String { owner = o }
                    if let g = attrs[.groupOwnerAccountName] as? String { group = g }
                }
            }
            
            self.isDirectory = isDir.boolValue
            self.isPackage = isPkg
            self.isSymlink = isSym
            self.isHidden = isHid
            self.isReadable = readable
            self.isWritable = writable
            self.isExecutable = executable
            self.size = itemSize
            self.creationDate = cDate
            self.modificationDate = mDate
            self.accessDate = aDate
            self.posixPermissions = posix
            self.ownerName = owner
            self.groupName = group
            
            if kindStr.isEmpty {
                if isDir.boolValue && !isPkg {
                    kindStr = "Folder"
                } else if let uttype = UTType(filenameExtension: url.pathExtension) {
                    kindStr = uttype.localizedDescription ?? uttype.description
                } else {
                    kindStr = url.pathExtension.isEmpty ? "Document" : url.pathExtension.uppercased() + " File"
                }
            }
            self.kind = kindStr
            self.childCount = count
            self._icon = nil
        }
    }
    
    public var formattedSize: String {
        if isDirectory && !isPackage {
            if let count = childCount {
                return "\(count) items"
            }
            return "--"
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    public var formattedDate: String {
        guard let date = modificationDate else { return "--" }
        return FileItem.dateFormatter.string(from: date)
    }
    
    public var formattedCreationDate: String {
        guard let date = creationDate else { return "--" }
        return FileItem.dateFormatter.string(from: date)
    }
    
    public var formattedAccessDate: String {
        guard let date = accessDate else { return "--" }
        return FileItem.dateFormatter.string(from: date)
    }
    
    public var permissionsString: String {
        guard let perm = posixPermissions else { return "---------" }
        return FileItem.formatPosixPermissions(perm)
    }
    
    public var octalPermissionsString: String {
        guard let perm = posixPermissions else { return "0000" }
        return String(format: "%04o", perm)
    }
    
    public static func formatPosixPermissions(_ permissions: Int) -> String {
        var str = ""
        let masks: [Int] = [
            0o400, 0o200, 0o100, // User: r, w, x
            0o040, 0o020, 0o010, // Group: r, w, x
            0o004, 0o002, 0o001  // Others: r, w, x
        ]
        let chars: [Character] = ["r", "w", "x", "r", "w", "x", "r", "w", "x"]
        for i in 0..<9 {
            if (permissions & masks[i]) != 0 {
                str.append(chars[i])
            } else {
                str.append("-")
            }
        }
        return str
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(url)
    }
    
    public static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        return lhs.id == rhs.id && lhs.url == rhs.url
    }
}
