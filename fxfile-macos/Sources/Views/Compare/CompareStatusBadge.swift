import SwiftUI
import fxfileCore

public struct CompareStatusBadge: View {
    let status: DirectoryCompareStatus

    public init(status: DirectoryCompareStatus) {
        self.status = status
    }

    public var body: some View {
        Text(label)
            .font(.caption.bold())
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(backgroundColor.opacity(0.15))
            .foregroundColor(backgroundColor)
            .clipShape(Capsule())
    }

    private var label: String {
        switch status {
        case .same:
            return "Same"
        case .modified:
            return "Modified"
        case .leftOnly:
            return "Left only"
        case .rightOnly:
            return "Right only"
        case .typeMismatch:
            return "Type mismatch"
        case .error:
            return "Error"
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .same:
            return .secondary
        case .modified:
            return .blue
        case .leftOnly:
            return .orange
        case .rightOnly:
            return .green
        case .typeMismatch:
            return .purple
        case .error:
            return .red
        }
    }
}
