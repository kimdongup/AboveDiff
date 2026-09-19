import Foundation

public struct GitMergetoolConfiguration: Sendable, Hashable {
    public let toolName: String
    public let command: String
    public let trustExitCode: Bool

    public init(
        toolName: String = "abovediff",
        command: String = #"abovediff --mergetool --base "$BASE" --local "$LOCAL" --remote "$REMOTE" --merged "$MERGED""#,
        trustExitCode: Bool = true
    ) {
        self.toolName = toolName
        self.command = command
        self.trustExitCode = trustExitCode
    }
}

public struct GitMergetoolConfigurationService: Sendable {
    private let runner: any GitCommandRunning

    public init(
        runner: any GitCommandRunning = GitCommandRunner.shared
    ) {
        self.runner = runner
    }

    public func installGlobal(
        configuration: GitMergetoolConfiguration = GitMergetoolConfiguration()
    ) throws {
        _ = try runner.run(
            arguments: [
                "config",
                "--global",
                "merge.tool",
                configuration.toolName
            ],
            currentDirectory: nil,
            allowFailure: false
        )

        _ = try runner.run(
            arguments: [
                "config",
                "--global",
                "mergetool.\(configuration.toolName).cmd",
                configuration.command
            ],
            currentDirectory: nil,
            allowFailure: false
        )

        _ = try runner.run(
            arguments: [
                "config",
                "--global",
                "mergetool.\(configuration.toolName).trustExitCode",
                configuration.trustExitCode ? "true" : "false"
            ],
            currentDirectory: nil,
            allowFailure: false
        )
    }

    public func currentTool() throws -> String? {
        let result = try runner.run(
            arguments: [
                "config",
                "--global",
                "--get",
                "merge.tool"
            ],
            currentDirectory: nil,
            allowFailure: true
        )

        guard result.exitCode == 0 else {
            return nil
        }

        let value = result.stdoutString.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return value.isEmpty ? nil : value
    }

    public func configuredCommand(
        toolName: String = "abovediff"
    ) throws -> String? {
        let result = try runner.run(
            arguments: [
                "config",
                "--global",
                "--get",
                "mergetool.\(toolName).cmd"
            ],
            currentDirectory: nil,
            allowFailure: true
        )

        guard result.exitCode == 0 else {
            return nil
        }

        let value = result.stdoutString.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return value.isEmpty ? nil : value
    }

    public func configuredTrustExitCode(
        toolName: String = "abovediff"
    ) throws -> Bool? {
        let result = try runner.run(
            arguments: [
                "config",
                "--global",
                "--get",
                "mergetool.\(toolName).trustExitCode"
            ],
            currentDirectory: nil,
            allowFailure: true
        )

        guard result.exitCode == 0 else {
            return nil
        }

        let value = result.stdoutString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch value {
        case "true", "yes", "on", "1":
            return true
        case "false", "no", "off", "0":
            return false
        default:
            return nil
        }
    }
}
