import SwiftUI
import AppKit
import AboveDiffCore

@MainActor
public enum GitConflictMergeWindowPresenter {
    public static func open(
        descriptor: GitConflictDescriptor
    ) {
        let key =
            "git-conflict:" +
            descriptor
                .repositoryRoot
                .standardizedFileURL
                .path +
            "::" +
            descriptor.relativePath

        if CompareWindowRegistry.shared
            .presentExisting(
                key: key
            ) {
            return
        }

        let content =
            GitConflictMergeView(
                descriptor:
                    descriptor
            )

        let controller =
            NSHostingController(
                rootView: content
            )

        let window =
            NSWindow(
                contentViewController:
                    controller
            )

        window.title =
            "Resolve Git Conflict — " +
            descriptor.relativePath

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
        window.isReleasedWhenClosed =
            false

        CompareWindowRegistry.shared
            .register(
                window,
                key: key
            )

        NSApp.activate(
            ignoringOtherApps: true
        )

        window.makeKeyAndOrderFront(
            nil
        )
    }
}
