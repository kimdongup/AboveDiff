import SwiftUI
import fxfileCore

public struct SyncPointSummaryBar: View {
    public let points: [DiffSyncPoint]

    public init(points: [DiffSyncPoint]) {
        self.points = points
    }

    public var body: some View {
        if !points.isEmpty {
            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                HStack(spacing: 8) {
                    Text("Sync Points")
                        .font(.caption.bold())

                    ForEach(points) { point in
                        HStack(spacing: 4) {
                            Text(
                                "L \(point.leftLine + 1)"
                            )

                            Image(
                                systemName:
                                    "arrow.left.arrow.right"
                            )

                            Text(
                                "R \(point.rightLine + 1)"
                            )
                        }
                        .font(.caption.monospacedDigit())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Color.accentColor
                                .opacity(0.12)
                        )
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
    }
}
