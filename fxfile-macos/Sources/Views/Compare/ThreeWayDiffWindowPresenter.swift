import SwiftUI
import AppKit

@MainActor
public enum ThreeWayDiffWindowPresenter {
    public static func open(
        localURL: URL,
        baseURL: URL,
        remoteURL: URL
    ) {
        let key =
            "three-way-diff:" +
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

        let content = ThreeWayDiffView(
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

        window.title = "Three-Way Compare"
        window.setContentSize(
            NSSize(
                width: 1320,
                height: 820
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
