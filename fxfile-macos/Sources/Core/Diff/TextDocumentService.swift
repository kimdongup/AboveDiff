import Foundation

public enum TextDocumentEncoding: String, Sendable, Codable {
    case utf8
    case utf16
    case isoLatin1
}

public struct LoadedTextDocument: Sendable, Hashable {
    public let url: URL
    public let text: String
    public let encoding: TextDocumentEncoding
    public let modificationDate: Date?

    public init(
        url: URL,
        text: String,
        encoding: TextDocumentEncoding,
        modificationDate: Date?
    ) {
        self.url = url
        self.text = text
        self.encoding = encoding
        self.modificationDate = modificationDate
    }
}

public protocol TextDocumentServicing: Sendable {
    func load(url: URL) throws -> LoadedTextDocument
    func save(
        text: String,
        to url: URL,
        encoding: TextDocumentEncoding
    ) throws
}

public struct TextDocumentService: TextDocumentServicing {
    public init() {}

    public func load(url: URL) throws -> LoadedTextDocument {
        let data = try Data(contentsOf: url)
        let values = try? url.resourceValues(
            forKeys: [.contentModificationDateKey]
        )

        if let text = String(data: data, encoding: .utf8) {
            return LoadedTextDocument(
                url: url,
                text: text,
                encoding: .utf8,
                modificationDate: values?.contentModificationDate
            )
        }

        if let text = String(data: data, encoding: .utf16) {
            return LoadedTextDocument(
                url: url,
                text: text,
                encoding: .utf16,
                modificationDate: values?.contentModificationDate
            )
        }

        if let text = String(data: data, encoding: .isoLatin1) {
            return LoadedTextDocument(
                url: url,
                text: text,
                encoding: .isoLatin1,
                modificationDate: values?.contentModificationDate
            )
        }

        throw TextDocumentServiceError.unsupportedEncoding(url)
    }

    public func save(
        text: String,
        to url: URL,
        encoding: TextDocumentEncoding
    ) throws {
        let stringEncoding: String.Encoding

        switch encoding {
        case .utf8:
            stringEncoding = .utf8
        case .utf16:
            stringEncoding = .utf16
        case .isoLatin1:
            stringEncoding = .isoLatin1
        }

        guard let data = text.data(using: stringEncoding) else {
            throw TextDocumentServiceError.encodingFailed(url)
        }

        try data.write(
            to: url,
            options: [.atomic]
        )
    }
}

public enum TextDocumentServiceError: LocalizedError, Sendable {
    case unsupportedEncoding(URL)
    case encodingFailed(URL)

    public var errorDescription: String? {
        switch self {
        case .unsupportedEncoding(let url):
            return "Unsupported text encoding: \(url.lastPathComponent)"
        case .encodingFailed(let url):
            return "Unable to encode text for: \(url.lastPathComponent)"
        }
    }
}
