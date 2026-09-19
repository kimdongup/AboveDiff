import Foundation

public enum SearchFileTypeFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "All Files & Folders"
    case foldersOnly = "Folders Only"
    case filesOnly = "Files Only"
    case code = "Code Files"
    case documents = "Documents"
    case images = "Images"
    case media = "Audio & Video"
    case archives = "Archives"
    
    public var id: String { rawValue }
    
    public func matches(file: FileItem) -> Bool {
        switch self {
        case .all:
            return true
        case .foldersOnly:
            return file.isDirectory && !file.isPackage
        case .filesOnly:
            return !file.isDirectory || file.isPackage
        case .code:
            let exts = ["swift", "c", "cpp", "h", "hpp", "m", "mm", "py", "js", "ts", "json", "xml", "html", "css", "sh", "rs", "go", "java", "kt"]
            return exts.contains(file.fileExtension)
        case .documents:
            let exts = ["pdf", "doc", "docx", "txt", "rtf", "md", "pages", "xls", "xlsx", "csv", "ppt", "pptx", "key"]
            return exts.contains(file.fileExtension)
        case .images:
            let exts = ["png", "jpg", "jpeg", "gif", "heic", "tiff", "bmp", "svg", "webp", "icns", "ico"]
            return exts.contains(file.fileExtension)
        case .media:
            let exts = ["mp3", "m4a", "wav", "flac", "aac", "mp4", "mov", "mkv", "avi", "webm", "m4v"]
            return exts.contains(file.fileExtension)
        case .archives:
            let exts = ["zip", "tar", "gz", "bz2", "xz", "7z", "rar", "dmg", "iso"]
            return exts.contains(file.fileExtension)
        }
    }
}

public struct SearchCriteria: Sendable {
    public var rootURL: URL
    public var nameQuery: String
    public var useRegex: Bool
    public var caseSensitiveName: Bool
    public var contentQuery: String
    public var caseSensitiveContent: Bool
    public var minSize: Int64?
    public var maxSize: Int64?
    public var modifiedAfter: Date?
    public var modifiedBefore: Date?
    public var typeFilter: SearchFileTypeFilter
    public var includeHidden: Bool
    public var recursive: Bool
    
    public init(
        rootURL: URL,
        nameQuery: String = "",
        useRegex: Bool = false,
        caseSensitiveName: Bool = false,
        contentQuery: String = "",
        caseSensitiveContent: Bool = false,
        minSize: Int64? = nil,
        maxSize: Int64? = nil,
        modifiedAfter: Date? = nil,
        modifiedBefore: Date? = nil,
        typeFilter: SearchFileTypeFilter = .all,
        includeHidden: Bool = false,
        recursive: Bool = true
    ) {
        self.rootURL = rootURL
        self.nameQuery = nameQuery
        self.useRegex = useRegex
        self.caseSensitiveName = caseSensitiveName
        self.contentQuery = contentQuery
        self.caseSensitiveContent = caseSensitiveContent
        self.minSize = minSize
        self.maxSize = maxSize
        self.modifiedAfter = modifiedAfter
        self.modifiedBefore = modifiedBefore
        self.typeFilter = typeFilter
        self.includeHidden = includeHidden
        self.recursive = recursive
    }
}

public struct SearchResultItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let fileItem: FileItem
    public let matchSnippet: String?
    public let matchLineNumber: Int?
    
    public init(
        id: UUID = UUID(),
        fileItem: FileItem,
        matchSnippet: String? = nil,
        matchLineNumber: Int? = nil
    ) {
        self.id = id
        self.fileItem = fileItem
        self.matchSnippet = matchSnippet
        self.matchLineNumber = matchLineNumber
    }
}

public final class FileSearchEngine: @unchecked Sendable {
    public static let shared = FileSearchEngine()
    
    private init() {}
    
