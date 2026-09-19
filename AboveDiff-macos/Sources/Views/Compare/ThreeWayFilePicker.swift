import AppKit
import Foundation

@MainActor
public enum ThreeWayFilePicker {
    public struct Selection {
        public let localURL: URL
        public let baseURL: URL
        public let remoteURL: URL

        public init(
            localURL: URL,
            baseURL: URL,
            remoteURL: URL
        ) {
            self.localURL = localURL
            self.baseURL = baseURL
            self.remoteURL = remoteURL
        }
    }

    public static func selectFiles(
        title: String
    ) -> Selection? {
        guard let local = chooseFile(
            title: "\(title) — Select LOCAL file"
        ) else {
            return nil
        }

        guard let base = chooseFile(
            title: "\(title) — Select BASE file"
        ) else {
            return nil
        }

        guard let remote = chooseFile(
            title: "\(title) — Select REMOTE file"
        ) else {
            return nil
        }

        return Selection(
            localURL: local,
            baseURL: base,
            remoteURL: remote
        )
    }

    private static func chooseFile(
        title: String
    ) -> URL? {
        let panel = NSOpenPanel()

        panel.title = title
        panel.prompt = "Select"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.resolvesAliases = true

        guard panel.runModal() == .OK else {
            return nil
        }

        return panel.url
    }
}
