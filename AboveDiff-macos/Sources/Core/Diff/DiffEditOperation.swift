import Foundation

public enum DiffSide: String, Sendable, Codable {
    case left
    case right
}

public struct DiffEditResult: Sendable, Hashable {
    public let leftText: String
    public let rightText: String

    public init(
        leftText: String,
        rightText: String
    ) {
        self.leftText = leftText
        self.rightText = rightText
    }
}
