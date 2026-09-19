import XCTest
@testable import AboveDiffCore

final class TextDocumentServiceTests:
    XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError()
        throws {
        tempDirectory =
            FileManager.default
                .temporaryDirectory
                .appendingPathComponent(
                    "abovediff_textdoc_\(UUID().uuidString)"
                )

        try FileManager.default
            .createDirectory(
                at: tempDirectory,
                withIntermediateDirectories:
                    true
            )
    }

    override func tearDownWithError()
        throws {
        try? FileManager.default
            .removeItem(
                at: tempDirectory
            )
    }

    func testUTF8LoadSave()
        throws {
        let url =
            tempDirectory
                .appendingPathComponent(
                    "test.txt"
                )

        try "hello"
            .write(
                to: url,
                atomically: true,
                encoding: .utf8
            )

        let service =
            TextDocumentService()

        let loaded =
            try service.load(
                url: url
            )

        XCTAssertEqual(
            loaded.text,
            "hello"
        )

        XCTAssertEqual(
            loaded.encoding,
            .utf8
        )

        try service.save(
            text: "changed",
            to: url,
            encoding: .utf8
        )

        let final =
            try String(
                contentsOf: url,
                encoding: .utf8
            )

        XCTAssertEqual(
            final,
            "changed"
        )
    }
}
