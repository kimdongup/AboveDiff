import XCTest
@testable import AboveDiffCore

final class GitMergeToolArgumentsTests: XCTestCase {
    func testParseValidArguments() throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let parsed = try GitMergeToolArgumentParser.parse([
            "--mergetool",
            "--base", fixture.base.path,
            "--local", fixture.local.path,
            "--remote", fixture.remote.path,
            "--merged", fixture.merged.path
        ])

        XCTAssertEqual(parsed.baseURL.path, fixture.base.path)
        XCTAssertEqual(parsed.localURL.path, fixture.local.path)
        XCTAssertEqual(parsed.remoteURL.path, fixture.remote.path)
        XCTAssertEqual(parsed.mergedURL.path, fixture.merged.path)
    }

    func testMissingRemote() throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        XCTAssertThrowsError(
            try GitMergeToolArgumentParser.parse([
                "--mergetool",
                "--base", fixture.base.path,
                "--local", fixture.local.path,
                "--merged", fixture.merged.path
            ])
        )
    }

    func testUnicodeAndSpaces() throws {
        let fixture = try Fixture(
            filenamePrefix: "한글 파일 "
        )
        defer { fixture.cleanup() }

        let parsed = try GitMergeToolArgumentParser.parse([
            "--mergetool",
            "--base", fixture.base.path,
            "--local", fixture.local.path,
            "--remote", fixture.remote.path,
            "--merged", fixture.merged.path
        ])

        XCTAssertTrue(
            parsed.baseURL.lastPathComponent.contains("한글 파일")
        )
    }
}

private final class Fixture {
    let root: URL
    let base: URL
    let local: URL
    let remote: URL
    let merged: URL

    init(
        filenamePrefix: String = ""
    ) throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )

        base = root.appendingPathComponent(
            "\(filenamePrefix)base.txt"
        )
        local = root.appendingPathComponent(
            "\(filenamePrefix)local.txt"
        )
        remote = root.appendingPathComponent(
            "\(filenamePrefix)remote.txt"
        )
        merged = root.appendingPathComponent(
            "\(filenamePrefix)merged.txt"
        )

        try "base\n".write(
            to: base,
            atomically: true,
            encoding: .utf8
        )

        try "local\n".write(
            to: local,
            atomically: true,
            encoding: .utf8
        )

        try "remote\n".write(
            to: remote,
            atomically: true,
            encoding: .utf8
        )
    }

    func cleanup() {
        try? FileManager.default.removeItem(
            at: root
        )
    }
}
