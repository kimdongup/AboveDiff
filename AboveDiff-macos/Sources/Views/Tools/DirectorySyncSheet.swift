import SwiftUI
import AboveDiffCore
import AboveDiffLocalization
import AboveDiffState

@MainActor
public struct DirectorySyncSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    @StateObject private var compareState: DirectoryCompareState

    public init(appState: AppState, source: URL? = nil, target: URL? = nil) {
        self.appState = appState
        _compareState = StateObject(
            wrappedValue: DirectoryCompareState(
                sourceURL: source ?? appState.leftPane.currentURL,
                targetURL: target ?? appState.rightPane.currentURL
            )
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            configuration
            progressSection
            results
            Divider()
            footer
        }
        .frame(minWidth: 780, minHeight: 560)
    }

    private var header: some View {
        HStack {
            Text(L10n("sync.title"))
                .font(.title2.bold())

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var configuration: some View {
        VStack(alignment: .leading, spacing: 12) {
            pathRow(
                title: L10n("sync.source"),
                url: compareState.sourceURL
            ) {
                selectFolder { compareState.sourceURL = $0 }
            }

            pathRow(
                title: L10n("sync.target"),
                url: compareState.targetURL
            ) {
                selectFolder { compareState.targetURL = $0 }
            }

            HStack {
                Text(L10n("sync.direction"))
                    .frame(width: 120, alignment: .trailing)

                Picker("", selection: $compareState.direction) {
                    ForEach(SyncDirection.allCases) { direction in
                        Text(direction.rawValue).tag(direction)
                    }
                }
                .frame(width: 250)

                Picker("Compare", selection: $compareState.comparisonMode) {
                    Text("Smart").tag(FileComparisonMode.smart)
                    Text("Metadata").tag(FileComparisonMode.metadata)
                    Text("Content").tag(FileComparisonMode.content)
                }
                .frame(width: 130)

                Toggle(
                    L10n("sync.include_subfolders"),
                    isOn: $compareState.recursive
                )

                Spacer()

                Button(L10n("action.compare")) {
                    compareState.compare()
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    compareState.sourceURL == nil ||
                    compareState.targetURL == nil ||
                    compareState.isComparing ||
                    compareState.isSyncing
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var progressSection: some View {
        if compareState.isComparing || compareState.isSyncing {
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(
                    value: compareState.progressValue,
                    total: 1.0
                )

                Text(compareState.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    private var results: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Comparison Results: (\(compareState.syncItems.count) items)")
                    .font(.headline)

                Spacer()

                if !compareState.syncItems.isEmpty {
                    Button("Select All") {
                        compareState.selectAll()
                    }

                    Button("Deselect All") {
                        compareState.deselectAll()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Table(compareState.syncItems) {
                TableColumn("Sync") { item in
                    Toggle(
                        "",
                        isOn: Binding(
                            get: { item.isSelected },
                            set: { newValue in
                                compareState.setSelected(
                                    newValue,
                                    id: item.id
                                )
                            }
                        )
                    )
                    .labelsHidden()
                }
                .width(40)

                TableColumn("Relative Path") { item in
                    Text(item.relativePath)
                        .lineLimit(1)
                }

                TableColumn("Status") { item in
                    Text(item.status.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(statusColor(item.status))
                }
                .width(140)

                TableColumn("Action") { item in
                    Text(item.action.rawValue)
                        .font(.caption)
                }
                .width(140)

                TableColumn("Source Size") { item in
                    Text(sizeString(item.sourceSize))
                }
                .width(90)

                TableColumn("Target Size") { item in
                    Text(sizeString(item.targetSize))
                }
                .width(90)
            }
            .frame(minHeight: 240)
        }
    }

    private var footer: some View {
        HStack {
            Button(L10n("action.cancel")) {
                dismiss()
            }

            Spacer()

            Button(
                "\(L10n("sync.start_btn")) (\(compareState.activeCount))"
            ) {
                compareState.sync {
                    appState.leftPane.refresh()
                    appState.rightPane.refresh()
                    dismiss()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                compareState.activeCount == 0 ||
                compareState.isSyncing ||
                compareState.isComparing
            )
        }
        .padding()
    }

    private func pathRow(
        title: String,
        url: URL?,
        select: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(title)
                .frame(width: 120, alignment: .trailing)

            Text(url?.path ?? "None")
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Button("Select...", action: select)
        }
    }

    private func selectFolder(
        completion: @escaping (URL) -> Void
    ) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true

        if panel.runModal() == .OK,
           let url = panel.url {
            completion(url)
        }
    }

    private func statusColor(_ status: SyncStatus) -> Color {
        switch status {
        case .missingInTarget, .missingInSource:
            return .orange
        case .newerInSource, .newerInTarget:
            return .blue
        case .differentSize:
            return .purple
        case .equal:
            return .secondary
        }
    }

    private func sizeString(_ value: Int64?) -> String {
        guard let value else {
            return "--"
        }

        return ByteCountFormatter.string(
            fromByteCount: value,
            countStyle: .file
        )
    }
}
