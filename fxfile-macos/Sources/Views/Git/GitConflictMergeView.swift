import SwiftUI
import AboveDiffCore
import AboveDiffState

@MainActor
public struct GitConflictMergeView:
    View {

    @StateObject private var state:
        GitConflictResolutionState

    @State private var synchronizedScrolling = true
    @State private var scrollGroup = SynchronizedScrollGroup()

    public init(
        descriptor:
            GitConflictDescriptor
    ) {
        _state = StateObject(
            wrappedValue:
                GitConflictResolutionState(
                    descriptor:
                        descriptor
                )
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()

            if state.isLoading {
                ProgressView(
                    "Preparing Git conflict merge…"
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            } else if let error =
                        state.errorMessage {
                errorView(error)
            } else if let diff =
                        state.diffResult {
                mergeContent(
                    diff: diff
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
            minWidth: 1250,
            minHeight: 860
        )
        .task {
            if state.diffResult ==
                nil &&
                !state.isLoading {
                state.load()
            }
        }
    }

    private var toolbar:
        some View {
        HStack(spacing: 12) {
            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text(
                    "Resolve Git Conflict"
                )
                .font(
                    .title2.bold()
                )

                Text(
                    state.descriptor
                        .relativePath
                )
                .font(.caption)
                .foregroundColor(
                    .secondary
                )
            }

            Spacer()

            Toggle(
                "Sync Scroll",
                isOn: $synchronizedScrolling
            )
            .toggleStyle(.checkbox)

            ConflictNavigator(
                positionText:
                    state
                    .conflictPositionText,
                unresolvedCount:
                    state
                    .unresolvedCount,
                canGoPrevious:
                    state
                    .currentConflictIndex >
                    0,
                canGoNext:
                    state
                    .currentConflictIndex <
                    max(
                        0,
                        state.conflicts
                            .count - 1
                    ),
                onPrevious: {
                    state
                    .previousConflict()
                },
                onNext: {
                    state
                    .nextConflict()
                }
            )

            Spacer()

            Button(
                "Save to Working Tree"
            ) {
                state
                    .saveToWorkingTree()
            }
            .disabled(
                state.unresolvedCount >
                    0 ||
                state.isSaving
            )

            Button(
                "Stage as Resolved"
            ) {
                state
                    .stageAsResolved()
            }
            .buttonStyle(
                .borderedProminent
            )
            .disabled(
                !state
                    .didSaveToWorkingTree ||
                state.unresolvedCount >
                    0 ||
                state.isStaging ||
                state
                    .didStageResolved
            )
        }
        .padding()
    }

    private func errorView(
        _ message: String
    ) -> some View {
        VStack(spacing: 12) {
            Image(
                systemName:
                    "exclamationmark.triangle"
            )
            .font(.largeTitle)

            Text(message)
                .foregroundColor(
                    .secondary
                )

            Button("Retry") {
                state.load()
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    private func mergeContent(
        diff:
            ThreeWayDiffResult
    ) -> some View {
        let group =
            synchronizedScrolling
            ? scrollGroup
            : nil

        return VSplitView {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    pane(
                        title: "OURS / LOCAL",
                        text:
                            state.localText,
                        side: .local,
                        diff: diff,
                        scrollGroup: group
                    )

                    Divider()

                    pane(
                        title: "BASE",
                        text:
                            state.baseText,
                        side: .base,
                        diff: diff,
                        scrollGroup: group
                    )

                    Divider()

                    pane(
                        title: "THEIRS / REMOTE",
                        text:
                            state.remoteText,
                        side: .remote,
                        diff: diff,
                        scrollGroup: group
                    )
                }

                Divider()

                MergeDecisionGutter(
                    hasConflict:
                        state
                        .currentConflict !=
                        nil,
                    onUseLocal: {
                        state.useLocal()
                    },
                    onUseRemote: {
                        state.useRemote()
                    },
                    onUseBase: {
                        state.useBase()
                    },
                    onUseBothLocalThenRemote: {
                        state
                        .useBothLocalThenRemote()
                    },
                    onUseBothRemoteThenLocal: {
                        state
                        .useBothRemoteThenLocal()
                    }
                )
                .padding(8)
            }

            VStack(spacing: 0) {
                HStack {
                    Text(
                        "MERGED WORKING TREE RESULT"
                    )
                    .font(.headline)

                    Spacer()

                    if state
                        .didStageResolved {
                        Label(
                            "Staged as resolved",
                            systemImage:
                                "checkmark.circle.fill"
                        )
                        .foregroundColor(
                            .green
                        )
                    } else if state
                        .didSaveToWorkingTree {
                        Label(
                            "Saved — not staged",
                            systemImage:
                                "square.and.arrow.down"
                        )
                        .foregroundColor(
                            .orange
                        )
                    }

                    Text(
                        "\(state.unresolvedCount) unresolved"
                    )
                    .font(.caption)
                }
                .padding(
                    .horizontal
                )
                .padding(
                    .vertical,
                    8
                )

                MergeResultPane(
                    text: Binding(
                        get: {
                            state
                                .mergedText
                        },
                        set: {
                            state
                                .mergedText =
                                $0
                        }
                    )
                )
            }
        }
    }

    private func pane(
        title: String,
        text: String,
        side:
            ThreeWayTextPane.Side,
        diff:
            ThreeWayDiffResult,
        scrollGroup: SynchronizedScrollGroup?
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(
                        .caption.bold()
                    )
                    .foregroundColor(
                        .secondary
                    )

                Spacer()
            }
            .padding(
                .horizontal,
                8
            )
            .padding(
                .vertical,
                4
            )

            ThreeWayTextPane(
                text: text,
                chunks:
                    diff.chunks,
                side: side,
                currentChunkID:
                    state
                    .currentConflict?
                    .id,
                scrollGroup:
                    scrollGroup
            )
        }
    }
}
