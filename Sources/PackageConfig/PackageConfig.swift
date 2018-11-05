import Foundation

/// The public API for tools working with Swift Package Manager
public struct PackageConfig {
    public init(_ options: [String: Any]) {
        let fileManager = FileManager.default
        let path = NSTemporaryDirectory()
        let packageConfigJSON = path + "package-config.json"
        let jsonData = try! JSONSerialization.data(withJSONObject: options, options: [])

        if !fileManager.createFile(atPath: packageConfigJSON, contents: jsonData, attributes: nil) {
            // Couldn't write to tmpdir
            print("PackageConfig: Could not create a temporary file for the PackageConfig: \(packageConfigJSON)")
        }
    }
}

/// Only prints when --verbose is in the arge, or when DEBUG exists
func debugLog(_ message: String) -> Void {
    let isVerbose = CommandLine.arguments.contains("--verbose") || (ProcessInfo.processInfo.environment["DEBUG"] != nil)
    if isVerbose {
        print(message)
    }
}

/// Gets a config object from the user's Package.swift
/// by parsing the document by the same way that SwiftPM does it
/// - Returns: A dictionary of all settings
public func getPackageConfig() -> Dictionary<String, AnyObject> {
    let fileManager = FileManager.default
    let swiftC = runXCRun(tool: "swiftc")

    var args = [String]()
    args += ["--driver-mode=swift"] // Eval in swift mode, I think?

    args += getSwiftPMManifestArgs(swiftPath: swiftC) // SwiftPM lib
    args += getPackageConfigArgs() // This lib

    args += ["-suppress-warnings"] // SPM does that too
    args += ["Package.swift"] // The Package.swift in the CWD

    // Create a process to eval the Swift Package manifest as a subprocess
    let proc = Process()
    proc.launchPath = swiftC
    proc.arguments = args

    debugLog("CMD: \(swiftC) \( args.joined(separator: " "))")

    let standardOutput = FileHandle.standardOutput
    proc.standardOutput = standardOutput
    proc.standardError = standardOutput

    // Evaluation of the package swift code will end up
    // creating a file in the tmpdir that stores the JSON
    // settings when a new instance of PackageConfig is created

    proc.launch()
    proc.waitUntilExit()

    debugLog("Finished launching swiftc")

    // So read it
    let path = NSTemporaryDirectory()
    let packageConfigJSON = path + "package-config.json"
    guard let jsonData = fileManager.contents(atPath: packageConfigJSON) else {
        // Package Manifest did not contain a config object at all
        // so just return an empty dictionary
        debugLog("Could not find a file at \(packageConfigJSON) - so returning an empty object")
        return  [:]
    }

    debugLog("Got \(String(describing: String(data: jsonData, encoding: .utf8)))")
    return try! JSONSerialization.jsonObject(with: jsonData) as! Dictionary<String, AnyObject>
}

/// Helper to run xcrun to get paths for things
func runXCRun(tool: String) -> String {
    let proc = Process()
    proc.launchPath = "/usr/bin/xcrun"
    proc.arguments = ["--find", tool]

    debugLog("CMD: \(proc.launchPath!) \( ["--find", tool].joined(separator: " "))")

    let pipe = Pipe()
    proc.standardOutput = pipe

    proc.launch()
    proc.waitUntilExit()

    let resultsWithNewline = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!
    return resultsWithNewline.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// Finds args for the locally built copy of PackageConfig
func getPackageConfigArgs() -> [String] {
    guard let libPackageConfig = getLibPackageConfigPath() else {
        print("PackageConfig: Could not find a libPackageConfig to link against, is it possible you've not built yet?")
        exit(1)
    }
    return ["-L", libPackageConfig, "-I", libPackageConfig, "-lPackageConfig"]
}

// Finds args for the current version of Xcode's Swift Package Manager
func getSwiftPMManifestArgs(swiftPath: String) -> [String] {
    // using "xcrun --find swift" we get
    // /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc
    // we need to transform it to something like:
    // /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/4_2
    let fileManager = FileManager.default

    let swiftPMDir = swiftPath.replacingOccurrences(of: "bin/swiftc", with: "lib/swift/pm")
    let versions = try! fileManager.contentsOfDirectory(atPath: swiftPMDir)
    // TODO: Handle the
    // // swift-tools-version:4.2
    // declarations?
    let latestSPM = versions.sorted().last!
    let libraryPathSPM = swiftPMDir + "/" + latestSPM

    debugLog("Using SPM version: \(libraryPathSPM)")
    return ["-L", libraryPathSPM, "-I", libraryPathSPM, "-lPackageDescription"]
}


/// Finds a path to add at runtime to the compiler, which links
/// to the library which ships with Swift PM
func getLibPackageDescriptionPath() -> String? {
    let fileManager = FileManager.default

    // Check and find where we can link to libDanger from
    let libPaths = [
        "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/4_2", // Xcode
    ]

    func isThePackageLibPath(path: String) -> Bool {
        return fileManager.fileExists(atPath: path + "/libPackageDescription.dylib")  || // OSX
            fileManager.fileExists(atPath: path + "/libPackageDescription.so")        // Linux
    }

    return libPaths.first(where: isThePackageLibPath)
}

/// Finds a path to add at runtime to the compiler, which links
/// to the library Danger
func getLibPackageConfigPath() -> String? {
    let fileManager = FileManager.default

    // Check and find where we can link to libDanger from
    let libPaths = [
        ".build/debug", // Working in Xcode / CLI
        ".build/x86_64-unknown-linux/debug", // Danger Swift's CI
        ".build/release", // Testing prod
    ]

    func isTheDangerLibPath(path: String) -> Bool {
        return fileManager.fileExists(atPath: path + "/libPackageConfig.dylib")  || // OSX
            fileManager.fileExists(atPath: path + "/libPackageConfig.so")        // Linux
    }

    return libPaths.first(where: isTheDangerLibPath)
}

