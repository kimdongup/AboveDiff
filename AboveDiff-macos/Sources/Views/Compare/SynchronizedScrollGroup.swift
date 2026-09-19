import AppKit

@MainActor
public final class SynchronizedScrollGroup {
    private final class WeakScrollView {
        weak var value: NSScrollView?

        init(_ value: NSScrollView) {
            self.value = value
        }
    }

    private var scrollViews: [WeakScrollView] = []
    private var observers: [ObjectIdentifier: NSObjectProtocol] = [:]
    private var isSynchronizing = false

    public init() {}

    deinit {
        for observer in observers.values {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    public func register(_ scrollView: NSScrollView) {
        cleanup()

        if scrollViews.contains(
            where: { $0.value === scrollView }
        ) {
            return
        }

        scrollViews.append(
            WeakScrollView(scrollView)
        )

        let clipView = scrollView.contentView
        clipView.postsBoundsChangedNotifications = true

        let identifier = ObjectIdentifier(scrollView)

        let observer = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: clipView,
            queue: .main
        ) { [weak self, weak scrollView] _ in
            guard let self,
                  let scrollView
            else {
                return
            }

            Task { @MainActor in
                self.synchronize(from: scrollView)
            }
        }

        observers[identifier] = observer
    }

    public func unregister(_ scrollView: NSScrollView) {
        let identifier = ObjectIdentifier(scrollView)

        if let observer = observers.removeValue(
            forKey: identifier
        ) {
            NotificationCenter.default.removeObserver(observer)
        }

        scrollViews.removeAll {
            $0.value == nil ||
            $0.value === scrollView
        }
    }

    private func synchronize(
        from source: NSScrollView
    ) {
        guard !isSynchronizing else {
            return
        }

        cleanup()

        let sourceClip = source.contentView
        let sourceDocumentHeight =
            source.documentView?.bounds.height ?? 0

        let sourceViewportHeight =
            sourceClip.bounds.height

        let sourceScrollableHeight =
            max(
                0,
                sourceDocumentHeight - sourceViewportHeight
            )

        let ratio: CGFloat
        if sourceScrollableHeight > 0 {
            ratio = min(
                1,
                max(
                    0,
                    sourceClip.bounds.origin.y /
                    sourceScrollableHeight
                )
            )
        } else {
            ratio = 0
        }

        isSynchronizing = true
        defer {
            isSynchronizing = false
        }

        for weakView in scrollViews {
            guard let target = weakView.value,
                  target !== source
            else {
                continue
            }

            let targetClip = target.contentView
            let targetDocumentHeight =
                target.documentView?.bounds.height ?? 0

            let targetScrollableHeight =
                max(
                    0,
                    targetDocumentHeight -
                    targetClip.bounds.height
                )

            let targetY =
                ratio * targetScrollableHeight

            let current = targetClip.bounds.origin

            targetClip.scroll(
                to: NSPoint(
                    x: current.x,
                    y: targetY
                )
            )

            target.reflectScrolledClipView(
                targetClip
            )
        }
    }

    private func cleanup() {
        let liveIdentifiers = Set(
            scrollViews.compactMap {
                $0.value.map(
                    ObjectIdentifier.init
                )
            }
        )

        let stale = observers.keys.filter {
            !liveIdentifiers.contains($0)
        }

        for identifier in stale {
            if let observer = observers.removeValue(
                forKey: identifier
            ) {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        scrollViews.removeAll {
            $0.value == nil
        }
    }
}
