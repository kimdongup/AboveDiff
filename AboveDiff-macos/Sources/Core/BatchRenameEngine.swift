import Foundation

public enum RenameCaseOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case lowercase
    case uppercase
    case titleCase
    case capitalized
    
    public var id: String { rawValue }
}

public enum NumberingPosition: String, CaseIterable, Identifiable, Codable, Sendable {
    case prefix
    case suffix
    case replace
    
    public var id: String { rawValue }
}

public enum BatchRenameRule: Identifiable, Hashable, Codable, Sendable {
    case replaceText(find: String, replaceWith: String, caseSensitive: Bool)
    case replaceRegex(pattern: String, template: String)
    case addPrefix(prefix: String)
    case addSuffix(suffix: String)
    case insertAt(text: String, index: Int)
    case deleteRange(fromStart: Int, count: Int)
    case deleteFromEnd(count: Int)
    case changeCase(option: RenameCaseOption)
    case numbering(position: NumberingPosition, start: Int, step: Int, digits: Int)
    case changeExtension(newExt: String, remove: Bool, lowercase: Bool)
    
    public var id: String {
        switch self {
        case .replaceText(let f, let r, let c): return "replaceText_\(f)_\(r)_\(c)"
        case .replaceRegex(let p, let t): return "replaceRegex_\(p)_\(t)"
        case .addPrefix(let p): return "addPrefix_\(p)"
        case .addSuffix(let s): return "addSuffix_\(s)"
        case .insertAt(let t, let i): return "insertAt_\(t)_\(i)"
        case .deleteRange(let s, let c): return "deleteRange_\(s)_\(c)"
        case .deleteFromEnd(let c): return "deleteFromEnd_\(c)"
        case .changeCase(let o): return "changeCase_\(o.rawValue)"
        case .numbering(let p, let s, let st, let d): return "numbering_\(p)_\(s)_\(st)_\(d)"
        case .changeExtension(let e, let r, let l): return "changeExt_\(e)_\(r)_\(l)"
        }
    }
}

public struct RenamePreviewItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let originalURL: URL
    public let originalName: String
    public let originalExtension: String
    public let newBaseName: String
    public let newExtension: String
    public let hasConflict: Bool
    public let errorMessage: String?
    
    public var originalFullName: String {
        if originalExtension.isEmpty {
            return originalName
        }
        return "\(originalName).\(originalExtension)"
    }
    
    public var fullNewName: String {
        if newExtension.isEmpty {
            return newBaseName
        }
        return "\(newBaseName).\(newExtension)"
    }
    
    public var destinationURL: URL {
        originalURL.deletingLastPathComponent().appendingPathComponent(fullNewName)
    }
    
    public init(
        id: UUID = UUID(),
        originalURL: URL,
        originalName: String,
        originalExtension: String,
        newBaseName: String,
        newExtension: String,
        hasConflict: Bool = false,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.originalURL = originalURL
        self.originalName = originalName
        self.originalExtension = originalExtension
        self.newBaseName = newBaseName
        self.newExtension = newExtension
        self.hasConflict = hasConflict
        self.errorMessage = errorMessage
    }
}

public final class BatchRenameEngine: @unchecked Sendable {
    public static let shared = BatchRenameEngine()
    
    private init() {}
    
