import SwiftUI
import fxfileCore

public struct DiffOverviewMap: View {
    public let result: DiffResult
    public let currentChangeID: Int?
    public let onSelect: (Int) -> Void

    public init(
        result: DiffResult,
        currentChangeID: Int?,
        onSelect: @escaping (Int) -> Void
    ) {
        self.result = result
        self.currentChangeID = currentChangeID
        self.onSelect = onSelect
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.08))

                ForEach(result.changes) { chunk in
                    let total = max(
                        result.leftLineCount,
                        result.rightLineCount,
                        1
                    )

                    let start = min(
                        chunk.left.lowerBound,
                        chunk.right.lowerBound
                    )

                    let length = max(
                        chunk.left.count,
                        chunk.right.count,
                        1
                    )

                    let y =
                        geometry.size.height *
                        CGFloat(start) /
                        CGFloat(total)

                    let height = max(
                        3,
                        geometry.size.height *
                        CGFloat(length) /
                        CGFloat(total)
                    )

                    Rectangle()
                        .fill(
                            color(for: chunk).opacity(
                                chunk.id == currentChangeID
                                    ? 0.9
                                    : 0.55
                            )
                        )
                        .frame(height: height)
                        .offset(y: y)
                        .onTapGesture {
                            onSelect(chunk.id)
                        }
                }
            }
        }
        .frame(width: 14)
    }

    private func color(
        for chunk: DiffChunk
    ) -> Color {
        switch chunk.kind {
        case .equal:
            return .secondary
        case .insert:
            return .green
        case .delete:
            return .red
        case .replace:
            return .yellow
        }
    }
}
