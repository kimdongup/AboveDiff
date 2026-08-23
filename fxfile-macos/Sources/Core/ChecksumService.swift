import Foundation
import CryptoKit
import CommonCrypto

public enum ChecksumAlgorithm: String, CaseIterable, Identifiable, Codable, Sendable {
    case crc32 = "CRC32"
    case md5 = "MD5"
    case sha1 = "SHA-1"
    case sha256 = "SHA-256"
    case sha512 = "SHA-512"
    
    public var id: String { rawValue }
    
    public var defaultExtension: String {
        switch self {
        case .crc32: return "sfv"
        case .md5: return "md5"
        case .sha1: return "sha1"
        case .sha256: return "sha256"
        case .sha512: return "sha512"
        }
    }
}

public struct ChecksumResult: Hashable, Sendable {
    public let algorithm: ChecksumAlgorithm
    public let hash: String
    public let fileURL: URL
    public let fileSize: Int64
    
    public init(algorithm: ChecksumAlgorithm, hash: String, fileURL: URL, fileSize: Int64) {
        self.algorithm = algorithm
        self.hash = hash
        self.fileURL = fileURL
        self.fileSize = fileSize
    }
}

public final class ChecksumService: @unchecked Sendable {
    public static let shared = ChecksumService()
    
    private init() {}
    
    // MARK: - CRC32 Implementation (IEEE 802.3)
    
    private static let crc32Table: [UInt32] = {
        (0..<256).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 {
                if (c & 1) != 0 {
                    c = 0xEDB88320 ^ (c >> 1)
                } else {
                    c = c >> 1
                }
            }
            return c
        }
    }()
    
    public func calculateCRC32(data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        data.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.bindMemory(to: UInt8.self).baseAddress else { return }
            for i in 0..<data.count {
                let byte = baseAddress[i]
                let tableIndex = Int((crc ^ UInt32(byte)) & 0xFF)
                crc = ChecksumService.crc32Table[tableIndex] ^ (crc >> 8)
            }
        }
        return crc ^ 0xFFFFFFFF
    }
    
    // MARK: - File Hashing with Streaming
    
    public func calculateChecksum(
        for url: URL,
        algorithm: ChecksumAlgorithm,
        progress: (@Sendable (Double) -> Void)? = nil
    ) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        
        let fileSize: Int64 = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize.map { Int64($0) }) ?? 0
        let bufferSize = 1024 * 1024 // 1 MB buffer
        var bytesRead: Int64 = 0
        
        switch algorithm {
        case .crc32:
            var crc: UInt32 = 0xFFFFFFFF
            while autoreleasepool(invoking: {
                let data = handle.readData(ofLength: bufferSize)
                if data.isEmpty { return false }
                
                data.withUnsafeBytes { rawBuffer in
                    guard let baseAddress = rawBuffer.bindMemory(to: UInt8.self).baseAddress else { return }
                    for i in 0..<data.count {
                        let byte = baseAddress[i]
                        let tableIndex = Int((crc ^ UInt32(byte)) & 0xFF)
                        crc = ChecksumService.crc32Table[tableIndex] ^ (crc >> 8)
                    }
                }
                
                bytesRead += Int64(data.count)
                if fileSize > 0 {
                    progress?(min(Double(bytesRead) / Double(fileSize), 1.0))
                }
                return true
            }) {}
            let finalCRC = crc ^ 0xFFFFFFFF
            return String(format: "%08X", finalCRC)
            
        case .md5:
            var hasher = Insecure.MD5()
            while autoreleasepool(invoking: {
                let data = handle.readData(ofLength: bufferSize)
                if data.isEmpty { return false }
                hasher.update(data: data)
                bytesRead += Int64(data.count)
                if fileSize > 0 {
                    progress?(min(Double(bytesRead) / Double(fileSize), 1.0))
                }
                return true
            }) {}
            let digest = hasher.finalize()
            return digest.map { String(format: "%02x", $0) }.joined()
            
        case .sha1:
            var hasher = Insecure.SHA1()
            while autoreleasepool(invoking: {
                let data = handle.readData(ofLength: bufferSize)
                if data.isEmpty { return false }
                hasher.update(data: data)
                bytesRead += Int64(data.count)
                if fileSize > 0 {
                    progress?(min(Double(bytesRead) / Double(fileSize), 1.0))
                }
                return true
            }) {}
            let digest = hasher.finalize()
            return digest.map { String(format: "%02x", $0) }.joined()
            
        case .sha256:
            var hasher = SHA256()
            while autoreleasepool(invoking: {
                let data = handle.readData(ofLength: bufferSize)
                if data.isEmpty { return false }
                hasher.update(data: data)
                bytesRead += Int64(data.count)
                if fileSize > 0 {
                    progress?(min(Double(bytesRead) / Double(fileSize), 1.0))
                }
                return true
            }) {}
            let digest = hasher.finalize()
            return digest.compactMap { String(format: "%02x", $0) }.joined()
            
        case .sha512:
            var hasher = SHA512()
            while autoreleasepool(invoking: {
                let data = handle.readData(ofLength: bufferSize)
                if data.isEmpty { return false }
                hasher.update(data: data)
                bytesRead += Int64(data.count)
                if fileSize > 0 {
                    progress?(min(Double(bytesRead) / Double(fileSize), 1.0))
                }
                return true
            }) {}
            let digest = hasher.finalize()
            return digest.compactMap { String(format: "%02x", $0) }.joined()
        }
    }
    
    public func calculateChecksum(data: Data, algorithm: ChecksumAlgorithm) -> String {
        switch algorithm {
        case .crc32:
            let crc = calculateCRC32(data: data)
            return String(format: "%08X", crc)
        case .md5:
            let digest = Insecure.MD5.hash(data: data)
            return digest.map { String(format: "%02x", $0) }.joined()
        case .sha1:
            let digest = Insecure.SHA1.hash(data: data)
            return digest.map { String(format: "%02x", $0) }.joined()
        case .sha256:
            let digest = SHA256.hash(data: data)
            return digest.compactMap { String(format: "%02x", $0) }.joined()
        case .sha512:
            let digest = SHA512.hash(data: data)
            return digest.compactMap { String(format: "%02x", $0) }.joined()
        }
    }
    
    public func verifyChecksum(fileURL: URL, expectedHash: String, algorithm: ChecksumAlgorithm) throws -> Bool {
        let computed = try calculateChecksum(for: fileURL, algorithm: algorithm)
        return computed.caseInsensitiveCompare(expectedHash.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
    }
    
    public func generateChecksumExport(results: [ChecksumResult], algorithm: ChecksumAlgorithm) -> String {
        var output = ""
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        switch algorithm {
        case .crc32:
            output += "; Generated by fxfile (macOS) on \(formatter.string(from: Date()))\n;\n"
            for res in results {
                output += "\(res.fileURL.lastPathComponent) \(res.hash)\n"
            }
        default:
            for res in results {
                output += "\(res.hash)  \(res.fileURL.lastPathComponent)\n"
            }
        }
        return output
    }
}
