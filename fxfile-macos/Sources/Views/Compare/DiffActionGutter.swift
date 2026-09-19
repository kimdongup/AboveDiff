import SwiftUI
import AboveDiffCore

public struct DiffActionGutter: View {
    public let currentChange: DiffChunk?
    public let onLeftToRight: () -> Void
    public let onRightToLeft: () -> Void

    public init(
        currentChange: DiffChunk?,
        onLeftToRight:
            @escaping () -> Void,
        onRightToLeft:
            @escaping () -> Void
    ) {
        self.currentChange =
            currentChange
        self.onLeftToRight =
            onLeftToRight
        self.onRightToLeft =
            onRightToLeft
    }

    public var body: some View {
        VStack(spacing: 8) {
            Spacer()

            Button(
                action: onRightToLeft
            ) {
                Image(
                    systemName:
                        "arrow.left"
                )
            }
            .help(
                "Apply right change to left"
            )
            .disabled(
                currentChange == nil
            )

            Button(
                action: onLeftToRight
            ) {
                Image(
                    systemName:
                        "arrow.right"
                )
            }
            .help(
                "Apply left change to right"
            )
            .disabled(
                currentChange == nil
            )

            Spacer()
        }
        .frame(width: 42)
    }
}
