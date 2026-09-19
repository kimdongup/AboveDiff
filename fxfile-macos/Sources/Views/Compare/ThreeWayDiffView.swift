import SwiftUI
import fxfileCore
import fxfileState

@MainActor
public struct ThreeWayDiffView: View {
    @StateObject private var state: ThreeWayDiffState
    @State private var synchronizedScrolling = true
    @State private var scrollGroup = SynchronizedScrollGroup()

    public init(
        localURL: URL,
        baseURL: URL,
        remoteURL: URL
    ) {
        _state = StateObject(
            wrappedValue: ThreeWayDiffState(
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
                ProgressView("Comparing three files…")
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
            } else if let result = state.result {
                content(result: result)
            } else {
                ProgressView()
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
            }
        }
        .frame(
            minWidth: 1200,
            minHeight: 760
        )
        .task {
            if state.result == nil,
               !state.isLoading {
                state.load()
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            fileLabel(
                title: "LOCAL",
                url: state.localURL,
                alignment: .leading
            )

            Spacer()

            Toggle(
                "Sync Scroll",
                isOn: $synchronizedScrolling
            )
            .toggleStyle(.checkbox)

            Toggle(
                "Conflicts only",
                isOn: Binding(
                    get: {
                        state.conflictsOnly
                    },
                    set: {
                        state.setConflictsOnly($0)
                    }
                )
            )
            .toggleStyle(.checkbox)

            Button {
                state.previousChange()
            } label: {
                Label(
                    "Previous",
                    systemImage: "chevron.up"
                )
            }
            .disabled(
                state.visibleChanges.isEmpty ||
                state.currentChangeIndex == 0
            )

            Text(state.changePositionText)
                .monospacedDigit()
                .frame(minWidth: 90)

            Button {
                state.nextChange()
            } label: {
                Label(
                    "Next",
                    systemImage: "chevron.down"
                )
            }
            .disabled(
                state.visibleChanges.isEmpty ||
                state.currentChangeIndex >=
                    state.visibleChanges.count - 1
            )

            Spacer()

            fileLabel(
                title: "BASE",
                url: state.baseURL,
                alignment: .center
            )

            Spacer()

            fileLabel(
                title: "REMOTE",
                url: state.remoteURL,
                alignment: .trailing
            )
        }
        .padding()
    }

    private func fileLabel(
        title: String,
        url: URL,
        alignment: Alignment
    ) -> some View {
        VStack(
            alignment:
                alignment == .trailing
                ? .trailing
                : .leading,
            spacing: 2
        ) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.secondary)

            Text(url.lastPathComponent)
                .font(.headline)

            Text(url.path)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(
            maxWidth: 260,
            alignment: alignment
        )
    }

    private func content(
        result: ThreeWayDiffResult
    ) -> some View {
        let group =
            synchronizedScrolling
            ? scrollGroup
            : nil

        return HStack(spacing: 0) {
            ThreeWayTextPane(
                text: state.localText,
                chunks: result.chunks,
                side: .local,
                currentChunkID:
                    state.currentChange?.id,
                scrollGroup: group
            )

            Divider()

            ThreeWayTextPane(
                text: state.baseText,
                chunks: result.chunks,
                side: .base,
                currentChunkID:
                    state.currentChange?.id,
                scrollGroup: group
            )

            ThreeWayOverviewMap(
                result: result,
                currentChunkID:
                    state.currentChange?.id
            ) { id in
                state.selectChange(id: id)
            }
            .padding(.horizontal, 4)

            Divider()

            ThreeWayTextPane(
                text: state.remoteText,
                chunks: result.chunks,
                side: .remote,
                currentChunkID:
                    state.currentChange?.id,
                scrollGroup: group
            )
        }
    }
}
