import Foundation
import fxfileCore

@MainActor
public final class EditableFileDiffState: ObservableObject {
    @Published public private(set) var leftURL: URL
    @Published public private(set) var rightURL: URL

    @Published public var leftText: String = ""
    @Published public var rightText: String = ""

    @Published public private(set) var result: DiffResult?
    @Published public private(set) var currentChangeIndex: Int = 0

    @Published public private(set) var leftDirty = false
    @Published public private(set) var rightDirty = false

    @Published public var ignoreBlankLines = false
    @Published public var regexFilters: [RegexTextFilter] = []
    @Published public var syncPoints: [DiffSyncPoint] = []

    @Published public private(set) var isLoading = false
    @Published public private(set) var isSaving = false
    @Published public private(set) var errorMessage: String?

    private var leftSavedText = ""
    private var rightSavedText = ""

    private var leftEncoding: TextDocumentEncoding = .utf8
    private var rightEncoding: TextDocumentEncoding = .utf8

    private let diffEngine: any DiffEngine
    private let editEngine: any DiffEditing
    private let documentService: any TextDocumentServicing

    private var rediffTask: Task<Void, Never>?

    public init(
        leftURL: URL,
        rightURL: URL,
        diffEngine: any DiffEngine = LineDiffEngine(),
        editEngine: any DiffEditing = DiffEditEngine(),
        documentService: any TextDocumentServicing = TextDocumentService()
    ) {
        self.leftURL = leftURL
        self.rightURL = rightURL
        self.diffEngine = diffEngine
        self.editEngine = editEngine
        self.documentService = documentService
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
        let service = self.documentService
        let engine = self.diffEngine
        let options = makeOptions()

        Task.detached {
            do {
                let leftDoc = try service.load(url: leftURL)
                let rightDoc = try service.load(url: rightURL)

                let result = try engine.compare(
                    left: DiffDocument(
                        identifier: leftURL.path,
                        text: leftDoc.text
                    ),
                    right: DiffDocument(
                        identifier: rightURL.path,
                        text: rightDoc.text
                    ),
                    options: options
                )

                await MainActor.run {
                    self.leftText = leftDoc.text
                    self.rightText = rightDoc.text

                    self.leftSavedText = leftDoc.text
                    self.rightSavedText = rightDoc.text

                    self.leftEncoding = leftDoc.encoding
                    self.rightEncoding = rightDoc.encoding

                    self.leftDirty = false
                    self.rightDirty = false

                    self.result = result
                    self.currentChangeIndex = 0
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage =
                        error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    public func setIgnoreBlankLines(_ enabled: Bool) {
        ignoreBlankLines = enabled
        recomputeImmediately()
    }

    public func setRegexFilters(
        _ filters: [RegexTextFilter]
    ) {
        regexFilters = filters
        recomputeImmediately()
    }

    public func setSyncPoints(
        _ points: [DiffSyncPoint]
    ) {
        syncPoints = points
        recomputeImmediately()
    }

    public func updateLeftText(_ text: String) {
        leftText = text
        leftDirty = text != leftSavedText
        scheduleRediff()
    }

    public func updateRightText(_ text: String) {
        rightText = text
        rightDirty = text != rightSavedText
        scheduleRediff()
    }

    public func applyCurrentLeftToRight() {
        guard let chunk = currentChange else {
            return
        }

        apply(chunk: chunk, from: .left)
    }

    public func applyCurrentRightToLeft() {
        guard let chunk = currentChange else {
            return
        }

        apply(chunk: chunk, from: .right)
    }

    private func apply(
        chunk: DiffChunk,
        from side: DiffSide
    ) {
        do {
            let edited = try editEngine.apply(
                chunk: chunk,
                from: side,
                leftText: leftText,
                rightText: rightText
            )

            leftText = edited.leftText
            rightText = edited.rightText

            leftDirty = leftText != leftSavedText
            rightDirty = rightText != rightSavedText

            recomputeImmediately()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func nextChange() {
        guard !changes.isEmpty else {
            return
        }

        if currentChangeIndex < changes.count - 1 {
            currentChangeIndex += 1
        }
    }

    public func previousChange() {
        guard !changes.isEmpty else {
            return
        }

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

    public func saveLeft() {
        save(side: .left)
    }

    public func saveRight() {
        save(side: .right)
    }

    public func saveAll() {
        guard leftDirty || rightDirty else {
            return
        }

        isSaving = true
        errorMessage = nil

        let service = documentService
        let leftURL = self.leftURL
        let rightURL = self.rightURL
        let leftText = self.leftText
        let rightText = self.rightText
        let leftEncoding = self.leftEncoding
        let rightEncoding = self.rightEncoding
        let saveLeft = self.leftDirty
        let saveRight = self.rightDirty

        Task.detached {
            do {
                if saveLeft {
                    try service.save(
                        text: leftText,
                        to: leftURL,
                        encoding: leftEncoding
                    )
                }

                if saveRight {
                    try service.save(
                        text: rightText,
                        to: rightURL,
                        encoding: rightEncoding
                    )
                }

                await MainActor.run {
                    if saveLeft {
                        self.leftSavedText = self.leftText
                        self.leftDirty = false
                    }

                    if saveRight {
                        self.rightSavedText = self.rightText
                        self.rightDirty = false
                    }

                    self.isSaving = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage =
                        error.localizedDescription
                    self.isSaving = false
                }
            }
        }
    }

    private func save(side: DiffSide) {
        isSaving = true
        errorMessage = nil

        let service = documentService

        switch side {
        case .left:
            let url = leftURL
            let text = leftText
            let encoding = leftEncoding

            Task.detached {
                do {
                    try service.save(
                        text: text,
                        to: url,
                        encoding: encoding
                    )

                    await MainActor.run {
                        self.leftSavedText = self.leftText
                        self.leftDirty = false
                        self.isSaving = false
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage =
                            error.localizedDescription
                        self.isSaving = false
                    }
                }
            }

        case .right:
            let url = rightURL
            let text = rightText
            let encoding = rightEncoding

            Task.detached {
                do {
                    try service.save(
                        text: text,
                        to: url,
                        encoding: encoding
                    )

                    await MainActor.run {
                        self.rightSavedText = self.rightText
                        self.rightDirty = false
                        self.isSaving = false
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage =
                            error.localizedDescription
                        self.isSaving = false
                    }
                }
            }
        }
    }

    private func scheduleRediff() {
        rediffTask?.cancel()

        let left = leftText
        let right = rightText
        let engine = diffEngine
        let options = makeOptions()

        rediffTask = Task {
            try? await Task.sleep(
                nanoseconds: 300_000_000
            )

            guard !Task.isCancelled else {
                return
            }

            do {
                let newResult = try await Task.detached {
                    try engine.compare(
                        left: DiffDocument(text: left),
                        right: DiffDocument(text: right),
                        options: options
                    )
                }.value

                guard !Task.isCancelled else {
                    return
                }

                self.result = newResult
                normalizeCurrentIndex()
                self.errorMessage = nil
            } catch {
                self.errorMessage =
                    error.localizedDescription
            }
        }
    }

    private func recomputeImmediately() {
        rediffTask?.cancel()

        do {
            result = try diffEngine.compare(
                left: DiffDocument(text: leftText),
                right: DiffDocument(text: rightText),
                options: makeOptions()
            )

            normalizeCurrentIndex()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func makeOptions() -> DiffOptions {
        DiffOptions(
            ignoreBlankLines: ignoreBlankLines,
            regexFilters: regexFilters,
            syncPoints: syncPoints
        )
    }

    private func normalizeCurrentIndex() {
        if changes.isEmpty {
            currentChangeIndex = 0
        } else if currentChangeIndex >= changes.count {
            currentChangeIndex = changes.count - 1
        }
    }
}
