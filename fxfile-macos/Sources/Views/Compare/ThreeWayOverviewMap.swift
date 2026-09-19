import SwiftUI
import fxfileCore

public struct ThreeWayOverviewMap: View {
    public let result: ThreeWayDiffResult
    public let currentChunkID: Int?
    public let onSelect: (Int) -> Void

    public init(
        result: ThreeWayDiffResult,
        currentChunkID: Int?,
        onSelect: @escaping (Int) -> Void
    ) {
        self.result = result
        self.currentChunkID = currentChunkID
        self.onSelect = onSelect
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(
                        Color.secondary
                            .opacity(0.08)
                    )

                ForEach(result.changes) { chunk in
                    let denominator = max(
                        1,
                        result.baseLineCount
                    )

                    let y =
                        CGFloat(chunk.base.lowerBound) /
                        CGFloat(denominator) *
                        geometry.size.height

                    let h =
                        max(
                            3,
                            CGFloat(max(1, chunk.base.count)) /
                            CGFloat(denominator) *
                            geometry.size.height
                        )

                    Rectangle()
                        .fill(color(for: chunk.kind))
                        .opacity(
                            chunk.id == currentChunkID
                            ? 0.9
                            : 0.55
                        )
                        .frame(height: h)
                        .offset(y: y)
                        .onTapGesture {
                            onSelect(chunk.id)
                        }
                }
            }
        }
        .frame(width: 18)
    }

    private func color(
        for kind: ThreeWayDiffKind
    ) -> Color {
        switch kind {
        case .equal:
            return .secondary
        case .localOnly:
            return .blue
        case .remoteOnly:
            return .purple
        case .sameChange:
            return .green
        case .conflict:
            return .red
        }
    }
}
