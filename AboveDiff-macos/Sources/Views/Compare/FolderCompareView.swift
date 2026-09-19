import SwiftUI
import AppKit
import AboveDiffCore
import AboveDiffState

@MainActor
public struct FolderCompareView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var appState: AppState
    @StateObject private var state: FolderCompareState

    public init(
        appState: AppState,
        leftRoot: URL?,
        rightRoot: URL?
    ) {
        self.appState = appState

        _state = StateObject(
            wrappedValue:
                FolderCompareState(
                    leftRoot: leftRoot,
                    rightRoot: rightRoot
                )
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            rootsAndOptions
            filterBar
            progressSection
            table
            Divider()
            footer
        }
        .frame(
            minWidth: 1040,
            minHeight: 680
        )
        .task {
            if state.items.isEmpty {
                state.compare()
            }
        }
    }

    private var header: some View {
        HStack {
            Image(
                systemName:
                    "rectangle.split.2x1"
            )

            Text("Folder Compare")
                .font(.title2.bold())

            Spacer()

            if state.isComparing {
                Button("Cancel") {
                    state.cancelCompare()
                }
            }

            Button("Refresh") {
                state.refresh()
            }
            .disabled(
                state.isComparing ||
                state.isApplyingAction
            )

            Button {
                dismiss()
            } label: {
                Image(
                    systemName:
                        "xmark.circle.fill"
                )
                .foregroundColor(
                    .secondary
                )
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var rootsAndOptions: some View {
        VStack(spacing: 10) {
            rootRow(
                title: "Left",
                url: state.leftRoot
            ) {
                selectFolder {
                    state.leftRoot = $0
                }
            }

            rootRow(
                title: "Right",
                url: state.rightRoot
            ) {
                selectFolder {
                    state.rightRoot = $0
                }
            }

            HStack {
                Picker(
                    "Mode",
                    selection:
                        $state.comparisonMode
                ) {
                    Text("Smart")
                        .tag(
                            FileComparisonMode
                                .smart
                        )

                    Text("Metadata")
                        .tag(
                            FileComparisonMode
                                .metadata
                        )

                    Text("Content")
                        .tag(
                            FileComparisonMode
                                .content
                        )
                }
                .frame(width: 190)

                Toggle(
                    "Recursive",
                    isOn:
                        $state.recursive
                )

                Toggle(
                    "Hidden files",
                    isOn:
                        $state
                        .includeHiddenFiles
                )

                Spacer()

                Button("Compare") {
                    state.compare()
                }
                .buttonStyle(
                    .borderedProminent
                )
                .disabled(
                    state.leftRoot == nil ||
                    state.rightRoot == nil ||
                    state.isComparing ||
                    state.isApplyingAction
                )
            }

            HStack {
                Text("Include")

                TextField(
                    "*.swift",
                    text:
                        $state.includePattern
                )
                .frame(width: 160)

                Text("Exclude")

                TextField(
                    "*.tmp",
                    text:
                        $state.excludePattern
                )
                .frame(width: 160)

                Toggle(
                    "Regex",
                    isOn:
                        $state.useRegexNameFilter
                )

                Spacer()
            }
            .font(.caption)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var filterBar: some View {
        HStack(spacing: 12) {
            Toggle(
                "Same",
                isOn:
                    $state.showSame
            )

            Toggle(
                "Modified",
                isOn:
                    $state.showModified
            )

            Toggle(
                "Left only",
                isOn:
                    $state.showLeftOnly
            )

            Toggle(
                "Right only",
                isOn:
                    $state.showRightOnly
            )

            Toggle(
                "Errors",
                isOn:
                    $state.showErrors
            )

            Spacer()

            Text(
                "\(state.filteredItems.count) shown / \(state.items.count) total"
            )
            .font(.caption)
            .foregroundColor(
                .secondary
            )
        }
        .toggleStyle(.checkbox)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var progressSection: some View {
        if state.isComparing ||
           state.isApplyingAction {
            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                ProgressView(
                    value:
                        state.progressValue,
                    total: 1
                )

                Text(
                    state.statusMessage
                )
                .font(.caption)
                .foregroundColor(
                    .secondary
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        } else if !state
                    .statusMessage
                    .isEmpty {
            HStack {
                Text(
                    state.statusMessage
                )
                .font(.caption)
                .foregroundColor(
                    .secondary
                )

                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private var table: some View {
        Table(
            state.filteredItems,
            selection: Binding(
                get: {
                    state.selectedIDs
                },
                set: {
                    state.selectedIDs = $0
                }
            )
        ) {
            TableColumn("Path") {
                item in

                HStack(spacing: 6) {
                    Image(
                        systemName:
                            item.isDirectory
                            ? "folder"
                            : "doc"
                    )

                    Text(
                        item.relativePath
                    )
                    .lineLimit(1)
                }
            }

            TableColumn(
                "Left Size"
            ) { item in
                Text(
                    sizeString(
                        item.left?.size
                    )
                )
            }
            .width(90)

            TableColumn("Status") {
                item in

                CompareStatusBadge(
                    status:
                        item.status
                )
            }
            .width(120)

            TableColumn(
                "Right Size"
            ) { item in
                Text(
                    sizeString(
                        item.right?.size
                    )
                )
            }
            .width(90)

            TableColumn(
                "Left Modified"
            ) { item in
                Text(
                    dateString(
                        item.left?
                            .modificationDate
                    )
                )
                .font(.caption)
            }
            .width(145)

            TableColumn(
                "Right Modified"
            ) { item in
                Text(
                    dateString(
                        item.right?
                            .modificationDate
                    )
                )
                .font(.caption)
            }
            .width(145)
        }
        .contextMenu(
            forSelectionType:
                String.self
        ) { selected in
            if !selected.isEmpty {
                Button(
                    "Copy Left → Right"
                ) {
                    state.selectedIDs =
                        selected

                    state
                        .copySelectedLeftToRight {
                            appState
                                .rightPane
                                .refresh()
                        }
                }

                Button(
                    "Copy Right → Left"
                ) {
                    state.selectedIDs =
                        selected

                    state
                        .copySelectedRightToLeft {
                            appState
                                .leftPane
                                .refresh()
                        }
                }

                if let pair =
                    diffPair(
                        for: selected
                    ) {
                    Divider()

                    Button(
                        "Open File Diff"
                    ) {
                        FileDiffWindowPresenter
                            .open(
                                leftURL:
                                    pair.left,
                                rightURL:
                                    pair.right
                            )
                    }
                }
            }
        } primaryAction: {
            selected in

            guard let pair =
                diffPair(
                    for: selected
                )
            else {
                return
            }

            FileDiffWindowPresenter
                .open(
                    leftURL:
                        pair.left,
                    rightURL:
                        pair.right
                )
        }
    }

    private var footer: some View {
        HStack {
            Button(
                "Select Visible"
            ) {
                state
                    .selectAllVisible()
            }

            Button(
                "Deselect Visible"
            ) {
                state
                    .deselectAllVisible()
            }

            Spacer()

            Button(
                "Copy Left → Right"
            ) {
                state
                    .copySelectedLeftToRight {
                        appState
                            .rightPane
                            .refresh()
                    }
            }
            .disabled(
                state.selectedIDs
                    .isEmpty ||
                state.isComparing ||
                state.isApplyingAction
            )

            Button(
                "Copy Right → Left"
            ) {
                state
                    .copySelectedRightToLeft {
                        appState
                            .leftPane
                            .refresh()
                    }
            }
            .disabled(
                state.selectedIDs
                    .isEmpty ||
                state.isComparing ||
                state.isApplyingAction
            )

            Button("Close") {
                dismiss()
            }
        }
        .padding()
    }

    private func diffPair(
        for selected: Set<String>
    ) -> (
        left: URL,
        right: URL
    )? {
        guard
            selected.count == 1,
            let id =
                selected.first,
            let item =
                state.items.first(
                    where: {
                        $0.id == id
                    }
                ),
            item.status ==
                .modified,
            !item.isDirectory,
            let left =
                item.left?.url,
            let right =
                item.right?.url
        else {
            return nil
        }

        return (left, right)
    }

    private func rootRow(
        title: String,
        url: URL?,
        select:
            @escaping () -> Void
    ) -> some View {
        HStack {
            Text(title)
                .frame(
                    width: 50,
                    alignment:
                        .trailing
                )
                .fontWeight(
                    .semibold
                )

            Text(
                url?.path ??
                "None"
            )
            .lineLimit(1)
            .truncationMode(
                .middle
            )
            .frame(
                maxWidth:
                    .infinity,
                alignment:
                    .leading
            )

            Button(
                "Select…",
                action: select
            )
        }
    }

    private func selectFolder(
        completion:
            @escaping (URL)
            -> Void
    ) {
        let panel =
            NSOpenPanel()

        panel.canChooseFiles =
            false
        panel.canChooseDirectories =
            true
        panel.allowsMultipleSelection =
            false

        if panel.runModal() ==
            .OK,
           let url = panel.url {
            completion(url)
        }
    }

    private func sizeString(
        _ value: Int64?
    ) -> String {
        guard let value else {
            return "—"
        }

        return ByteCountFormatter
            .string(
                fromByteCount:
                    value,
                countStyle: .file
            )
    }

    private func dateString(
        _ date: Date?
    ) -> String {
        guard let date else {
            return "—"
        }

        return date.formatted(
            date: .numeric,
            time: .shortened
        )
    }
}