    public func search(
        criteria: SearchCriteria,
        onResult: @escaping @Sendable (SearchResultItem) -> Void,
        shouldCancel: @escaping @Sendable () -> Bool
    ) {
        let fm = FileManager.default
        let options: FileManager.DirectoryEnumerationOptions = criteria.includeHidden ? [] : [.skipsHiddenFiles]
        
        guard let enumerator = fm.enumerator(
            at: criteria.rootURL,
            includingPropertiesForKeys: [
                .nameKey,
                .isDirectoryKey,
                .isPackageKey,
                .fileSizeKey,
                .contentModificationDateKey
            ],
            options: options
        ) else { return }
        
        var regex: NSRegularExpression? = nil
        if !criteria.nameQuery.isEmpty {
            if criteria.useRegex {
                let options: NSRegularExpression.Options = criteria.caseSensitiveName ? [] : [.caseInsensitive]
                regex = try? NSRegularExpression(pattern: criteria.nameQuery, options: options)
            } else {
                // Convert wildcard glob (*, ?) to regex
                var pattern = "^"
                for char in criteria.nameQuery {
                    switch char {
                    case "*": pattern += ".*"
                    case "?": pattern += "."
                    case ".", "(", ")", "[", "]", "{", "}", "^", "$", "+", "|", "\\":
                        pattern += "\\\(char)"
                    default:
                        pattern.append(char)
                    }
                }
                pattern += "$"
                let options: NSRegularExpression.Options = criteria.caseSensitiveName ? [] : [.caseInsensitive]
                regex = try? NSRegularExpression(pattern: pattern, options: options)
            }
        }
        
        for case let url as URL in enumerator {
            if shouldCancel() { break }
            
            if !criteria.recursive {
                if url.deletingLastPathComponent().standardizedFileURL.path != criteria.rootURL.standardizedFileURL.path {
                    enumerator.skipDescendants()
                    continue
                }
            }
            
            let item = FileItem(url: url)
            
            // Hidden check
            if !criteria.includeHidden && item.isHidden {
                continue
            }
            
            // Type filter
            if !criteria.typeFilter.matches(file: item) {
                continue
            }
            
            // Name match
            if let regex = regex {
                let range = NSRange(item.name.startIndex..<item.name.endIndex, in: item.name)
                if regex.firstMatch(in: item.name, range: range) == nil {
                    continue
                }
            }
            
            // Size filter
            if !item.isDirectory || item.isPackage {
                if let min = criteria.minSize, item.size < min {
                    continue
                }
                if let max = criteria.maxSize, item.size > max {
                    continue
                }
            }
            
            // Date filter
            if let after = criteria.modifiedAfter, let mDate = item.modificationDate, mDate < after {
                continue
            }
            if let before = criteria.modifiedBefore, let mDate = item.modificationDate, mDate > before {
                continue
            }
            
            // Content search
            var contentSnippet: String? = nil
            var lineNumber: Int? = nil
            
            if !criteria.contentQuery.isEmpty {
                if item.isDirectory && !item.isPackage {
                    continue
                }
                if item.size > 20 * 1024 * 1024 { // Skip files > 20MB for content search
                    continue
                }
                
                let stringContent: String? = (try? String(contentsOf: url, encoding: .utf8)) ?? (try? String(contentsOf: url, encoding: .ascii))
                guard let content = stringContent else {
                    continue
                }
                
                let lines = content.components(separatedBy: .newlines)
                var matched = false
                let query = criteria.caseSensitiveContent ? criteria.contentQuery : criteria.contentQuery.lowercased()
                
                for (idx, line) in lines.enumerated() {
                    let target = criteria.caseSensitiveContent ? line : line.lowercased()
                    if target.contains(query) {
                        matched = true
                        lineNumber = idx + 1
                        contentSnippet = line.trimmingCharacters(in: .whitespaces)
                        break
                    }
                }
                
                if !matched {
                    continue
                }
            }
            
            let result = SearchResultItem(
                fileItem: item,
                matchSnippet: contentSnippet,
                matchLineNumber: lineNumber
            )
            onResult(result)
        }
    }
}
