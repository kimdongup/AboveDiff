import SwiftUI
import AboveDiffCore

public struct MergeDecisionGutter: View {
    public let hasConflict: Bool

    public let onUseLocal: () -> Void
    public let onUseRemote: () -> Void
    public let onUseBase: () -> Void
    public let onUseBothLocalThenRemote: () -> Void
    public let onUseBothRemoteThenLocal: () -> Void

    public init(
        hasConflict: Bool,
        onUseLocal: @escaping () -> Void,
        onUseRemote: @escaping () -> Void,
        onUseBase: @escaping () -> Void,
        onUseBothLocalThenRemote: @escaping () -> Void,
        onUseBothRemoteThenLocal: @escaping () -> Void
    ) {
        self.hasConflict = hasConflict
        self.onUseLocal = onUseLocal
        self.onUseRemote = onUseRemote
        self.onUseBase = onUseBase
        self.onUseBothLocalThenRemote = onUseBothLocalThenRemote
        self.onUseBothRemoteThenLocal = onUseBothRemoteThenLocal
    }

    public var body: some View {
        HStack(spacing: 8) {
            Button("Use Local") {
                onUseLocal()
            }

            Button("Use Remote") {
                onUseRemote()
            }

            Button("Use Base") {
                onUseBase()
            }

            Menu("Use Both") {
                Button("Local → Remote") {
                    onUseBothLocalThenRemote()
                }

                Button("Remote → Local") {
                    onUseBothRemoteThenLocal()
                }
            }
        }
        .disabled(!hasConflict)
    }
}