    public func generatePreview(
        files: [FileItem],
        rules: [BatchRenameRule]
    ) -> [RenamePreviewItem] {
        var previews: [RenamePreviewItem] = []
        var generatedNames = Set<String>()
        var conflictIndices = Set<Int>()
        
        for (index, file) in files.enumerated() {
            let originalFullName = file.name
            let ext = file.isDirectory && !file.isPackage ? "" : file.url.pathExtension
            let baseName = ext.isEmpty ? originalFullName : (originalFullName as NSString).deletingPathExtension
            
            var currentBase = baseName
            var currentExt = ext
            
            for rule in rules {
                switch rule {
                case .replaceText(let find, let replaceWith, let caseSensitive):
                    if !find.isEmpty {
                        let options: String.CompareOptions = caseSensitive ? [] : [.caseInsensitive]
                        currentBase = currentBase.replacingOccurrences(of: find, with: replaceWith, options: options)
                    }
                    
                case .replaceRegex(let pattern, let template):
                    if !pattern.isEmpty, let regex = try? NSRegularExpression(pattern: pattern) {
                        let range = NSRange(currentBase.startIndex..<currentBase.endIndex, in: currentBase)
                        currentBase = regex.stringByReplacingMatches(in: currentBase, range: range, withTemplate: template)
                    }
                    
                case .addPrefix(let prefix):
                    currentBase = prefix + currentBase
                    
                case .addSuffix(let suffix):
                    currentBase = currentBase + suffix
                    
                case .insertAt(let text, let atIndex):
                    if atIndex <= 0 {
                        currentBase = text + currentBase
                    } else if atIndex >= currentBase.count {
                        currentBase = currentBase + text
                    } else {
                        let strIndex = currentBase.index(currentBase.startIndex, offsetBy: atIndex)
                        currentBase.insert(contentsOf: text, at: strIndex)
                    }
                    
                case .deleteRange(let fromStart, let count):
                    if count > 0 && fromStart < currentBase.count {
                        let start = max(0, fromStart)
                        let length = min(count, currentBase.count - start)
                        let startIndex = currentBase.index(currentBase.startIndex, offsetBy: start)
                        let endIndex = currentBase.index(startIndex, offsetBy: length)
                        currentBase.removeSubrange(startIndex..<endIndex)
                    }
                    
                case .deleteFromEnd(let count):
                    if count > 0 {
                        let delCount = min(count, currentBase.count)
                        let startIndex = currentBase.index(currentBase.endIndex, offsetBy: -delCount)
                        currentBase.removeSubrange(startIndex..<currentBase.endIndex)
                    }
                    
                case .changeCase(let option):
                    switch option {
                    case .lowercase:
                        currentBase = currentBase.lowercased()
                    case .uppercase:
                        currentBase = currentBase.uppercased()
                    case .titleCase:
                        currentBase = currentBase.capitalized
                    case .capitalized:
                        if let first = currentBase.first {
                            currentBase = String(first).uppercased() + currentBase.dropFirst()
                        }
                    }
                    
                case .numbering(let position, let start, let step, let digits):
                    let num = start + (index * step)
                    let numStr = String(format: "%0\(digits)d", num)
                    switch position {
                    case .prefix:
                        currentBase = "\(numStr)\(currentBase)"
                    case .suffix:
                        currentBase = "\(currentBase)\(numStr)"
                    case .replace:
                        currentBase = numStr
                    }
                    
                case .changeExtension(let newExt, let remove, let lowercase):
                    if !file.isDirectory || file.isPackage {
                        if remove {
                            currentExt = ""
                        } else if !newExt.isEmpty {
                            currentExt = newExt.hasPrefix(".") ? String(newExt.dropFirst()) : newExt
                        }
                        if lowercase {
                            currentExt = currentExt.lowercased()
                        }
                    }
                }
            }
            
            let trimmedBase = currentBase.trimmingCharacters(in: .whitespaces)
            let finalBase = trimmedBase.isEmpty ? baseName : trimmedBase
            let finalFullName = currentExt.isEmpty ? finalBase : "\(finalBase).\(currentExt)"
            let parentDir = file.url.deletingLastPathComponent().path
            let fullTargetKey = "\(parentDir)/\(finalFullName)".lowercased()
            
            var isConflict = false
            var errorMsg: String? = nil
            
            if generatedNames.contains(fullTargetKey) {
                isConflict = true
                errorMsg = "Duplicate filename in batch"
                conflictIndices.insert(index)
            } else {
                generatedNames.insert(fullTargetKey)
            }
            
            let targetURL = file.url.deletingLastPathComponent().appendingPathComponent(finalFullName)
            if FileManager.default.fileExists(atPath: targetURL.path) && targetURL.path != file.url.path {
                isConflict = true
                errorMsg = "File already exists on disk"
            }
            
            let preview = RenamePreviewItem(
                originalURL: file.url,
                originalName: baseName,
                originalExtension: ext,
                newBaseName: finalBase,
                newExtension: currentExt,
                hasConflict: isConflict,
                errorMessage: errorMsg
            )
            previews.append(preview)
        }
        
        return previews
    }
    
    public func executeRename(previews: [RenamePreviewItem]) throws -> [URL: URL] {
        let fm = FileManager.default
        var resultMap: [URL: URL] = [:]
        
        // Pass 1: Rename to temporary names if case-only change or swap collision
        var tempRenames: [(tempURL: URL, finalURL: URL)] = []
        
        for item in previews {
            let dest = item.destinationURL
            if item.originalURL.path == dest.path {
                continue
            }
            
            // Check if destination matches case-insensitively on same file
            let isSameFileCaseChange = item.originalURL.path.caseInsensitiveCompare(dest.path) == .orderedSame
            
            if isSameFileCaseChange {
                let tempName = ".abovediff_rename_tmp_\(UUID().uuidString)"
                let tempURL = item.originalURL.deletingLastPathComponent().appendingPathComponent(tempName)
                try fm.moveItem(at: item.originalURL, to: tempURL)
                tempRenames.append((tempURL: tempURL, finalURL: dest))
            } else {
                try fm.moveItem(at: item.originalURL, to: dest)
                resultMap[item.originalURL] = dest
            }
        }
        
        // Pass 2: Finalize temp renames
        for temp in tempRenames {
            try fm.moveItem(at: temp.tempURL, to: temp.finalURL)
            // find original URL
            if let orig = previews.first(where: { $0.destinationURL.path == temp.finalURL.path })?.originalURL {
                resultMap[orig] = temp.finalURL
            }
        }
        
        return resultMap
    }
}
