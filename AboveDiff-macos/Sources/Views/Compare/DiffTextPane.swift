import SwiftUI
import AppKit
import AboveDiffCore

public struct DiffTextPane: NSViewRepresentable {
    public let text: String
    public let chunks: [DiffChunk]
    public let side: Side
    public let currentChangeID: Int?

    public enum Side {
        case left
        case right
    }

    public init(
        text: String,
        chunks: [DiffChunk],
        side: Side,
        currentChangeID: Int?
    ) {
        self.text = text
        self.chunks = chunks
        self.side = side
        self.currentChangeID = currentChangeID
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.usesFindBar = true
        textView.font = NSFont.monospacedSystemFont(
            ofSize: 12,
            weight: .regular
        )
        textView.textContainerInset = NSSize(width: 8, height: 8)

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView

        context.coordinator.textView = textView
        return scrollView
    }

    public func updateNSView(
        _ scrollView: NSScrollView,
        context: Context
    ) {
        guard let textView = context.coordinator.textView else { return }

        if textView.string != text {
            textView.string = text
        }

        applyHighlights(to: textView)

        if context.coordinator.lastCurrentChangeID != currentChangeID {
            context.coordinator.lastCurrentChangeID = currentChangeID
            scrollToCurrentChange(in: textView)
        }
    }

    private func applyHighlights(to textView: NSTextView) {
        let nsText = textView.string as NSString
        let fullRange = NSRange(
            location: 0,
            length: nsText.length
        )

        textView.textStorage?.setAttributes(
            [
                .font: NSFont.monospacedSystemFont(
                    ofSize: 12,
                    weight: .regular
                ),
                .foregroundColor: NSColor.labelColor
            ],
            range: fullRange
        )

        let lineRanges = Self.characterRangesByLine(
            in: textView.string
        )

        for chunk in chunks where chunk.isChange {
            let lineRange = side == .left
                ? chunk.left.range
                : chunk.right.range

            guard !lineRange.isEmpty else { continue }

            let charRange = Self.characterRange(
                for: lineRange,
                lineRanges: lineRanges
            )

            guard charRange.length > 0 else { continue }

            let color: NSColor
            switch chunk.kind {
            case .equal:
                continue
            case .insert:
                color = .systemGreen
            case .delete:
                color = .systemRed
            case .replace:
                color = .systemYellow
            }

            let alpha: CGFloat =
                chunk.id == currentChangeID ? 0.30 : 0.14

            textView.textStorage?.addAttribute(
                .backgroundColor,
                value: color.withAlphaComponent(alpha),
                range: charRange
            )
        }
    }

    private func scrollToCurrentChange(
        in textView: NSTextView
    ) {
        guard let currentChangeID,
              let chunk = chunks.first(
                where: { $0.id == currentChangeID }
              )
        else {
            return
        }

        let lineRange = side == .left
            ? chunk.left.range
            : chunk.right.range

        guard !lineRange.isEmpty else { return }

        let lineRanges = Self.characterRangesByLine(
            in: textView.string
        )

        let charRange = Self.characterRange(
            for: lineRange,
            lineRanges: lineRanges
        )

        if charRange.length > 0 {
            textView.scrollRangeToVisible(charRange)
        }
    }

    private static func characterRangesByLine(
        in text: String
    ) -> [NSRange] {
        let nsText = text as NSString

        guard nsText.length > 0 else {
            return []
        }

        var ranges: [NSRange] = []
        var location = 0

        while location < nsText.length {
            let range = nsText.lineRange(
                for: NSRange(location: location, length: 0)
            )
            ranges.append(range)
            location = NSMaxRange(range)
        }

        return ranges
    }

    private static func characterRange(
        for lines: Range<Int>,
        lineRanges: [NSRange]
    ) -> NSRange {
        guard !lineRanges.isEmpty,
              lines.lowerBound < lineRanges.count
        else {
            return NSRange(location: 0, length: 0)
        }

        let startIndex = min(
            lines.lowerBound,
            lineRanges.count - 1
        )

        let endExclusive = min(
            lines.upperBound,
            lineRanges.count
        )

        guard endExclusive > startIndex else {
            return NSRange(location: 0, length: 0)
        }

        let first = lineRanges[startIndex]
        let last = lineRanges[endExclusive - 1]

        return NSRange(
            location: first.location,
            length: NSMaxRange(last) - first.location
        )
    }

    public final class Coordinator {
        var textView: NSTextView?
        var lastCurrentChangeID: Int?
    }
}
