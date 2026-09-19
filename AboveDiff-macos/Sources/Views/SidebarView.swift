import SwiftUI
import AppKit
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
                
                ForEach(appState.favorites) { favorite in
                    sidebarRow(title: favorite.name, icon: "folder.fill", url: favorite.url)
                        .contextMenu {
                            Button(L10n("sidebar.remove_favorite"), role: .destructive) {
                                appState.removeFavorite(id: favorite.id)
                            }
                        }
                }
                
                Button(action: addCurrentToFavorites) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.caption)
                        Text(L10n("sidebar.add_favorite"))
                            .font(.caption)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 2)
                .disabled(isCurrentLocationFavorite)
            }
            
            Section(L10n("sidebar.locations")) {
                sidebarRow(
                    title: Host.current().localizedName ?? L10n("sidebar.computer"),
                    icon: "desktopcomputer",
                    url: URL(fileURLWithPath: "/Volumes")
                )
                
                ForEach(volumes) { vol in
                    Button(action: {
                        appState.activePane.navigateTo(url: vol.url)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: vol.systemImageName)
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
                
                Button(action: openNetworkLocation) {
                    HStack(spacing: 8) {
                        Image(systemName: "network")
                            .foregroundColor(.accentColor)
                            .frame(width: 20)
                        
                        Text(L10n("sidebar.network"))
                            .font(.system(size: 13))
                            .lineLimit(1)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180, idealWidth: 200, maxWidth: 260)
        .onAppear(perform: reloadLocations)
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didMountNotification)) { _ in
            reloadLocations()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didUnmountNotification)) { _ in
            reloadLocations()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didRenameVolumeNotification)) { _ in
            reloadLocations()
        }
    }
    
    private var isCurrentLocationFavorite: Bool {
        isFavorite(url: appState.activePane.currentURL)
    }
    
    private func addCurrentToFavorites() {
        let active = appState.activePane
        guard !isFavorite(url: active.currentURL) else { return }
        appState.addFavorite(name: active.currentTab.title, url: active.currentURL)
    }
    
    private func isFavorite(url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        if builtInFavoritePaths.contains(path) { return true }
        return appState.favorites.contains { $0.url.standardizedFileURL.path == path }
    }
    
    private var builtInFavoritePaths: Set<String> {
        var paths: [String] = [FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path]
        let userDirs: [FileManager.SearchPathDirectory] = [
            .desktopDirectory, .documentDirectory, .downloadsDirectory,
            .picturesDirectory, .musicDirectory, .moviesDirectory, .trashDirectory
        ]
        for dir in userDirs {
            if let url = FileManager.default.urls(for: dir, in: .userDomainMask).first {
                paths.append(url.standardizedFileURL.path)
            }
        }
        if let apps = FileManager.default.urls(for: .applicationDirectory, in: .systemDomainMask).first {
            paths.append(apps.standardizedFileURL.path)
        }
        return Set(paths)
    }
    
    private func reloadLocations() {
        volumes = FileSystemService.shared.listVolumes()
    }
    
    private func openNetworkLocation() {
        let networkURL = URL(fileURLWithPath: "/Network")
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: networkURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
            appState.activePane.navigateTo(url: networkURL)
            return
        }
        if let nodeURL = URL(string: "nwnode://") {
            NSWorkspace.shared.open(nodeURL)
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
