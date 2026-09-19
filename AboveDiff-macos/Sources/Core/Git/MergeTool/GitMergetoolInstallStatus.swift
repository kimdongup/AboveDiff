import Foundation

public struct GitMergetoolInstallStatus: Sendable, Hashable {
    public let cliPath: String?
    public let appInstalled: Bool
    public let mergeToolName: String?
    public let configuredCommand: String?
    public let trustExitCode: Bool?

    public init(
        cliPath: String?,
        appInstalled: Bool,
        mergeToolName: String?,
        configuredCommand: String?,
        trustExitCode: Bool?
    ) {
        self.cliPath = cliPath
        self.appInstalled = appInstalled
        self.mergeToolName = mergeToolName
        self.configuredCommand = configuredCommand
        self.trustExitCode = trustExitCode
    }

    public var isFullyConfigured: Bool {
        cliPath != nil &&
        appInstalled &&
        mergeToolName == "abovediff" &&
        configuredCommand?.contains("abovediff --mergetool") == true &&
        trustExitCode == true
    }
}

public struct GitMergetoolStatusService: Sendable {
    private let configService: GitMergetoolConfigurationService

    public init(
        configService: GitMergetoolConfigurationService =
            GitMergetoolConfigurationService()
    ) {
        self.configService = configService
    }

    public func inspect(
        appPath: String = "/Applications/AboveDiff.app"
    ) throws -> GitMergetoolInstallStatus {
        let cliPath = Self.findExecutable(
            named: "abovediff"
        )

        let appInstalled =
            FileManager.default.fileExists(
                atPath: appPath
            )

        return GitMergetoolInstallStatus(
            cliPath: cliPath,
            appInstalled: appInstalled,
            mergeToolName:
                try configService.currentTool(),
            configuredCommand:
                try configService.configuredCommand(),
            trustExitCode:
                try configService.configuredTrustExitCode()
        )
    }

    private static func findExecutable(
        named name: String
    ) -> String? {
        let process = Process()
        process.executableURL = URL(
            fileURLWithPath: "/usr/bin/env"
        )
        process.arguments = ["which", name]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else {
            return nil
        }

        let data = pipe.fileHandleForReading
            .readDataToEndOfFile()

        let path = String(
            data: data,
            encoding: .utf8
        )?
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard let path,
              !path.isEmpty
        else {
            return nil
        }

        return path
    }
}
