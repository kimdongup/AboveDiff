import SwiftUI
import AppKit

@MainActor
public enum ThreeWayMergeWindowPresenter {
    public static func open(
        localURL: URL,
        baseURL: URL,
        remoteURL: URL
    ) {
        let key =
            "three-way-merge:" +
            localURL.standardizedFileURL.path +
            "::" +
            baseURL.standardizedFileURL.path +
            "::" +
            remoteURL.standardizedFileURL.path

        if CompareWindowRegistry.shared
            .presentExisting(
                key: key
            ) {
            return
        }

        let content = ThreeWayMergeView(
            localURL: localURL,
            baseURL: baseURL,
            remoteURL: remoteURL
        )

        let controller = NSHostingController(
            rootView: content
        )

        let window = NSWindow(
            contentViewController: controller
        )

        window.title = "Three-Way Merge"

        window.setContentSize(
            NSSize(
                width: 1380,
                height: 900
            )
        )

        window.styleMask = [
            .titled,
            .closable,
            .miniaturizable,
            .resizable
        ]

        window.center()
        window.isReleasedWhenClosed = false

        CompareWindowRegistry.shared
            .register(
                window,
                key: key
            )

        NSApp.activate(
            ignoringOtherApps: true
        )

        window.makeKeyAndOrderFront(nil)
    }
}
