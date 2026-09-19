import Foundation

public enum GitRepositoryError: LocalizedError, Sendable, Equatable {
    case notRepository(URL)
    case pathOutsideRepository(URL)
    case invalidStatusOutput

    public var errorDescription: String? {
        switch self {
        case .notRepository(let url):
            return "Not a Git repository: \(url.path)"

        case .pathOutsideRepository(let url):
            return "The selected path is outside the Git repository: \(url.path)"

        case .invalidStatusOutput:
            return "Git returned an invalid status record."
        }
    }
}

public protocol GitRepositoryServicing: Sendable {
    func repositoryRoot(
        for url: URL
    ) throws -> URL?

    func relativePath(
        for url: URL,
        repositoryRoot: URL
    ) throws -> String

    func status(
        repositoryRoot: URL,
        relativePath: String?
    ) throws -> [GitStatusItem]

    func currentBranch(
        repositoryRoot: URL
    ) throws -> String?
}

public final class GitRepositoryService:
    @unchecked Sendable,
    GitRepositoryServicing {

    public static let shared =
        GitRepositoryService()

    private let runner:
        any GitCommandRunning

    public init(
        runner:
            any GitCommandRunning =
                GitCommandRunner.shared
    ) {
        self.runner = runner
    }

    public func repositoryRoot(
        for url: URL
    ) throws -> URL? {
        let directory =
            isDirectory(url)
            ? url
            : url.deletingLastPathComponent()

        let result = try runner.run(
            arguments: [
                "-C",
                directory.path,
                "rev-parse",
                "--show-toplevel"
            ],
            currentDirectory: nil,
            allowFailure: true
        )

        guard result.exitCode == 0 else {
            return nil
        }

        let path = result.stdoutString
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !path.isEmpty else {
            return nil
        }

        return URL(
            fileURLWithPath: path
        ).standardizedFileURL
    }

    public func relativePath(
        for url: URL,
        repositoryRoot: URL
    ) throws -> String {
        let rootPath =
            repositoryRoot
                .standardizedFileURL
                .path

        let filePath =
            url.standardizedFileURL.path

        guard filePath == rootPath ||
              filePath.hasPrefix(
                rootPath + "/"
              )
        else {
            throw GitRepositoryError
                .pathOutsideRepository(url)
        }

        if filePath == rootPath {
            return "."
        }

        return String(
            filePath.dropFirst(
                rootPath.count + 1
            )
        )
    }

    public func status(
        repositoryRoot: URL,
        relativePath: String? = nil
    ) throws -> [GitStatusItem] {
        var arguments = [
            "-C",
            repositoryRoot.path,
            "status",
            "--porcelain=v1",
            "-z"
        ]

        if let relativePath {
            arguments.append("--")
            arguments.append(relativePath)
        }

        let result = try runner.run(
            arguments: arguments,
            currentDirectory: nil,
            allowFailure: false
        )

        return parseStatus(
            data: result.stdout
        )
    }

    public func currentBranch(
        repositoryRoot: URL
    ) throws -> String? {
        let result = try runner.run(
            arguments: [
                "-C",
                repositoryRoot.path,
                "branch",
                "--show-current"
            ],
            currentDirectory: nil,
            allowFailure: false
        )

        let value = result.stdoutString
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return value.isEmpty
            ? nil
            : value
    }

    private func parseStatus(
        data: Data
    ) -> [GitStatusItem] {
        let records = data.split(
            separator: 0
        )

        var output: [GitStatusItem] = []
        var index = 0

        while index < records.count {
            let raw = String(
                data: Data(records[index]),
                encoding: .utf8
            ) ?? ""

            guard raw.count >= 3 else {
                index += 1
                continue
            }

            let chars = Array(raw)
            let x = chars[0]
            let y = chars[1]

            var path = String(
                chars.dropFirst(3)
            )

            if x == "R" || x == "C" {
                if index + 1 < records.count {
                    path = String(
                        data: Data(records[index + 1]),
                        encoding: .utf8
                    ) ?? path

                    index += 1
                }
            }

            let conflicted =
                isConflictCode(x, y)

            output.append(
                GitStatusItem(
                    relativePath: path,
                    indexStatus:
                        mapStatus(x),
                    workTreeStatus:
                        mapStatus(y),
                    isConflicted:
                        conflicted
                )
            )

            index += 1
        }

        return output
    }

    private func mapStatus(
        _ character: Character
    ) -> GitFileStatus {
        switch character {
        case " ":
            return .clean
        case "M":
            return .modified
        case "A":
            return .added
        case "D":
            return .deleted
        case "R":
            return .renamed
        case "?":
            return .untracked
        case "U":
            return .conflicted
        default:
            return .unknown
        }
    }

    private func isConflictCode(
        _ x: Character,
        _ y: Character
    ) -> Bool {
        let code = String([x, y])

        switch code {
        case "DD", "AU", "UD", "UA",
             "DU", "AA", "UU":
            return true
        default:
            return false
        }
    }

    private func isDirectory(
        _ url: URL
    ) -> Bool {
        var isDirectory:
            ObjCBool = false

        guard FileManager.default
            .fileExists(
                atPath: url.path,
                isDirectory:
                    &isDirectory
            )
        else {
            return url.hasDirectoryPath
        }

        return isDirectory.boolValue
    }
}
