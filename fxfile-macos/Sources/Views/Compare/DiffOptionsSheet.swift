import SwiftUI
import AboveDiffCore
import AboveDiffState

@MainActor
public struct DiffOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var state:
        EditableFileDiffState

    @State private var ignoreBlankLines: Bool
    @State private var filters:
        [RegexTextFilter]
    @State private var syncPoints:
        [DiffSyncPoint]

    public init(
        state: EditableFileDiffState
    ) {
        self.state = state

        _ignoreBlankLines = State(
            initialValue:
                state.ignoreBlankLines
        )

        _filters = State(
            initialValue:
                state.regexFilters
        )

        _syncPoints = State(
            initialValue:
                state.syncPoints
        )
    }

    public var body: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            HStack {
                Text("Diff Options")
                    .font(.title2.bold())

                Spacer()

                Button("Close") {
                    dismiss()
                }
            }

            Toggle(
                "Ignore blank lines",
                isOn:
                    $ignoreBlankLines
            )

            Divider()

            Text("Regex text filters")
                .font(.headline)

            ForEach($filters) {
                $filter in

                HStack {
                    Toggle(
                        "",
                        isOn:
                            $filter.isEnabled
                    )
                    .labelsHidden()

                    TextField(
                        "Pattern",
                        text:
                            $filter.pattern
                    )

                    TextField(
                        "Replacement",
                        text:
                            $filter.replacement
                    )

                    Button {
                        filters.removeAll {
                            $0.id ==
                            filter.id
                        }
                    } label: {
                        Image(
                            systemName:
                                "minus.circle"
                        )
                    }
                }
            }

            Button("Add Filter") {
                filters.append(
                    RegexTextFilter(
                        pattern: ""
                    )
                )
            }

            Divider()

            Text(
                "Sync points (line numbers)"
            )
            .font(.headline)

            Text(
                "Line numbers are shown as 1-based values."
            )
            .font(.caption)
            .foregroundColor(.secondary)

            ForEach($syncPoints) {
                $point in

                HStack {
                    TextField(
                        "Left",
                        value:
                            displayBinding(
                                $point.leftLine
                            ),
                        format: .number
                    )
                    .frame(width: 90)

                    Image(
                        systemName:
                            "arrow.left.arrow.right"
                    )

                    TextField(
                        "Right",
                        value:
                            displayBinding(
                                $point.rightLine
                            ),
                        format: .number
                    )
                    .frame(width: 90)

                    Text(
                        "✓ Active"
                    )
                    .font(.caption)
                    .foregroundColor(.green)

                    Button {
                        syncPoints.removeAll {
                            $0.id ==
                            point.id
                        }
                    } label: {
                        Image(
                            systemName:
                                "minus.circle"
                        )
                    }
                }
            }

            Button("Add Sync Point") {
                syncPoints.append(
                    DiffSyncPoint(
                        leftLine: 0,
                        rightLine: 0
                    )
                )
            }

            Spacer()

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }

                Button("Apply") {
                    state.setIgnoreBlankLines(
                        ignoreBlankLines
                    )

                    state.setRegexFilters(
                        filters.filter {
                            !$0.pattern.isEmpty
                        }
                    )

                    state.setSyncPoints(
                        syncPoints
                    )

                    dismiss()
                }
                .buttonStyle(
                    .borderedProminent
                )
            }
        }
        .padding()
        .frame(
            minWidth: 640,
            minHeight: 500
        )
    }

    private func displayBinding(
        _ zeroBased: Binding<Int>
    ) -> Binding<Int> {
        Binding<Int>(
            get: {
                zeroBased.wrappedValue + 1
            },
            set: { newValue in
                zeroBased.wrappedValue =
                    max(0, newValue - 1)
            }
        )
    }
}
