import Foundation
import AboveDiffCore

@main
struct AboveDiffCLI {
    static func main() {
        let arguments = Array(
            CommandLine.arguments.dropFirst()
        )

        if arguments == ["--version"] {
            print("abovediff 1.0.0")
            exit(GitMergeToolExitStatus.success.rawValue)
        }

        if arguments.isEmpty ||
           arguments.contains("--help") {
            printHelp()
            exit(GitMergeToolExitStatus.success.rawValue)
        }

        do {
            let parsed = try GitMergeToolArgumentParser.parse(arguments)
            let request = MergeToolSessionRequest(
                arguments: parsed
            )

            let store = try MergeToolSessionStore()
            try store.writeRequest(request)

            print(request.id.uuidString)

            fputs(
                "AboveDiff merge session created. GUI handoff is implemented in P9.4-P9.7.\n",
                stderr
            )

            exit(
                GitMergeToolExitStatus.internalError.rawValue
            )
        } catch let error as GitMergeToolArgumentError {
            fputs(
                "abovediff: \(error.localizedDescription)\n",
                stderr
            )

            exit(
                GitMergeToolExitStatus.invalidArguments.rawValue
            )
        } catch {
            fputs(
                "abovediff: \(error.localizedDescription)\n",
                stderr
            )

            exit(
                GitMergeToolExitStatus.internalError.rawValue
            )
        }
    }

    private static func printHelp() {
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

        Product name: AboveDiff
        Git mergetool name: abovediff
        """)
    }
}
