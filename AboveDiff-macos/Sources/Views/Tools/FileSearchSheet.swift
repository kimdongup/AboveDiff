import SwiftUI
import AboveDiffCore
import AboveDiffLocalization
import AboveDiffState

@MainActor
public struct FileSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    
    @State private var searchRootURL: URL
    @State private var nameQuery: String = ""
    @State private var contentQuery: String = ""
    @State private var useRegex: Bool = false
    @State private var caseSensitive: Bool = false
    @State private var typeFilter: SearchFileTypeFilter = .all
    @State private var includeHidden: Bool = false
    @State private var recursive: Bool = true
    
    @State private var searchResults: [SearchResultItem] = []
    @State private var isSearching: Bool = false
    @State private var selectedResultID: UUID? = nil
    
    // Cancellation flag holder
    private class CancellationHolder: @unchecked Sendable {
        var isCancelled = false
    }
    @State private var cancelHolder = CancellationHolder()
    
    public init(appState: AppState, rootURL: URL? = nil) {
        self.appState = appState
        self._searchRootURL = State(initialValue: rootURL ?? appState.activePane.currentURL)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n("search.title"))
                    .font(.title2.bold())
                Spacer()
                Button(action: {
                    cancelHolder.isCancelled = true
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Search Parameters
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(L10n("search.search_in"))
                        .frame(width: 140, alignment: .trailing)
                    Text(searchRootURL.path)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Browse...") {
                        selectFolder()
                    }
                }
                
                HStack {
                    Text(L10n("search.file_name"))
                        .frame(width: 140, alignment: .trailing)
                    TextField("e.g. *.swift, Report*.*", text: $nameQuery)
                        .textFieldStyle(.roundedBorder)
                    
                    Toggle("Regex", isOn: $useRegex)
                    Toggle("Case Sensitive", isOn: $caseSensitive)
                }
                
                HStack {
                    Text(L10n("search.content"))
                        .frame(width: 140, alignment: .trailing)
                    TextField("Text inside file...", text: $contentQuery)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    Text("Type Filter:")
                        .frame(width: 140, alignment: .trailing)
                    Picker("", selection: $typeFilter) {
                        ForEach(SearchFileTypeFilter.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .frame(width: 180)
                    
                    Toggle("Subfolders", isOn: $recursive)
                    Toggle("Hidden Files", isOn: $includeHidden)
                    
                    Spacer()
                    
                    if isSearching {
                        Button(L10n("action.stop")) {
                            cancelHolder.isCancelled = true
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button(L10n("action.start")) {
                            startSearch()
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Results Table
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(L10n("search.results_count")) \(searchResults.count)")
                        .font(.headline)
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text(L10n("search.searching"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Table(searchResults, selection: $selectedResultID) {
                    TableColumn("Name") { item in
                        HStack(spacing: 6) {
                            Image(nsImage: item.fileItem.icon)
                                .resizable()
                                .frame(width: 16, height: 16)
                            Text(item.fileItem.name)
                                .fontWeight(.medium)
                        }
                    }
                    TableColumn("Location") { item in
                        Text(item.fileItem.url.deletingLastPathComponent().path)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    TableColumn("Size") { item in
                        Text(item.fileItem.formattedSize)
                    }
                    .width(90)
                    TableColumn("Modified") { item in
                        Text(item.fileItem.formattedDate)
                    }
                    .width(130)
                    TableColumn("Content Match") { item in
                        if let snippet = item.matchSnippet {
                            Text(item.matchLineNumber.map { "L\($0): \(snippet)" } ?? snippet)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .lineLimit(1)
                        } else {
                            Text("--")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(minHeight: 250)
            }
            
            Divider()
            
            // Footer
            HStack {
                Button("Reveal in Active Pane") {
                    revealSelected()
                }
                .disabled(selectedResultID == nil)
                
                Button("Open File") {
                    openSelected()
                }
                .disabled(selectedResultID == nil)
                
                Spacer()
                
                Button(L10n("action.close")) {
                    cancelHolder.isCancelled = true
                    dismiss()
                }
            }
            .padding()
        }
        .frame(minWidth: 780, minHeight: 560)
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            searchRootURL = url
        }
    }
    
    private func startSearch() {
        isSearching = true
        cancelHolder = CancellationHolder()
        let holder = cancelHolder
        searchResults.removeAll()
        
        let criteria = SearchCriteria(
            rootURL: searchRootURL,
            nameQuery: nameQuery,
            useRegex: useRegex,
            caseSensitiveName: caseSensitive,
            contentQuery: contentQuery,
            caseSensitiveContent: caseSensitive,
            typeFilter: typeFilter,
            includeHidden: includeHidden,
            recursive: recursive
        )
        
        Task.detached(priority: .userInitiated) {
            FileSearchEngine.shared.search(
                criteria: criteria,
                onResult: { item in
                    Task { @MainActor in
                        self.searchResults.append(item)
                    }
                },
                shouldCancel: {
                    holder.isCancelled
                }
            )
            
            await MainActor.run {
                self.isSearching = false
            }
        }
    }
    
    private func revealSelected() {
        guard let id = selectedResultID, let match = searchResults.first(where: { $0.id == id }) else { return }
        let parentURL = match.fileItem.url.deletingLastPathComponent()
        appState.activePane.navigateTo(url: parentURL)
        appState.activePane.selectedItemIDs = [match.fileItem.id]
        dismiss()
    }
    
    private func openSelected() {
        guard let id = selectedResultID, let match = searchResults.first(where: { $0.id == id }) else { return }
        FileSystemService.shared.openWithDefaultApp(url: match.fileItem.url)
    }
}
