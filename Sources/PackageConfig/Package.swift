import Foundation

enum Package {
    static func compile() throws {
        #if os(Linux)
        let swiftC = try findPath(tool: "swiftc")
        #else
        let swiftC = try runXCRun(tool: "swiftc")
        #endif
        let process = Process()
        let linkedLibraries = try libraryLinkingArguments()
        var arguments = [String]()
        arguments += ["--driver-mode=swift"] // Eval in swift mode, I think?
        arguments += getSwiftPMManifestArgs(swiftPath: swiftC) // SwiftPM lib
        arguments += linkedLibraries
        arguments += ["-suppress-warnings"] // SPM does that too
        arguments += ["Package.swift"] // The Package.swift in the CWD

        // Create a process to eval the Swift Package manifest as a subprocess
        process.launchPath = swiftC
        process.arguments = arguments
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardOutput

        debugLog("CMD: \(swiftC) \(arguments.joined(separator: " "))")

        // Evaluation of the package swift code will end up
        // creating a file in the tmpdir that stores the JSON
        // settings when a new instance of PackageConfig is created
        process.launch()
        process.waitUntilExit()
        debugLog("Finished launching swiftc")
    }

    static private func runXCRun(tool: String) throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.launchPath = "/usr/bin/xcrun"
        process.arguments = ["--find", tool]
        process.standardOutput = pipe

        debugLog("CMD: \(process.launchPath!) \( ["--find", tool].joined(separator: " "))")

        process.launch()
        process.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func findPath(tool: String) throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.launchPath = "/bin/bash"
        process.arguments = ["-c", "command -v \(tool)"]
        process.standardOutput = pipe

        debugLog("CMD: \(process.launchPath!) \(process.arguments!.joined(separator: " "))")

        process.launch()
        process.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func libraryPath(for library: String) -> String? {
        let fileManager = FileManager.default
        let libPaths = [
            ".build/debug",
            ".build/x86_64-unknown-linux/debug",
            ".build/release",
        ]

        // "needs to be improved"
        // "consider adding `/usr/lib` to libPath maybe"

        func isLibPath(path: String) -> Bool {
            return fileManager.fileExists(atPath: path + "/lib\(library).dylib") || // macOS
                fileManager.fileExists(atPath: path + "/lib\(library).so") // Linux
        }

        return libPaths.first(where: isLibPath)
    }

    private static func libraryLinkingArguments() throws -> [String] {
        let packageConfigLib = "PackageConfig"
        guard let packageConfigPath = libraryPath(for: packageConfigLib) else {
            throw Error("PackageConfig: Could not find lib\(packageConfigLib) to link against, is it possible you've not built yet?")
        }

        return try DynamicLibraries.list().map { libraryName in
            guard let path = libraryPath(for: libraryName) else {
                throw Error("PackageConfig: Could not find lib\(libraryName) to link against, is it possible you've not built yet?")
            }

            return [
                "-L", path,
                "-I", path,
                "-l\(libraryName)",
            ]
        }.reduce([
            "-L", packageConfigPath,
            "-I", packageConfigPath,
            "-l\(packageConfigLib)",
        ], +)
    }

    private static func getSwiftPMManifestArgs(swiftPath: String) -> [String] {
        // using "xcrun --find swift" we get
        // /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc
        // we need to transform it to something like:
        // /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/4_2
        let fileManager = FileManager.default

        let swiftPMDir = swiftPath.replacingOccurrences(of: "bin/swiftc", with: "lib/swift/pm")
        let versions = try! fileManager.contentsOfDirectory(atPath: swiftPMDir).filter { $0 != "llbuild" }

        let latestVersion = versions.sorted().last!
        var spmVersionDir = latestVersion
        let swiftToolsVersion = getSwiftToolsVersion()

        if let swiftToolsVersion = swiftToolsVersion, versions.contains(swiftToolsVersion) {
            spmVersionDir = swiftToolsVersion
        }

        let packageDescriptionVersion = swiftToolsVersion?.replacingOccurrences(of: "_", with: ".")
        let libraryPathSPM = swiftPMDir + "/" + spmVersionDir

        debugLog("Using SPM version: \(libraryPathSPM)")
        return ["-L", libraryPathSPM, "-I", libraryPathSPM, "-lPackageDescription", "-package-description-version", packageDescriptionVersion ?? "5.2"]
    }

    private static func getSwiftToolsVersion() -> String? {
        guard let contents = try? String(contentsOfFile: "Package.swift") else {
            return nil
        }

        let range = NSRange(location: 0, length: contents.count)
        guard let regex = try? NSRegularExpression(pattern: "^// swift-tools-version:(?:(\\d)\\.(\\d)(?:\\.\\d)?)"),
            let match = regex.firstMatch(in: contents, options: [], range: range),
            let majorRange = Range(match.range(at: 1), in: contents), let major = Int(contents[majorRange]),
            let minorRange = Range(match.range(at: 2), in: contents), let minor = Int(contents[minorRange])
        else {
            return nil
        }

        switch major {
        case 4:
            if minor < 2 {
                return "4"
            }
            return "4_2"
        default:
            return "\(major)_\(minor)"
        }
    }
}
