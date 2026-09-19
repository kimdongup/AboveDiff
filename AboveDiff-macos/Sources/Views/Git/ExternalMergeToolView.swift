import SwiftUI
import AboveDiffCore
import AboveDiffState

@MainActor
public struct ExternalMergeToolView: View {
    @StateObject private var state: ExternalMergeToolState

    @State private var synchronizedScrolling = true
    @State private var scrollGroup = SynchronizedScrollGroup()

    private let onComplete: () -> Void

    public init(
        request: MergeToolSessionRequest,
        sessionStore: MergeToolSessionStore,
        onComplete: @escaping () -> Void
    ) {
        _state = StateObject(
            wrappedValue: ExternalMergeToolState(
                request: request,
                sessionStore: sessionStore
            )
        )

        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()

            if state.isLoading {
                ProgressView("Preparing Git mergetool session…")
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
            } else if let error = state.errorMessage {
                errorView(error)
            } else if let diff = state.diffResult {
                mergeContent(diff: diff)
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
            state.load()
        }
        .onChange(of: state.isCompleted) { completed in
            if completed {
                onComplete()
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text("AboveDiff Git Mergetool")
                    .font(.title2.bold())

                Text(
                    state.request.arguments.mergedURL.path
                )
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            }

            Spacer()

            Toggle(
                "Sync Scroll",
                isOn: $synchronizedScrolling
            )
            .toggleStyle(.checkbox)

            ConflictNavigator(
                positionText: state.conflictPositionText,
                unresolvedCount: state.unresolvedCount,
                canGoPrevious: state.currentConflictIndex > 0,
                canGoNext:
                    state.currentConflictIndex <
                    max(0, state.conflicts.count - 1),
                onPrevious: {
                    state.previousConflict()
                },
                onNext: {
                    state.nextConflict()
                }
            )

            Spacer()

            Button("Cancel") {
                state.cancel()
            }

            Button("Save & Resolve") {
                state.saveAndResolve()
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                state.unresolvedCount > 0 ||
                state.isSaving
            )
        }
        .padding()
    }

    private func errorView(
        _ message: String
    ) -> some View {
        VStack(spacing: 12) {
            Image(
                systemName: "exclamationmark.triangle"
            )
            .font(.largeTitle)

            Text(message)
                .foregroundColor(.secondary)

            HStack {
                Button("Cancel") {
                    state.cancel()
                }

                Button("Retry") {
                    state.load()
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    private func mergeContent(
        diff: ThreeWayDiffResult
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
                        text: state.localText,
                        side: .local,
                        diff: diff,
                        scrollGroup: group
                    )

                    Divider()

                    pane(
                        title: "BASE",
                        text: state.baseText,
                        side: .base,
                        diff: diff,
                        scrollGroup: group
                    )

                    Divider()

                    pane(
                        title: "THEIRS / REMOTE",
                        text: state.remoteText,
                        side: .remote,
                        diff: diff,
                        scrollGroup: group
                    )
                }

                Divider()

                MergeDecisionGutter(
                    hasConflict: state.currentConflict != nil,
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
                        state.useBothLocalThenRemote()
                    },
                    onUseBothRemoteThenLocal: {
                        state.useBothRemoteThenLocal()
                    }
                )
                .padding(8)
            }

            VStack(spacing: 0) {
                HStack {
                    Text("MERGED RESULT")
                        .font(.headline)

                    Spacer()

                    Text(
                        "\(state.unresolvedCount) unresolved"
                    )
                    .font(.caption)
                    .foregroundColor(
                        state.unresolvedCount == 0
                        ? .green
                        : .orange
                    )
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                MergeResultPane(
                    text: $state.mergedText
                )
            }
        }
    }

    private func pane(
        title: String,
        text: String,
        side: ThreeWayTextPane.Side,
        diff: ThreeWayDiffResult,
        scrollGroup: SynchronizedScrollGroup?
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            ThreeWayTextPane(
                text: text,
                chunks: diff.chunks,
                side: side,
                currentChunkID: state.currentConflict?.id,
                scrollGroup: scrollGroup
            )
        }
    }
}
