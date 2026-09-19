import AppKit
import Foundation

@MainActor
public final class CompareWindowRegistry {
    public static let shared = CompareWindowRegistry()

    private var windows: [String: NSWindow] = [:]

    private init() {}

    public func existingWindow(
        for key: String
    ) -> NSWindow? {
        cleanup()
        return windows[key]
    }

    public func register(
        _ window: NSWindow,
        key: String
    ) {
        cleanup()

        windows[key] = window

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self, weak window] _ in
            guard let self,
                  let window
            else {
                return
            }

            Task { @MainActor in
                if self.windows[key] === window {
                    self.windows.removeValue(
                        forKey: key
                    )
                }
            }
        }
    }

    public func presentExisting(
        key: String
    ) -> Bool {
        guard let window = existingWindow(
            for: key
        ) else {
            return false
        }

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        NSApp.activate(
            ignoringOtherApps: true
        )

        window.makeKeyAndOrderFront(nil)
        return true
    }

    private func cleanup() {
        windows = windows.filter {
            $0.value.isVisible ||
            $0.value.isMiniaturized
        }
    }
}
