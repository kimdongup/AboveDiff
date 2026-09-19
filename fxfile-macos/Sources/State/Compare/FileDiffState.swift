import Foundation
import fxfileCore

@MainActor
public final class FileDiffState: ObservableObject {
    @Published public private(set) var leftURL: URL
    @Published public private(set) var rightURL: URL
    @Published public private(set) var leftText: String = ""
    @Published public private(set) var rightText: String = ""
    @Published public private(set) var result: DiffResult?
    @Published public private(set) var currentChangeIndex: Int = 0
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?

    private let engine: any DiffEngine

    public init(
        leftURL: URL,
        rightURL: URL,
        engine: any DiffEngine = LineDiffEngine()
    ) {
        self.leftURL = leftURL
        self.rightURL = rightURL
        self.engine = engine
    }

    public var changes: [DiffChunk] {
        result?.changes ?? []
    }

    public var currentChange: DiffChunk? {
        guard !changes.isEmpty,
              currentChangeIndex >= 0,
              currentChangeIndex < changes.count
        else {
            return nil
        }
        return changes[currentChangeIndex]
    }

    public var changePositionText: String {
        guard !changes.isEmpty else {
            return "No differences"
        }
        return "\(currentChangeIndex + 1) / \(changes.count)"
    }

    public func load() {
        isLoading = true
        errorMessage = nil

        let leftURL = self.leftURL
        let rightURL = self.rightURL
        let engine = self.engine

        Task.detached {
            do {
                let leftText = try Self.readText(from: leftURL)
                let rightText = try Self.readText(from: rightURL)

                let result = try engine.compare(
                    left: DiffDocument(
                        identifier: leftURL.path,
                        text: leftText
                    ),
                    right: DiffDocument(
                        identifier: rightURL.path,
                        text: rightText
                    ),
                    options: DiffOptions()
                )

                await MainActor.run {
                    self.leftText = leftText
                    self.rightText = rightText
                    self.result = result
                    self.currentChangeIndex = 0
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    public func nextChange() {
        guard !changes.isEmpty else { return }
        if currentChangeIndex < changes.count - 1 {
            currentChangeIndex += 1
        }
    }

    public func previousChange() {
        guard !changes.isEmpty else { return }
        if currentChangeIndex > 0 {
            currentChangeIndex -= 1
        }
    }

    public func selectChange(id: Int) {
        guard let index = changes.firstIndex(
            where: { $0.id == id }
        ) else {
            return
        }
        currentChangeIndex = index
    }

    nonisolated private static func readText(
        from url: URL
    ) throws -> String {
        let data = try Data(contentsOf: url)

        if let text = String(data: data, encoding: .utf8) {
            return text
        }
        if let text = String(data: data, encoding: .utf16) {
            return text
        }
        if let text = String(data: data, encoding: .isoLatin1) {
            return text
        }

        throw FileDiffStateError.unsupportedTextEncoding(url)
    }
}

public enum FileDiffStateError: LocalizedError {
    case unsupportedTextEncoding(URL)

    public var errorDescription: String? {
        switch self {
        case .unsupportedTextEncoding(let url):
            return "Unsupported text encoding: \(url.lastPathComponent)"
        }
    }
}
