import Foundation

public struct ThreeWayDiffOptions: Sendable, Hashable {
    public var diffOptions: DiffOptions

    public init(
        diffOptions: DiffOptions = DiffOptions()
    ) {
        self.diffOptions = diffOptions
    }
}

public struct ThreeWayDocument: Sendable, Hashable {
    public let identifier: String?
    public let text: String

    public init(
        identifier: String? = nil,
        text: String
    ) {
        self.identifier = identifier
        self.text = text
    }
}
