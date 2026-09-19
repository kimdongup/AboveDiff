import Foundation
import fxfileCore

@MainActor
public final class ThreeWayDiffState: ObservableObject {
    @Published public private(set) var localURL: URL
    @Published public private(set) var baseURL: URL
    @Published public private(set) var remoteURL: URL

    @Published public private(set) var localText: String = ""
    @Published public private(set) var baseText: String = ""
    @Published public private(set) var remoteText: String = ""

    @Published public private(set) var result: ThreeWayDiffResult?
    @Published public private(set) var currentChangeIndex = 0
    @Published public var conflictsOnly = false

    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?

    private let engine: any ThreeWayDiffing
    private let documentService: any TextDocumentServicing

    public init(
        localURL: URL,
        baseURL: URL,
        remoteURL: URL,
        engine: any ThreeWayDiffing = ThreeWayDiffEngine(),
        documentService: any TextDocumentServicing = TextDocumentService()
    ) {
        self.localURL = localURL
        self.baseURL = baseURL
        self.remoteURL = remoteURL
        self.engine = engine
        self.documentService = documentService
    }

    public var visibleChanges: [ThreeWayDiffChunk] {
        guard let result else {
            return []
        }

        return conflictsOnly
            ? result.conflicts
            : result.changes
    }

    public var currentChange: ThreeWayDiffChunk? {
        guard !visibleChanges.isEmpty,
              currentChangeIndex >= 0,
              currentChangeIndex < visibleChanges.count
        else {
            return nil
        }

        return visibleChanges[currentChangeIndex]
    }

    public var changePositionText: String {
        guard !visibleChanges.isEmpty else {
            return conflictsOnly ? "No conflicts" : "No differences"
        }

        return "\(currentChangeIndex + 1) / \(visibleChanges.count)"
    }

    public func load() {
        isLoading = true
        errorMessage = nil

        let localURL = self.localURL
        let baseURL = self.baseURL
        let remoteURL = self.remoteURL
        let engine = self.engine
        let service = self.documentService

        Task.detached {
            do {
                let localDoc = try service.load(url: localURL)
                let baseDoc = try service.load(url: baseURL)
                let remoteDoc = try service.load(url: remoteURL)

                let result = try engine.compare(
                    local: ThreeWayDocument(
                        identifier: localURL.path,
                        text: localDoc.text
                    ),
                    base: ThreeWayDocument(
                        identifier: baseURL.path,
                        text: baseDoc.text
                    ),
                    remote: ThreeWayDocument(
                        identifier: remoteURL.path,
                        text: remoteDoc.text
                    ),
                    options: ThreeWayDiffOptions()
                )

                await MainActor.run {
                    self.localText = localDoc.text
                    self.baseText = baseDoc.text
                    self.remoteText = remoteDoc.text
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
        guard !visibleChanges.isEmpty else {
            return
        }

        currentChangeIndex =
            min(
                currentChangeIndex + 1,
                visibleChanges.count - 1
            )
    }

    public func previousChange() {
        guard !visibleChanges.isEmpty else {
            return
        }

        currentChangeIndex =
            max(0, currentChangeIndex - 1)
    }

    public func selectChange(id: Int) {
        guard let index = visibleChanges.firstIndex(
            where: { $0.id == id }
        ) else {
            return
        }

        currentChangeIndex = index
    }

    public func setConflictsOnly(_ enabled: Bool) {
        conflictsOnly = enabled
        currentChangeIndex = 0
    }
}
