import Foundation
import fxfileCore

@MainActor
public final class FileDiffGuardState: ObservableObject {
    @Published public private(set) var leftResult: TextFileGuardResult = .text
    @Published public private(set) var rightResult: TextFileGuardResult = .text
    @Published public private(set) var errorMessage: String?

    private let guardService: TextFileGuard

    public init(
        guardService: TextFileGuard = TextFileGuard()
    ) {
        self.guardService = guardService
    }

    public var canOpenTextDiff: Bool {
        isText(leftResult) &&
        isText(rightResult)
    }

    public func inspect(
        leftURL: URL,
        rightURL: URL
    ) {
        do {
            leftResult = try guardService.inspect(
                url: leftURL
            )

            rightResult = try guardService.inspect(
                url: rightURL
            )

            errorMessage = userMessage()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func isText(
        _ result: TextFileGuardResult
    ) -> Bool {
        if case .text = result {
            return true
        }

        return false
    }

    private func userMessage() -> String? {
        switch (leftResult, rightResult) {
        case (.binary, _),
             (_, .binary):
            return "Binary files cannot be opened in the text diff editor."

        case (.tooLarge(let bytes), _):
            return "The left file is too large for the text diff editor (\(ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)))."

        case (_, .tooLarge(let bytes)):
            return "The right file is too large for the text diff editor (\(ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)))."

        default:
            return nil
        }
    }
}
