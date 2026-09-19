import Foundation
import AboveDiffCore

@MainActor
public final class ExternalMergeToolState: ObservableObject {
    public let request: MergeToolSessionRequest

    @Published public private(set) var localText = ""
    @Published public private(set) var baseText = ""
    @Published public private(set) var remoteText = ""
    @Published public var mergedText = ""

    @Published public private(set) var diffResult: ThreeWayDiffResult?
    @Published public private(set) var mergeStates: [MergeChunkState] = []
    @Published public private(set) var currentConflictIndex = 0

    @Published public private(set) var isLoading = false
    @Published public private(set) var isSaving = false
    @Published public private(set) var isCompleted = false
    @Published public private(set) var errorMessage: String?

    private let diffEngine: any ThreeWayDiffing
    private let mergeEngine: any ThreeWayMerging
    private let documentService: any TextDocumentServicing
    private let sessionStore: MergeToolSessionStore

    public init(
        request: MergeToolSessionRequest,
        diffEngine: any ThreeWayDiffing = ThreeWayDiffEngine(),
        mergeEngine: any ThreeWayMerging = ThreeWayMergeEngine(),
        documentService: any TextDocumentServicing = TextDocumentService(),
        sessionStore: MergeToolSessionStore
    ) {
        self.request = request
        self.diffEngine = diffEngine
        self.mergeEngine = mergeEngine
        self.documentService = documentService
        self.sessionStore = sessionStore
    }

    public var conflicts: [ThreeWayDiffChunk] {
        diffResult?.conflicts ?? []
    }

    public var currentConflict: ThreeWayDiffChunk? {
        guard
            !conflicts.isEmpty,
            currentConflictIndex >= 0,
            currentConflictIndex < conflicts.count
        else {
            return nil
        }

        return conflicts[currentConflictIndex]
    }

    public var unresolvedCount: Int {
        mergeStates.filter { !$0.isResolved }.count
    }

    public var conflictPositionText: String {
        guard !conflicts.isEmpty else {
            return "No conflicts"
        }

        return "\(currentConflictIndex + 1) / \(conflicts.count)"
    }

    public func load() {
        guard !isLoading else {
            return
        }

        isLoading = true
        errorMessage = nil

        let request = self.request
        let documentService = self.documentService
        let diffEngine = self.diffEngine
        let mergeEngine = self.mergeEngine

        Task.detached {
            do {
                let local = try documentService.load(
                    url: request.arguments.localURL
                )

                let base = try documentService.load(
                    url: request.arguments.baseURL
                )

                let remote = try documentService.load(
                    url: request.arguments.remoteURL
                )

                let diff = try diffEngine.compare(
                    local: ThreeWayDocument(text: local.text),
                    base: ThreeWayDocument(text: base.text),
                    remote: ThreeWayDocument(text: remote.text),
                    options: ThreeWayDiffOptions()
                )

                let merge = mergeEngine.initialMerge(
                    localText: local.text,
                    baseText: base.text,
                    remoteText: remote.text,
                    diff: diff
                )

                await MainActor.run {
                    self.localText = local.text
                    self.baseText = base.text
                    self.remoteText = remote.text
                    self.diffResult = diff
                    self.mergeStates = merge.chunkStates
                    self.mergedText = merge.text
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

    public func previousConflict() {
        currentConflictIndex = max(
            0,
            currentConflictIndex - 1
        )
    }

    public func nextConflict() {
        guard !conflicts.isEmpty else {
            return
        }

        currentConflictIndex = min(
            conflicts.count - 1,
            currentConflictIndex + 1
        )
    }

    public func useLocal() {
        apply(.useLocal)
    }

    public func useRemote() {
        apply(.useRemote)
    }

    public func useBase() {
        apply(.useBase)
    }

    public func useBothLocalThenRemote() {
        apply(.useBothLocalThenRemote)
    }

    public func useBothRemoteThenLocal() {
        apply(.useBothRemoteThenLocal)
    }

    public func saveAndResolve() {
        guard unresolvedCount == 0 else {
            errorMessage = "Resolve all conflicts before saving."
            return
        }

        guard !isSaving else {
            return
        }

        isSaving = true
        errorMessage = nil

        let text = mergedText
        let mergedURL = request.arguments.mergedURL
        let request = self.request
        let documentService = self.documentService
        let sessionStore = self.sessionStore

        Task.detached {
            do {
                try documentService.save(
                    text: text,
                    to: mergedURL,
                    encoding: .utf8
                )

                try sessionStore.writeResult(
                    MergeToolSessionResult(
                        sessionID: request.id,
                        outcome: .resolved,
                        exitStatus: .success
                    )
                )

                await MainActor.run {
                    self.isSaving = false
                    self.isCompleted = true
                }
            } catch {
                let message = error.localizedDescription

                try? sessionStore.writeResult(
                    MergeToolSessionResult(
                        sessionID: request.id,
                        outcome: .failed,
                        exitStatus: .fileError,
                        message: message
                    )
                )

                await MainActor.run {
                    self.errorMessage = message
                    self.isSaving = false
                }
            }
        }
    }

    public func cancel() {
        guard !isCompleted else {
            return
        }

        do {
            try sessionStore.writeResult(
                MergeToolSessionResult(
                    sessionID: request.id,
                    outcome: .cancelled,
                    exitStatus: .cancelled,
                    message: "Merge cancelled by user."
                )
            )

            isCompleted = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply(
        _ decision: MergeDecision
    ) {
        guard
            let conflict = currentConflict,
            let index = mergeStates.firstIndex(
                where: { $0.chunkID == conflict.id }
            )
        else {
            return
        }

        mergeStates[index].decision = decision
        mergeStates[index].isResolved = true

        recompute()

        if currentConflictIndex < conflicts.count - 1 {
            currentConflictIndex += 1
        }
    }

    private func recompute() {
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
