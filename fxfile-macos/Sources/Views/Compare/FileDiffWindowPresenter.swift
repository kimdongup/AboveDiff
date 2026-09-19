import SwiftUI
import AppKit

@MainActor
public enum FileDiffWindowPresenter {
    public static func open(
        leftURL: URL,
        rightURL: URL
    ) {
        let key =
            "file-diff:" +
            leftURL.standardizedFileURL.path +
            "::" +
            rightURL.standardizedFileURL.path

        if CompareWindowRegistry.shared
            .presentExisting(
                key: key
            ) {
            return
        }

        let content = FileDiffView(
            leftURL: leftURL,
            rightURL: rightURL
        )

        let controller = NSHostingController(
            rootView: content
        )

        let window = NSWindow(
            contentViewController: controller
        )

        window.title =
            "\(leftURL.lastPathComponent) ↔ \(rightURL.lastPathComponent)"

        window.setContentSize(
            NSSize(
                width: 1180,
                height: 760
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
