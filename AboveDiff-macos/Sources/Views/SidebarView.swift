import SwiftUI
import AboveDiffCore
import AboveDiffLocalization
import AboveDiffState

@MainActor
public struct SidebarView: View {
    @ObservedObject var appState: AppState
    @State private var volumes: [VolumeItem] = []
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        List {
            // Favorites Section
            Section(L10n("sidebar.favorites")) {
                sidebarRow(title: L10n("sidebar.home"), icon: "house.fill", url: FileManager.default.homeDirectoryForCurrentUser)
                
                if let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
                    sidebarRow(title: L10n("sidebar.desktop"), icon: "desktopcomputer", url: desktop)
                }
                
                if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    sidebarRow(title: L10n("sidebar.documents"), icon: "doc.text.fill", url: docs)
                }
                
                if let dl = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
                    sidebarRow(title: L10n("sidebar.downloads"), icon: "arrow.down.circle.fill", url: dl)
                }
                
                if let apps = FileManager.default.urls(for: .applicationDirectory, in: .systemDomainMask).first {
                    sidebarRow(title: L10n("sidebar.applications"), icon: "app.badge.fill", url: apps)
                }
                
                if let pics = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first {
                    sidebarRow(title: L10n("sidebar.pictures"), icon: "photo.fill", url: pics)
                }
                
                if let music = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first {
                    sidebarRow(title: L10n("sidebar.music"), icon: "music.note", url: music)
                }
                
                if let movies = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first {
                    sidebarRow(title: L10n("sidebar.movies"), icon: "film.fill", url: movies)
                }
                
                if let trash = FileManager.default.urls(for: .trashDirectory, in: .userDomainMask).first {
                    sidebarRow(title: L10n("sidebar.trash"), icon: "trash.fill", url: trash)
                }
            }
            
            // Volumes Section
            Section(L10n("sidebar.volumes")) {
                ForEach(volumes) { vol in
                    Button(action: {
                        appState.activePane.navigateTo(url: vol.url)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: vol.isRemovable ? "externaldrive.fill" : "internaldrive.fill")
                                .foregroundColor(.accentColor)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(vol.name)
                                    .font(.system(size: 13))
                                    .lineLimit(1)
                                
                                Text("\(vol.formattedFreeSpace) free")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Bookmarks Section
            Section(L10n("sidebar.bookmarks")) {
                ForEach(appState.bookmarks) { bookmark in
                    HStack {
                        Button(action: {
                            appState.activePane.navigateTo(url: bookmark.url)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "bookmark.fill")
                                    .foregroundColor(.orange)
                                    .frame(width: 20)
                                
                                Text(bookmark.name)
                                    .font(.system(size: 13))
                                    .lineLimit(1)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .contextMenu {
                        Button("Remove Bookmark", role: .destructive) {
                            appState.removeBookmark(id: bookmark.id)
                        }
                    }
                }
                
                Button(action: {
                    let active = appState.activePane
                    appState.addBookmark(name: active.currentTab.title, url: active.currentURL)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.caption)
                        Text(L10n("sidebar.add_bookmark"))
                            .font(.caption)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 2)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180, idealWidth: 200, maxWidth: 260)
        .onAppear {
            self.volumes = FileSystemService.shared.listVolumes()
        }
    }
    
    @ViewBuilder
    private func sidebarRow(title: String, icon: String, url: URL) -> some View {
        Button(action: {
            appState.activePane.navigateTo(url: url)
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
