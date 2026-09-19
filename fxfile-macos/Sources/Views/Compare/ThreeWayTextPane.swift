import SwiftUI
import AppKit
import fxfileCore

public struct ThreeWayTextPane: NSViewRepresentable {
    public enum Side {
        case local
        case base
        case remote
    }

    public let text: String
    public let chunks: [ThreeWayDiffChunk]
    public let side: Side
    public let currentChunkID: Int?
    public let scrollGroup: SynchronizedScrollGroup?

    public init(
        text: String,
        chunks: [ThreeWayDiffChunk],
        side: Side,
        currentChunkID: Int?,
        scrollGroup: SynchronizedScrollGroup? = nil
    ) {
        self.text = text
        self.chunks = chunks
        self.side = side
        self.currentChunkID = currentChunkID
        self.scrollGroup = scrollGroup
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true

        let textView = NSTextView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: 500,
                height: 900
            )
        )

        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]
        textView.font = NSFont.monospacedSystemFont(
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

        scrollView.documentView = textView

        scrollView.verticalRulerView = LineNumberRulerView(
            textView: textView,
            scrollView: scrollView
        )

        context.coordinator.textView = textView
        context.coordinator.scrollGroup = scrollGroup

        scrollGroup?.register(scrollView)

        return scrollView
    }

    public func updateNSView(
        _ scrollView: NSScrollView,
        context: Context
    ) {
        if context.coordinator.scrollGroup !== scrollGroup {
            context.coordinator.scrollGroup?.unregister(scrollView)
            context.coordinator.scrollGroup = scrollGroup
            scrollGroup?.register(scrollView)
        }

        guard let textView = context.coordinator.textView else {
            return
        }

        if textView.string != text {
            textView.string = text
        }

        applyHighlights(to: textView)

        if context.coordinator.lastCurrentChunkID != currentChunkID {
            context.coordinator.lastCurrentChunkID = currentChunkID
            scrollToCurrentChunk(in: textView)
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

        scrollView.verticalRulerView?.needsDisplay = true
    }

    public static func dismantleNSView(
        _ scrollView: NSScrollView,
        coordinator: Coordinator
    ) {
        coordinator.scrollGroup?.unregister(scrollView)
    }

    private func applyHighlights(
        to textView: NSTextView
    ) {
        let ns = textView.string as NSString

        let full = NSRange(
            location: 0,
            length: ns.length
        )

        textView.textStorage?.setAttributes(
            [
                .font: NSFont.monospacedSystemFont(
                    ofSize: 12,
                    weight: .regular
                ),
                .foregroundColor: NSColor.labelColor
            ],
            range: full
        )

        let lineRanges = characterRangesByLine(
            in: textView.string
        )

        for chunk in chunks where chunk.isChange {
            let range: Range<Int>

            switch side {
            case .local:
                range = chunk.local.range
            case .base:
                range = chunk.base.range
            case .remote:
                range = chunk.remote.range
            }

            guard !range.isEmpty else {
                continue
            }

            let charRange = characterRange(
                for: range,
                lineRanges: lineRanges
            )

            guard charRange.length > 0 else {
                continue
            }

            let color: NSColor

            switch chunk.kind {
            case .equal:
                continue
            case .localOnly:
                color = .systemBlue
            case .remoteOnly:
                color = .systemPurple
            case .sameChange:
                color = .systemGreen
            case .conflict:
                color = .systemRed
            }

            let alpha: CGFloat =
                chunk.id == currentChunkID
                ? 0.32
                : 0.14

            textView.textStorage?.addAttribute(
                .backgroundColor,
                value: color.withAlphaComponent(alpha),
                range: charRange
            )
        }
    }

    private func scrollToCurrentChunk(
        in textView: NSTextView
    ) {
        guard let currentChunkID,
              let chunk = chunks.first(
                where: { $0.id == currentChunkID }
              )
        else {
            return
        }

        let range: Range<Int>

        switch side {
        case .local:
            range = chunk.local.range
        case .base:
            range = chunk.base.range
        case .remote:
            range = chunk.remote.range
        }

        let charRange = characterRange(
            for: range,
            lineRanges: characterRangesByLine(
                in: textView.string
            )
        )

        if charRange.length > 0 {
            textView.scrollRangeToVisible(charRange)
        }
    }

    private func characterRangesByLine(
        in text: String
    ) -> [NSRange] {
        let ns = text as NSString

        guard ns.length > 0 else {
            return []
        }

        var result: [NSRange] = []
        var location = 0

        while location < ns.length {
            let range = ns.lineRange(
                for: NSRange(
                    location: location,
                    length: 0
                )
            )

            result.append(range)
            location = NSMaxRange(range)
        }

        return result
    }

    private func characterRange(
        for lines: Range<Int>,
        lineRanges: [NSRange]
    ) -> NSRange {
        guard !lines.isEmpty,
              !lineRanges.isEmpty,
              lines.lowerBound < lineRanges.count
        else {
            return NSRange(location: 0, length: 0)
        }

        let lower = min(
            lines.lowerBound,
            lineRanges.count - 1
        )

        let upperExclusive = min(
            lines.upperBound,
            lineRanges.count
        )

        guard upperExclusive > lower else {
            return NSRange(location: 0, length: 0)
        }

        let first = lineRanges[lower]
        let last = lineRanges[upperExclusive - 1]

        return NSRange(
            location: first.location,
            length: NSMaxRange(last) - first.location
        )
    }

    public final class Coordinator {
        var textView: NSTextView?
        var scrollGroup: SynchronizedScrollGroup?
        var lastCurrentChunkID: Int?
    }
}
