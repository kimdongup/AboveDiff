import Foundation
import fxfileCore

@MainActor
public final class GitConflictResolutionState:
    ObservableObject {

    public let descriptor:
        GitConflictDescriptor

    @Published public private(set)
    var localText = ""

    @Published public private(set)
    var baseText = ""

    @Published public private(set)
    var remoteText = ""

    @Published public private(set)
    var diffResult:
        ThreeWayDiffResult?

    @Published public private(set)
    var mergeStates:
        [MergeChunkState] = []

    @Published public var mergedText = ""

    @Published public private(set)
    var currentConflictIndex = 0

    @Published public private(set)
    var isLoading = false

    @Published public private(set)
    var isSaving = false

    @Published public private(set)
    var isStaging = false

    @Published public private(set)
    var didSaveToWorkingTree = false

    @Published public private(set)
    var didStageResolved = false

    @Published public private(set)
    var errorMessage: String?

    private let diffEngine:
        any ThreeWayDiffing

    private let mergeEngine:
        any ThreeWayMerging

    private let documentService:
        any TextDocumentServicing

    private let conflictService:
        any GitConflictServicing

    public init(
        descriptor:
            GitConflictDescriptor,
        diffEngine:
            any ThreeWayDiffing =
                ThreeWayDiffEngine(),
        mergeEngine:
            any ThreeWayMerging =
                ThreeWayMergeEngine(),
        documentService:
            any TextDocumentServicing =
                TextDocumentService(),
        conflictService:
            any GitConflictServicing =
                GitConflictService.shared
    ) {
        self.descriptor =
            descriptor
        self.diffEngine =
            diffEngine
        self.mergeEngine =
            mergeEngine
        self.documentService =
            documentService
        self.conflictService =
            conflictService
    }

    public var conflicts:
        [ThreeWayDiffChunk] {
        diffResult?.conflicts ?? []
    }

    public var currentConflict:
        ThreeWayDiffChunk? {
        guard !conflicts.isEmpty,
              currentConflictIndex >= 0,
              currentConflictIndex <
                conflicts.count
        else {
            return nil
        }

        return conflicts[
            currentConflictIndex
        ]
    }

    public var unresolvedCount: Int {
        mergeStates.filter {
            !$0.isResolved
        }.count
    }

    public var conflictPositionText:
        String {
        guard !conflicts.isEmpty
        else {
            return "No conflicts"
        }

        return "\(currentConflictIndex + 1) / \(conflicts.count)"
    }

    public func load() {
        isLoading = true
        errorMessage = nil

        let descriptor =
            self.descriptor
        let service =
            documentService
        let diffEngine =
            self.diffEngine
        let mergeEngine =
            self.mergeEngine

        Task.detached {
            do {
                let local =
                    try service.load(
                        url:
                            descriptor
                            .oursURL
                    )

                let base =
                    try service.load(
                        url:
                            descriptor
                            .baseURL
                    )

                let remote =
                    try service.load(
                        url:
                            descriptor
                            .theirsURL
                    )

                let diff =
                    try diffEngine
                    .compare(
                        local:
                            ThreeWayDocument(
                                text:
                                    local
                                    .text
                            ),
                        base:
                            ThreeWayDocument(
                                text:
                                    base
                                    .text
                            ),
                        remote:
                            ThreeWayDocument(
                                text:
                                    remote
                                    .text
                            ),
                        options:
                            ThreeWayDiffOptions()
                    )

                let merge =
                    mergeEngine
                    .initialMerge(
                        localText:
                            local.text,
                        baseText:
                            base.text,
                        remoteText:
                            remote.text,
                        diff:
                            diff
                    )

                await MainActor.run {
                    self.localText =
                        local.text
                    self.baseText =
                        base.text
                    self.remoteText =
                        remote.text
                    self.diffResult =
                        diff
                    self.mergeStates =
                        merge
                        .chunkStates
                    self.mergedText =
                        merge.text
                    self.currentConflictIndex =
                        0
                    self.isLoading =
                        false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage =
                        error
                        .localizedDescription
                    self.isLoading =
                        false
                }
            }
        }
    }

    public func previousConflict() {
        currentConflictIndex =
            max(
                0,
                currentConflictIndex - 1
            )
    }

    public func nextConflict() {
        guard !conflicts.isEmpty
        else {
            return
        }

        currentConflictIndex =
            min(
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
        apply(
            .useBothLocalThenRemote
        )
    }

    public func useBothRemoteThenLocal() {
        apply(
            .useBothRemoteThenLocal
        )
    }

    public func saveToWorkingTree() {
        guard unresolvedCount == 0
        else {
            errorMessage =
                "Resolve all conflicts before saving the Git merge result."
            return
        }

        isSaving = true
        errorMessage = nil

        let text =
            mergedText
        let url =
            descriptor
            .workingTreeURL
        let service =
            documentService

        Task.detached {
            do {
                try service.save(
                    text: text,
                    to: url,
                    encoding: .utf8
                )

                await MainActor.run {
                    self
                    .didSaveToWorkingTree =
                        true
                    self.isSaving =
                        false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage =
                        error
                        .localizedDescription
                    self.isSaving =
                        false
                }
            }
        }
    }

    public func stageAsResolved() {
        guard didSaveToWorkingTree
        else {
            errorMessage =
                "Save the merged result to the working tree first."
            return
        }

        guard unresolvedCount == 0
        else {
            errorMessage =
                "Resolve all conflicts before staging the file."
            return
        }

        isStaging = true
        errorMessage = nil

        let descriptor =
            self.descriptor
        let service =
            conflictService

        Task.detached {
            do {
                try service
                    .stageResolved(
                        descriptor:
                            descriptor
                    )

                let stillConflicted =
                    try service
                    .isStillConflicted(
                        descriptor:
                            descriptor
                    )

                await MainActor.run {
                    self
                    .didStageResolved =
                        !stillConflicted
                    self.isStaging =
                        false

                    if stillConflicted {
                        self.errorMessage =
                            "Git still reports this file as conflicted."
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage =
                        error
                        .localizedDescription
                    self.isStaging =
                        false
                }
            }
        }
    }

    private func apply(
        _ decision:
            MergeDecision
    ) {
        guard let conflict =
            currentConflict,
              let index =
                mergeStates
                .firstIndex(
                    where: {
                        $0.chunkID ==
                        conflict.id
                    }
                )
        else {
            return
        }

        mergeStates[index]
            .decision =
            decision

        mergeStates[index]
            .isResolved =
            true

        recompute()

        if currentConflictIndex <
            conflicts.count - 1 {
            currentConflictIndex += 1
        }
    }

    private func recompute() {
        guard let diffResult
        else {
            return
        }

        let merge =
            mergeEngine.resolve(
                localText:
                    localText,
                baseText:
                    baseText,
                remoteText:
                    remoteText,
                diff:
                    diffResult,
                states:
                    mergeStates
            )

        mergedText =
            merge.text

        mergeStates =
            merge.chunkStates

        didSaveToWorkingTree =
            false

        didStageResolved =
            false
    }
}
