import SwiftUI
import AboveDiffCore
import AboveDiffState

@MainActor
public struct FileDiffView: View {
    @StateObject private var state:
        EditableFileDiffState

    @State private var showOptions = false
    @State private var synchronizedScrolling = true

    private let largeFilePolicy =
        DiffLargeFilePolicy()

    @State private var scrollGroup =
        SynchronizedScrollGroup()

    public init(
        leftURL: URL,
        rightURL: URL
    ) {
        _state = StateObject(
            wrappedValue:
                EditableFileDiffState(
                    leftURL: leftURL,
                    rightURL: rightURL
                )
        )
    }

    private var isLargeFile: Bool {
        largeFilePolicy.isLarge(
            text: state.leftText
        ) ||
        largeFilePolicy.isLarge(
            text: state.rightText
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            toolbar

            if isLargeFile {
                HStack {
                    Image(
                        systemName:
                            "exclamationmark.triangle"
                    )

                    Text(
                        "Large file mode: change highlighting is reduced for performance."
                    )

                    Spacer()
                }
                .font(.caption)
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(
                    Color.orange
                        .opacity(0.12)
                )
            }

            SyncPointSummaryBar(
                points:
                    state.syncPoints
            )

            Divider()

            if state.isLoading {
                ProgressView(
                    "Comparing files…"
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            } else if let error =
                        state.errorMessage {
                VStack(spacing: 12) {
                    Image(
                        systemName:
                            "exclamationmark.triangle"
                    )
                    .font(.largeTitle)

                    Text(error)
                        .foregroundColor(
                            .secondary
                        )

                    Button("Diff Options…") {
                        showOptions = true
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            } else if let result =
                        state.result {
                content(
                    result: result
                )
            } else {
                ProgressView()
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
            }
        }
        .frame(
            minWidth: 1000,
            minHeight: 700
        )
        .task {
            if state.result == nil,
               !state.isLoading {
                state.load()
            }
        }
        .sheet(
            isPresented:
                $showOptions
        ) {
            DiffOptionsSheet(
                state: state
            )
        }
    }

    private var toolbar: some View {
        HStack {
            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                HStack(spacing: 4) {
                    if state.leftDirty {
                        Circle()
                            .frame(
                                width: 7,
                                height: 7
                            )
                    }

                    Text(
                        state.leftURL
                            .lastPathComponent
                    )
                    .font(.headline)
                }

                Text(
                    state.leftURL.path
                )
                .font(.caption)
                .foregroundColor(
                    .secondary
                )
                .lineLimit(1)
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )

            Toggle(
                "Sync Scroll",
                isOn: $synchronizedScrolling
            )
            .toggleStyle(.checkbox)

            Button("Options…") {
                showOptions = true
            }

            Button("Save Left") {
                state.saveLeft()
            }
            .disabled(
                !state.leftDirty ||
                state.isSaving
            )

            Button("Save All") {
                state.saveAll()
            }
            .disabled(
                (!state.leftDirty &&
                 !state.rightDirty) ||
                state.isSaving
            )

            Button("Save Right") {
                state.saveRight()
            }
            .disabled(
                !state.rightDirty ||
                state.isSaving
            )

            Divider()
                .frame(height: 22)

            Button {
                state.previousChange()
            } label: {
                Label(
                    "Previous",
                    systemImage:
                        "chevron.up"
                )
            }
            .disabled(
                state.changes.isEmpty ||
                state.currentChangeIndex ==
                    0
            )

            Text(
                state.changePositionText
            )
            .monospacedDigit()
            .frame(minWidth: 80)

            Button {
                state.nextChange()
            } label: {
                Label(
                    "Next",
                    systemImage:
                        "chevron.down"
                )
            }
            .disabled(
                state.changes.isEmpty ||
                state.currentChangeIndex >=
                    state.changes.count - 1
            )

            VStack(
                alignment: .trailing,
                spacing: 2
            ) {
                HStack(spacing: 4) {
                    Text(
                        state.rightURL
                            .lastPathComponent
                    )
                    .font(.headline)

                    if state.rightDirty {
                        Circle()
                            .frame(
                                width: 7,
                                height: 7
                            )
                    }
                }

                Text(
                    state.rightURL.path
                )
                .font(.caption)
                .foregroundColor(
                    .secondary
                )
                .lineLimit(1)
            }
            .frame(
                maxWidth: .infinity,
                alignment: .trailing
            )
        }
        .padding()
    }

    private func content(
        result: DiffResult
    ) -> some View {
        let group =
            synchronizedScrolling
            ? scrollGroup
            : nil

        return HStack(spacing: 0) {
            EditableDiffTextPane(
                text:
                    state.leftText,
                chunks:
                    isLargeFile
                    ? []
                    : result.chunks,
                side: .left,
                currentChangeID:
                    state.currentChange?.id,
                scrollGroup: group
            ) { newText in
                state.updateLeftText(
                    newText
                )
            }

            Divider()

            DiffActionGutter(
                currentChange:
                    state.currentChange,
                onLeftToRight: {
                    state
                        .applyCurrentLeftToRight()
                },
                onRightToLeft: {
                    state
                        .applyCurrentRightToLeft()
                }
            )

            DiffOverviewMap(
                result: result,
                currentChangeID:
                    state.currentChange?.id
            ) { id in
                state.selectChange(
                    id: id
                )
            }
            .padding(
                .horizontal,
                4
            )

            DiffActionGutter(
                currentChange:
                    state.currentChange,
                onLeftToRight: {
                    state
                        .applyCurrentLeftToRight()
                },
                onRightToLeft: {
                    state
                        .applyCurrentRightToLeft()
                }
            )

            Divider()

            EditableDiffTextPane(
                text:
                    state.rightText,
                chunks:
                    isLargeFile
                    ? []
                    : result.chunks,
                side: .right,
                currentChangeID:
                    state.currentChange?.id,
                scrollGroup: group
            ) { newText in
                state.updateRightText(
                    newText
                )
            }
        }
    }
}
