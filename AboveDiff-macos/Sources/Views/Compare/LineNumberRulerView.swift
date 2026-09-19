import AppKit

public final class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?

    public init(
        textView: NSTextView,
        scrollView: NSScrollView
    ) {
        self.textView = textView

        super.init(
            scrollView: scrollView,
            orientation: .verticalRuler
        )

        clientView = textView
        ruleThickness = 48

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: NSText.didChangeNotification,
            object: textView
        )

        scrollView.contentView.postsBoundsChangedNotifications = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(boundsDidChange),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    private func textDidChange() {
        needsDisplay = true
    }

    @objc
    private func boundsDidChange() {
        needsDisplay = true
    }

    public override func drawHashMarksAndLabels(
        in rect: NSRect
    ) {
        guard
            let textView,
            let layoutManager = textView.layoutManager,
            let textContainer = textView.textContainer
        else {
            return
        }

        let visibleRect = textView.visibleRect

        let glyphRange = layoutManager.glyphRange(
            forBoundingRect: visibleRect,
            in: textContainer
        )

        let characterRange = layoutManager.characterRange(
            forGlyphRange: glyphRange,
            actualGlyphRange: nil
        )

        let nsText = textView.string as NSString

        let firstLine = lineNumber(
            atCharacterIndex: characterRange.location,
            in: nsText
        )

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(
                ofSize: 10,
                weight: .regular
            ),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle
        ]

        var line = firstLine
        var characterIndex = characterRange.location
        let limit = min(
            NSMaxRange(characterRange),
            nsText.length
        )

        while characterIndex < limit {
            let lineRange = nsText.lineRange(
                for: NSRange(
                    location: characterIndex,
                    length: 0
                )
            )

            let glyphIndex = layoutManager.glyphIndexForCharacter(
                at: lineRange.location
            )

            var effectiveRange = NSRange()

            let fragmentRect =
                layoutManager.lineFragmentRect(
                    forGlyphAt: glyphIndex,
                    effectiveRange: &effectiveRange
                )

            let containerOrigin =
                textView.textContainerOrigin

            // Convert document coordinates into the ruler's visible coordinates.
            // Without subtracting visibleRect.minY, line numbers drift downward
            // as the text view scrolls and eventually disappear.
            let y =
                fragmentRect.minY +
                containerOrigin.y -
                visibleRect.minY

            let number = "\(line)" as NSString

            number.draw(
                in: NSRect(
                    x: 2,
                    y: y,
                    width: ruleThickness - 8,
                    height: 16
                ),
                withAttributes: attributes
            )

            line += 1

            let next = NSMaxRange(lineRange)

            if next <= characterIndex {
                break
            }

            characterIndex = next
        }
    }

    private func lineNumber(
        atCharacterIndex index: Int,
        in text: NSString
    ) -> Int {
        guard index > 0 else {
            return 1
        }

        var count = 1
        var position = 0

        while position < index &&
              position < text.length {
            let range = text.lineRange(
                for: NSRange(
                    location: position,
                    length: 0
                )
            )

            let next = NSMaxRange(range)

            if next <= position {
                break
            }

            if next <= index {
                count += 1
            }

            position = next
        }

        return count
    }
}
