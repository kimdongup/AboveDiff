import SwiftUI

public struct ConflictNavigator: View {
    public let positionText: String
    public let unresolvedCount: Int
    public let canGoPrevious: Bool
    public let canGoNext: Bool
    public let onPrevious: () -> Void
    public let onNext: () -> Void

    public init(
        positionText: String,
        unresolvedCount: Int,
        canGoPrevious: Bool,
        canGoNext: Bool,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void
    ) {
        self.positionText = positionText
        self.unresolvedCount = unresolvedCount
        self.canGoPrevious = canGoPrevious
        self.canGoNext = canGoNext
        self.onPrevious = onPrevious
        self.onNext = onNext
    }

    public var body: some View {
        HStack(spacing: 10) {
            Button {
                onPrevious()
            } label: {
                Label(
                    "Previous Conflict",
                    systemImage: "chevron.up"
                )
            }
            .disabled(!canGoPrevious)

            Text(positionText)
                .monospacedDigit()
                .frame(minWidth: 90)

            Button {
                onNext()
            } label: {
                Label(
                    "Next Conflict",
                    systemImage: "chevron.down"
                )
            }
            .disabled(!canGoNext)

            Divider()
                .frame(height: 20)

            if unresolvedCount == 0 {
                Label(
                    "All conflicts resolved",
                    systemImage: "checkmark.circle.fill"
                )
                .foregroundColor(.green)
            } else {
                Label(
                    "\(unresolvedCount) unresolved",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundColor(.orange)
            }
        }
    }
}
