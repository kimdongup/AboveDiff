import SwiftUI
import fxfileCore
import fxfileLocalization
import fxfileState

@MainActor
public struct PaneView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var paneState: PaneState
    let paneIndex: Int
    
    @State private var isEditingPath: Bool = false
    @State private var editablePath: String = ""
    
    public init(appState: AppState, paneState: PaneState, paneIndex: Int) {
        self.appState = appState
        self.paneState = paneState
        self.paneIndex = paneIndex
    }
    
    private var isActive: Bool {
        appState.activePaneIndex == paneIndex
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 2) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(Array(paneState.tabs.enumerated()), id: \.element.id) { index, tab in
                            tabItemView(tab: tab, index: index)
                        }
                    }
                }
                
                Button(action: { paneState.addTab() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .padding(5)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Path / Address Bar
            HStack(spacing: 6) {
                // Navigation buttons
                HStack(spacing: 2) {
                    Button(action: { paneState.goBack() }) {
                        Image(systemName: "chevron.backward")
                    }
                    .disabled(!paneState.canGoBack)
                    
                    Button(action: { paneState.goForward() }) {
                        Image(systemName: "chevron.forward")
                    }
                    .disabled(!paneState.canGoForward)
                    
                    Button(action: { paneState.goUp() }) {
                        Image(systemName: "chevron.up")
                    }
                    .disabled(!paneState.canGoUp)
                    
                    Button(action: { paneState.refresh() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.plain)
                
                // Path Bar / Breadcrumbs
                if isEditingPath {
                    TextField("Enter path...", text: $editablePath, onCommit: {
                        navigateToEditablePath()
                    })
                    .textFieldStyle(.roundedBorder)
                    
                    Button("Go") {
                        navigateToEditablePath()
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { isEditingPath = false }) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                } else {
                    breadcrumbsBar
                        .onTapGesture(count: 2) {
                            editablePath = paneState.currentURL.path
                            isEditingPath = true
                        }
                }
                
                // Filter search field
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.secondary)
                    TextField("Filter...", text: $paneState.filterQuery)
                        .textFieldStyle(.plain)
                        .frame(width: 90)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
            
            Divider()
            
            // Main File List
            ZStack {
                FileTableView(appState: appState, paneState: paneState)
                
                if paneState.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                }
            }
            
            Divider()
            
            // Bottom Status Bar for Pane
            HStack {
                Text(paneState.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
        .simultaneousGesture(
            TapGesture().onEnded {
                appState.activePaneIndex = paneIndex
            }
        )
    }
    
    // MARK: - Breadcrumbs Bar
    
    private var breadcrumbsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                let segments = pathSegments(for: paneState.currentURL)
                ForEach(segments, id: \.url) { seg in
                    Button(action: {
                        paneState.navigateTo(url: seg.url)
                    }) {
                        HStack(spacing: 2) {
                            Text(seg.name)
                                .font(.system(size: 12))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 3)
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(5)
    }
    
    private struct PathSegment {
        let name: String
        let url: URL
    }
    
    private func pathSegments(for url: URL) -> [PathSegment] {
        var segments: [PathSegment] = []
        var current = url.standardizedFileURL
        
        while current.path != "/" && !current.path.isEmpty {
            segments.insert(PathSegment(name: current.lastPathComponent, url: current), at: 0)
            current = current.deletingLastPathComponent()
        }
        segments.insert(PathSegment(name: "Macintosh HD", url: URL(fileURLWithPath: "/")), at: 0)
        return segments
    }
    
    private func navigateToEditablePath() {
        var path = editablePath.trimmingCharacters(in: .whitespacesAndNewlines)
        if path.hasPrefix("~") {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            path = path.replacingOccurrences(of: "~", with: home, options: [.anchored])
        }
        let targetURL = URL(fileURLWithPath: path)
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: targetURL.path, isDirectory: &isDir) && isDir.boolValue {
            paneState.navigateTo(url: targetURL)
        }
        isEditingPath = false
    }
    
    // MARK: - Tab Item View
    
    @ViewBuilder
    private func tabItemView(tab: TabItem, index: Int) -> some View {
        let isSelected = paneState.activeTabIndex == index
        HStack(spacing: 6) {
            Image(systemName: "folder.fill")
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .font(.caption)
            
            Text(tab.title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .lineLimit(1)
            
            if paneState.tabs.count > 1 {
                Button(action: {
                    paneState.closeTab(at: index)
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(isSelected ? Color(NSColor.controlBackgroundColor) : Color.clear)
        .cornerRadius(6)
        .onTapGesture {
            paneState.selectTab(at: index)
            appState.activePaneIndex = paneIndex
        }
    }
}
