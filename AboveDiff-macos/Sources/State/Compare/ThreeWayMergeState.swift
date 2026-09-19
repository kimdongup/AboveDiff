import Foundation
import AboveDiffCore

@MainActor
public final class ThreeWayMergeState: ObservableObject {
    @Published public private(set) var localURL: URL
    @Published public private(set) var baseURL: URL
    @Published public private(set) var remoteURL: URL

    @Published public private(set) var localText = ""
    @Published public private(set) var baseText = ""
    @Published public private(set) var remoteText = ""

    @Published public private(set) var diffResult: ThreeWayDiffResult?
    @Published public private(set) var mergeStates: [MergeChunkState] = []

    @Published public var mergedText = ""
    @Published public private(set) var savedMergedText = ""

    @Published public private(set) var currentConflictIndex = 0

    @Published public private(set) var isLoading = false
    @Published public private(set) var isSaving = false
    @Published public private(set) var errorMessage: String?

    private let diffEngine: any ThreeWayDiffing
    private let mergeEngine: any ThreeWayMerging
    private let documentService: any TextDocumentServicing

    public init(
        localURL: URL,
        baseURL: URL,
        remoteURL: URL,
        diffEngine: any ThreeWayDiffing = ThreeWayDiffEngine(),
        mergeEngine: any ThreeWayMerging = ThreeWayMergeEngine(),
        documentService: any TextDocumentServicing = TextDocumentService()
    ) {
        self.localURL = localURL
        self.baseURL = baseURL
        self.remoteURL = remoteURL
        self.diffEngine = diffEngine
        self.mergeEngine = mergeEngine
        self.documentService = documentService
    }

    public var conflicts: [ThreeWayDiffChunk] {
        diffResult?.conflicts ?? []
    }

    public var currentConflict: ThreeWayDiffChunk? {
        guard !conflicts.isEmpty,
              currentConflictIndex >= 0,
              currentConflictIndex < conflicts.count
        else {
            return nil
        }

        return conflicts[currentConflictIndex]
    }

    public var unresolvedCount: Int {
        mergeStates.filter {
            !$0.isResolved
        }.count
    }

    public var isDirty: Bool {
        mergedText != savedMergedText
    }

    public var conflictPositionText: String {
        guard !conflicts.isEmpty else {
            return "No conflicts"
        }

        return "\(currentConflictIndex + 1) / \(conflicts.count)"
    }

    public func load() {
        isLoading = true
        errorMessage = nil

        let localURL = self.localURL
        let baseURL = self.baseURL
        let remoteURL = self.remoteURL

        let diffEngine = self.diffEngine
        let mergeEngine = self.mergeEngine
        let documentService = self.documentService

        Task.detached {
            do {
                let localDoc = try documentService.load(url: localURL)
                let baseDoc = try documentService.load(url: baseURL)
                let remoteDoc = try documentService.load(url: remoteURL)

                let diff = try diffEngine.compare(
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

                let merge = mergeEngine.initialMerge(
                    localText: localDoc.text,
                    baseText: baseDoc.text,
                    remoteText: remoteDoc.text,
                    diff: diff
                )

                await MainActor.run {
                    self.localText = localDoc.text
                    self.baseText = baseDoc.text
                    self.remoteText = remoteDoc.text

                    self.diffResult = diff
                    self.mergeStates = merge.chunkStates
                    self.mergedText = merge.text
                    self.savedMergedText = merge.text
                    self.currentConflictIndex = 0
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

    public func nextConflict() {
        guard !conflicts.isEmpty else {
            return
        }

        currentConflictIndex =
            min(
                currentConflictIndex + 1,
                conflicts.count - 1
            )
    }

    public func previousConflict() {
        guard !conflicts.isEmpty else {
            return
        }

        currentConflictIndex =
            max(
                currentConflictIndex - 1,
                0
            )
    }

    public func selectConflict(id: Int) {
        guard let index = conflicts.firstIndex(
            where: { $0.id == id }
        ) else {
            return
        }

        currentConflictIndex = index
    }

    public func useLocal() {
        applyDecision(.useLocal)
    }

    public func useRemote() {
        applyDecision(.useRemote)
    }

    public func useBase() {
        applyDecision(.useBase)
    }

    public func useBothLocalThenRemote() {
        applyDecision(.useBothLocalThenRemote)
    }

    public func useBothRemoteThenLocal() {
        applyDecision(.useBothRemoteThenLocal)
    }

    public func updateMergedText(_ text: String) {
        mergedText = text
    }

    public func saveMergedResult(
        to url: URL
    ) {
        isSaving = true
        errorMessage = nil

        let service = documentService
        let text = mergedText

        Task.detached {
            do {
                try service.save(
                    text: text,
                    to: url,
                    encoding: .utf8
                )

                await MainActor.run {
                    self.savedMergedText = self.mergedText
                    self.isSaving = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isSaving = false
                }
            }
        }
    }

    private func applyDecision(
        _ decision: MergeDecision
    ) {
        guard let currentConflict else {
            return
        }

        guard let index = mergeStates.firstIndex(
            where: {
                $0.chunkID == currentConflict.id
            }
        ) else {
            return
        }

        mergeStates[index].decision = decision
        mergeStates[index].isResolved = true

        recomputeMerge()

        if currentConflictIndex < conflicts.count - 1 {
            currentConflictIndex += 1
        }
    }

    private func recomputeMerge() {
        guard let diffResult else {
            return
        }

        let merge = mergeEngine.resolve(
            localText: localText,
            baseText: baseText,
            remoteText: remoteText,
            diff: diffResult,
            states: mergeStates
        )

        mergedText = merge.text
        mergeStates = merge.chunkStates
    }
}
