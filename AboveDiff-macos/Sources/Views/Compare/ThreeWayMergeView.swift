import SwiftUI
import AppKit
import AboveDiffCore
import AboveDiffState

@MainActor
public struct ThreeWayMergeView: View {
    @StateObject private var state: ThreeWayMergeState
    @State private var showSaveWarning = false
    @State private var synchronizedScrolling = true
    @State private var scrollGroup = SynchronizedScrollGroup()

    public init(
        localURL: URL,
        baseURL: URL,
        remoteURL: URL
    ) {
        _state = StateObject(
            wrappedValue:
                ThreeWayMergeState(
                    localURL: localURL,
                    baseURL: baseURL,
                    remoteURL: remoteURL
                )
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()

            if state.isLoading {
                ProgressView("Preparing merge…")
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
            } else if let error = state.errorMessage {
                VStack(spacing: 12) {
                    Image(
                        systemName:
                            "exclamationmark.triangle"
                    )
                    .font(.largeTitle)

                    Text(error)
                        .foregroundColor(.secondary)

                    Button("Retry") {
                        state.load()
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
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
            minHeight: 850
        )
        .task {
            if state.diffResult == nil,
               !state.isLoading {
                state.load()
            }
        }
        .alert(
            "Unresolved Conflicts",
            isPresented: $showSaveWarning
        ) {
            Button(
                "Save Anyway",
                role: .destructive
            ) {
                saveMergedResult()
            }

            Button(
                "Cancel",
                role: .cancel
            ) {}
        } message: {
            Text(
                "\(state.unresolvedCount) conflict(s) are still unresolved."
            )
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text("Three-Way Merge")
                    .font(.title2.bold())

                Text(
                    state.localURL.lastPathComponent +
                    " / " +
                    state.baseURL.lastPathComponent +
                    " / " +
                    state.remoteURL.lastPathComponent
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            Toggle(
                "Sync Scroll",
                isOn: $synchronizedScrolling
            )
            .toggleStyle(.checkbox)

            ConflictNavigator(
                positionText:
                    state.conflictPositionText,
                unresolvedCount:
                    state.unresolvedCount,
                canGoPrevious:
                    state.currentConflictIndex > 0,
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

            if state.isDirty {
                Text("Modified")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            Button("Save Result…") {
                if state.unresolvedCount > 0 {
                    showSaveWarning = true
                } else {
                    saveMergedResult()
                }
            }
            .disabled(
                state.isLoading ||
                state.isSaving
            )
        }
        .padding()
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
                    labeledPane(
                        "LOCAL",
                        text: state.localText,
                        side: .local,
                        diff: diff,
                        scrollGroup: group
                    )

                    Divider()

                    labeledPane(
                        "BASE",
                        text: state.baseText,
                        side: .base,
                        diff: diff,
                        scrollGroup: group
                    )

                    Divider()

                    labeledPane(
                        "REMOTE",
                        text: state.remoteText,
                        side: .remote,
                        diff: diff,
                        scrollGroup: group
                    )
                }

                Divider()

                MergeDecisionGutter(
                    hasConflict:
                        state.currentConflict != nil,
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
                    text: Binding(
                        get: {
                            state.mergedText
                        },
                        set: {
                            state.updateMergedText($0)
                        }
                    )
                )
            }
        }
    }

    private func labeledPane(
        _ title: String,
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
                currentChunkID:
                    state.currentConflict?.id,
                scrollGroup: scrollGroup
            )
        }
    }

    private func saveMergedResult() {
        let panel = NSSavePanel()

        panel.nameFieldStringValue =
            "merged-" +
            state.localURL.lastPathComponent

        guard panel.runModal() == .OK,
              let url = panel.url
        else {
            return
        }

        state.saveMergedResult(to: url)
    }
}
