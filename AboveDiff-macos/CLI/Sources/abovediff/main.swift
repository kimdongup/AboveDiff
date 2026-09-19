import Foundation
import AboveDiffCore

let arguments = Array(
    CommandLine.arguments.dropFirst()
)

if arguments == ["--version"] {
    print("abovediff 1.0.0")
    exit(
        GitMergeToolExitStatus
            .success
            .rawValue
    )
}

if arguments.isEmpty ||
   arguments.contains("--help") {
    printHelp()
    exit(
        GitMergeToolExitStatus
            .success
            .rawValue
    )
}

do {
    let parsed =
        try GitMergeToolArgumentParser
        .parse(arguments)

    let request =
        MergeToolSessionRequest(
            arguments: parsed
        )

    let store =
        try MergeToolSessionStore()

    let maintenance =
        MergeToolSessionMaintenance(
            sessionStore: store
        )

    try? maintenance
        .removeStaleSessions()

    try store.writeRequest(
        request
    )

    let environment =
        ProcessInfo
        .processInfo
        .environment

    if environment[
        "ABOVEDIFF_NO_LAUNCH"
    ] == "1" {
        fputs(
            "abovediff: development mode; using already-running AboveDiff\n",
            stderr
        )
    } else {
        try activateAboveDiff(
            explicitAppPath:
                environment[
                    "ABOVEDIFF_APP_PATH"
                ]
        )
    }

    let timeout =
        TimeInterval(
            environment[
                "ABOVEDIFF_SESSION_TIMEOUT"
            ] ?? ""
        )
        ?? 30 * 60

    let result =
        try waitForResult(
            request:
                request,
            store:
                store,
            timeout:
                timeout
        )

    if let message =
        result.message,
       !message.isEmpty {
        fputs(
            "abovediff: \(message)\n",
            stderr
        )
    }

    try? store.removeSession(
        sessionID: request.id
    )

    exit(
        result.exitStatus.rawValue
    )
} catch let error
    as GitMergeToolArgumentError {

    fputs(
        "abovediff: \(error.localizedDescription)\n",
        stderr
    )

    exit(
        GitMergeToolExitStatus
            .invalidArguments
            .rawValue
    )
} catch let error
    as CLIError {

    fputs(
        "abovediff: \(error.localizedDescription)\n",
        stderr
    )

    exit(
        error.exitStatus.rawValue
    )
} catch {
    fputs(
        "abovediff: \(error.localizedDescription)\n",
        stderr
    )

    exit(
        GitMergeToolExitStatus
            .internalError
            .rawValue
    )
}

func activateAboveDiff(
    explicitAppPath: String?
) throws {
    let process = Process()

    process.executableURL = URL(
        fileURLWithPath:
            "/usr/bin/open"
    )

    if let explicitAppPath,
       !explicitAppPath.isEmpty {
        guard FileManager
            .default
            .fileExists(
                atPath:
                    explicitAppPath
            )
        else {
            throw CLIError
                .appNotFound(
                    explicitAppPath
                )
        }

        process.arguments = [
            "-a",
            explicitAppPath
        ]
    } else {
        let defaultPath =
            "/Applications/AboveDiff.app"

        guard FileManager
            .default
            .fileExists(
                atPath:
                    defaultPath
            )
        else {
            throw CLIError
                .appNotFound(
                    defaultPath
                )
        }

        process.arguments = [
            "-a",
            defaultPath
        ]
    }

    try process.run()
    process.waitUntilExit()

    guard process
        .terminationStatus == 0
    else {
        throw CLIError
            .appLaunchFailed(
                process
                    .terminationStatus
            )
    }
}

func waitForResult(
    request:
        MergeToolSessionRequest,
    store:
        MergeToolSessionStore,
    timeout: TimeInterval
) throws -> MergeToolSessionResult {
    let started = Date()

    while true {
        if FileManager
            .default
            .fileExists(
                atPath:
                    store
                    .resultURL(
                        for:
                            request.id
                    )
                    .path
            ) {
            return try store
                .readResult(
                    sessionID:
                        request.id
                )
        }

        if Date()
            .timeIntervalSince(
                started
            ) >= timeout {
            try? store
                .removeSession(
                    sessionID:
                        request.id
                )

            throw CLIError
                .sessionTimedOut(
                    timeout
                )
        }

        Thread.sleep(
            forTimeInterval:
                0.2
        )
    }
}

func printHelp() {
    print("""
    AboveDiff CLI

    Usage:
      abovediff --version
      abovediff --help

      abovediff --mergetool \\
        --base <path> \\
        --local <path> \\
        --remote <path> \\
        --merged <path>

    Environment:
      ABOVEDIFF_NO_LAUNCH=1
      ABOVEDIFF_APP_PATH=/path/to/AboveDiff.app
      ABOVEDIFF_SESSION_TIMEOUT=seconds

    Production:
      /Applications/AboveDiff.app
      /usr/local/bin/abovediff
    """)
}

enum CLIError:
    LocalizedError {

    case appNotFound(String)
    case appLaunchFailed(Int32)
    case sessionTimedOut(
        TimeInterval
    )

    var exitStatus:
        GitMergeToolExitStatus {
        switch self {
        case .appNotFound,
             .appLaunchFailed:
            return .internalError
        case .sessionTimedOut:
            return .internalError
        }
    }

    var errorDescription:
        String? {
        switch self {
        case .appNotFound(
            let path
        ):
            return
                "AboveDiff.app was not found at \(path). Reinstall or repair Git integration."

        case .appLaunchFailed(
            let status
        ):
            return
                "Unable to launch AboveDiff (open exit \(status))."

        case .sessionTimedOut(
            let timeout
        ):
            return
                "Merge session timed out after \(Int(timeout)) seconds."
        }
    }
}
