import SwiftUI
import AppKit

public struct MergeResultPane: NSViewRepresentable {
    @Binding public var text: String

    public init(
        text: Binding<String>
    ) {
        self._text = text
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text
        )
    }

    public func makeNSView(
        context: Context
    ) -> NSScrollView {
        let scrollView = NSScrollView()

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true

        let textView = NSTextView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: 1000,
                height: 600
            )
        )

        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.usesFindBar = true

        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true

        textView.autoresizingMask = [.width]
        textView.font =
            NSFont.monospacedSystemFont(
                ofSize: 12,
                weight: .regular
            )

        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )

        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.heightTracksTextView = false
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )

        textView.delegate = context.coordinator
        scrollView.documentView = textView
        context.coordinator.textView = textView

        return scrollView
    }

    public func updateNSView(
        _ scrollView: NSScrollView,
        context: Context
    ) {
        guard let textView = context.coordinator.textView else {
            return
        }

        if textView.string != text {
            context.coordinator.isProgrammaticUpdate = true
            textView.string = text
            context.coordinator.isProgrammaticUpdate = false
        }

        if let layoutManager = textView.layoutManager,
           let textContainer = textView.textContainer {
            layoutManager.ensureLayout(for: textContainer)

            let used = layoutManager.usedRect(
                for: textContainer
            )

            textView.setFrameSize(
                NSSize(
                    width: max(
                        scrollView.contentSize.width,
                        used.width + 24
                    ),
                    height: max(
                        scrollView.contentSize.height,
                        used.height + 24
                    )
                )
            )
        }
    }

    public final class Coordinator:
        NSObject,
        NSTextViewDelegate {

        var textView: NSTextView?
        var isProgrammaticUpdate = false
        var text: Binding<String>

        init(
            text: Binding<String>
        ) {
            self.text = text
        }

        public func textDidChange(
            _ notification: Notification
        ) {
            guard !isProgrammaticUpdate,
                  let textView
            else {
                return
            }

            text.wrappedValue = textView.string
        }
    }
}
