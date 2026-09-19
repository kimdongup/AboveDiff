import SwiftUI
import AppKit
import AboveDiffCore

@MainActor
public enum ExternalMergeToolWindowPresenter {
    public static func open(
        request: MergeToolSessionRequest,
        sessionStore: MergeToolSessionStore,
        onClose: @escaping () -> Void
    ) {
        let holder = WindowHolder()

        let content = ExternalMergeToolView(
            request: request,
            sessionStore: sessionStore
        ) {
            holder.window?.close()
        }

        let controller = NSHostingController(
            rootView: content
        )

        let window = NSWindow(
            contentViewController: controller
        )

        holder.window = window

        let delegate = SessionWindowDelegate(
            request: request,
            sessionStore: sessionStore,
            onClose: onClose
        )

        holder.delegate = delegate
        window.delegate = delegate

        window.title =
            "AboveDiff Git Merge — " +
            request.arguments.mergedURL.lastPathComponent

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

        objc_setAssociatedObject(
            window,
            &AssociatedKeys.holder,
            holder,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        NSApp.activate(
            ignoringOtherApps: true
        )

        window.makeKeyAndOrderFront(nil)
    }

    private final class WindowHolder {
        weak var window: NSWindow?
        var delegate: SessionWindowDelegate?
    }

    private final class SessionWindowDelegate:
        NSObject,
        NSWindowDelegate {

        private let request: MergeToolSessionRequest
        private let sessionStore: MergeToolSessionStore
        private let onClose: () -> Void

        init(
            request: MergeToolSessionRequest,
            sessionStore: MergeToolSessionStore,
            onClose: @escaping () -> Void
        ) {
            self.request = request
            self.sessionStore = sessionStore
            self.onClose = onClose
        }

        func windowWillClose(
            _ notification: Notification
        ) {
            if !FileManager.default.fileExists(
                atPath: sessionStore
                    .resultURL(for: request.id)
                    .path
            ) {
                try? sessionStore.writeResult(
                    MergeToolSessionResult(
                        sessionID: request.id,
                        outcome: .cancelled,
                        exitStatus: .cancelled,
                        message: "Merge window closed by user."
                    )
                )
            }

            onClose()
        }
    }

    private enum AssociatedKeys {
        static var holder: UInt8 = 0
    }
}
