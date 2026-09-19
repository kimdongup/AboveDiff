import Foundation

public struct GitCommandResult: Sendable, Hashable {
    public let exitCode: Int32
    public let stdout: Data
    public let stderr: Data

    public init(
        exitCode: Int32,
        stdout: Data,
        stderr: Data
    ) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
    }

    public var stdoutString: String {
        String(data: stdout, encoding: .utf8) ?? ""
    }

    public var stderrString: String {
        String(data: stderr, encoding: .utf8) ?? ""
    }
}

public enum GitCommandError: LocalizedError, Sendable, Equatable {
    case gitNotFound
    case launchFailed(String)
    case commandFailed(
        arguments: [String],
        exitCode: Int32,
        stderr: String
    )

    public var errorDescription: String? {
        switch self {
        case .gitNotFound:
            return "Git executable was not found."

        case .launchFailed(let message):
            return "Failed to launch Git: \(message)"

        case .commandFailed(
            let arguments,
            let exitCode,
            let stderr
        ):
            let command = (["git"] + arguments)
                .joined(separator: " ")

            let detail = stderr
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            if detail.isEmpty {
                return "\(command) failed with exit code \(exitCode)."
            }

            return "\(command) failed with exit code \(exitCode): \(detail)"
        }
    }
}

public protocol GitCommandRunning: Sendable {
    func run(
        arguments: [String],
        currentDirectory: URL?,
        allowFailure: Bool
    ) throws -> GitCommandResult
}

public final class GitCommandRunner:
    @unchecked Sendable,
    GitCommandRunning {

    public static let shared = GitCommandRunner()

    private let executableURL: URL

    public init(
        executableURL: URL = URL(
            fileURLWithPath: "/usr/bin/git"
        )
    ) {
        self.executableURL = executableURL
    }

    public func run(
        arguments: [String],
        currentDirectory: URL? = nil,
        allowFailure: Bool = false
    ) throws -> GitCommandResult {
        if Task.isCancelled {
            throw CancellationError()
        }

        guard FileManager.default
            .isExecutableFile(
                atPath: executableURL.path
            )
        else {
            throw GitCommandError.gitNotFound
        }

        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        if let currentDirectory {
            process.currentDirectoryURL =
                currentDirectory
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            throw GitCommandError.launchFailed(
                error.localizedDescription
            )
        }

        process.waitUntilExit()

        let stdout = stdoutPipe
            .fileHandleForReading
            .readDataToEndOfFile()

        let stderr = stderrPipe
            .fileHandleForReading
            .readDataToEndOfFile()

        if Task.isCancelled {
            throw CancellationError()
        }

        let result = GitCommandResult(
            exitCode: process.terminationStatus,
            stdout: stdout,
            stderr: stderr
        )

        if !allowFailure,
           result.exitCode != 0 {
            throw GitCommandError.commandFailed(
                arguments: arguments,
                exitCode: result.exitCode,
                stderr: result.stderrString
            )
        }

        return result
    }
}
