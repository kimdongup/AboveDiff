import AppKit
import AboveDiffViews

@MainActor
final class AppLifecycleDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {

        NSApp.setActivationPolicy(.regular)

        MergeToolSessionCoordinator.shared.start()
    }

    func applicationDidBecomeActive(
        _ notification: Notification
    ) {

        MergeToolSessionCoordinator.shared.scanNow()
    }

    func applicationWillTerminate(
        _ notification: Notification
    ) {
        MergeToolSessionCoordinator.shared.stop()
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        MergeToolSessionCoordinator.shared.scanNow()

        if !flag {
            let candidate =
                sender.windows.first {
                    $0.canBecomeMain &&
                    $0.isMiniaturized
                }
                ??
                sender.windows.first {
                    $0.canBecomeMain
                }

            if let window = candidate {
                if window.isMiniaturized {
                    window.deminiaturize(nil)
                }

                window.makeKeyAndOrderFront(nil)
            }
        }

        sender.activate(
            ignoringOtherApps: true
        )

        return true
    }
}
