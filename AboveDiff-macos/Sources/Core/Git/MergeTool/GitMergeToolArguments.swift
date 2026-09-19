import Foundation

public struct GitMergeToolArguments: Sendable, Hashable, Codable {
    public let baseURL: URL
    public let localURL: URL
    public let remoteURL: URL
    public let mergedURL: URL

    public init(
        baseURL: URL,
        localURL: URL,
        remoteURL: URL,
        mergedURL: URL
    ) {
        self.baseURL = baseURL
        self.localURL = localURL
        self.remoteURL = remoteURL
        self.mergedURL = mergedURL
    }
}

public enum GitMergeToolArgumentError: LocalizedError, Sendable, Equatable {
    case missingMergetoolFlag
    case missingValue(String)
    case duplicateOption(String)
    case unknownOption(String)
    case inputFileMissing(String)
    case mergedParentMissing(String)

    public var errorDescription: String? {
        switch self {
        case .missingMergetoolFlag:
            return "The --mergetool flag is required."

        case .missingValue(let option):
            return "Missing value for \(option)."

        case .duplicateOption(let option):
            return "Option was provided more than once: \(option)."

        case .unknownOption(let option):
            return "Unknown option: \(option)."

        case .inputFileMissing(let path):
            return "Input file does not exist: \(path)"

        case .mergedParentMissing(let path):
            return "MERGED parent directory does not exist: \(path)"
        }
    }
}

public enum GitMergeToolArgumentParser {
    public static func parse(
        _ arguments: [String],
        fileManager: FileManager = .default
    ) throws -> GitMergeToolArguments {
        guard arguments.contains("--mergetool") else {
            throw GitMergeToolArgumentError.missingMergetoolFlag
        }

        let valueOptions = Set([
            "--base",
            "--local",
            "--remote",
            "--merged"
        ])

        var values: [String: String] = [:]
        var index = 0

        while index < arguments.count {
            let argument = arguments[index]

            if argument == "--mergetool" {
                index += 1
                continue
            }

            guard valueOptions.contains(argument) else {
                throw GitMergeToolArgumentError.unknownOption(argument)
            }

            guard values[argument] == nil else {
                throw GitMergeToolArgumentError.duplicateOption(argument)
            }

            let next = index + 1

            guard next < arguments.count else {
                throw GitMergeToolArgumentError.missingValue(argument)
            }

            let value = arguments[next]

            guard !value.hasPrefix("--") else {
                throw GitMergeToolArgumentError.missingValue(argument)
            }

            values[argument] = value
            index += 2
        }

        func required(_ option: String) throws -> String {
            guard let value = values[option], !value.isEmpty else {
                throw GitMergeToolArgumentError.missingValue(option)
            }
            return value
        }

        let basePath = try required("--base")
        let localPath = try required("--local")
        let remotePath = try required("--remote")
        let mergedPath = try required("--merged")

        for path in [basePath, localPath, remotePath] {
            guard fileManager.fileExists(atPath: path) else {
                throw GitMergeToolArgumentError.inputFileMissing(path)
            }
        }

        let mergedURL = URL(fileURLWithPath: mergedPath)
        let parent = mergedURL.deletingLastPathComponent()

        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(
            atPath: parent.path,
            isDirectory: &isDirectory
        ),
        isDirectory.boolValue
        else {
            throw GitMergeToolArgumentError.mergedParentMissing(parent.path)
        }

        return GitMergeToolArguments(
            baseURL: URL(fileURLWithPath: basePath),
            localURL: URL(fileURLWithPath: localPath),
            remoteURL: URL(fileURLWithPath: remotePath),
            mergedURL: mergedURL
        )
    }
}
