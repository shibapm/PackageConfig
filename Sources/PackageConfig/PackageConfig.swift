
import Foundation
@_exported import TypePreservingCodingAdapter

/// A facade to decorate any configurations we might think of
public struct PackageConfig {

	private let configurations: [PackageName: Aliased]

	public init(configurations: [PackageName: Aliased], adapter: TypePreservingCodingAdapter) {
		self.configurations = configurations
		write(packageConfig: self, adapter: adapter)
	}

	/// Provides a specific package configuation by packageName
	public subscript(package packageName: PackageName) -> Aliased? {
		get {
			return configurations[packageName]
		}
	}
}

extension PackageConfig: Codable {

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let keysAndValues = try container.decode([PackageName: Wrap].self).map { package, wrap in
			(package, wrap.wrapped as! Aliased)
		}
		self.configurations = [PackageName: Aliased](uniqueKeysWithValues: keysAndValues)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		let wraps = [PackageName: Wrap](uniqueKeysWithValues: configurations.map { (package, configuration) in
			(package, Wrap(wrapped: configuration, strategy: .alias))
		})
		try container.encode(wraps)
	}
}


/// Loads the specific Configuration if capable
public func loadConfigurationFromPackageConfig<T: Aliased>(_ packageName: PackageName, adapter: TypePreservingCodingAdapter) -> T? {
	return read(adapter: adapter)?[package: packageName] as? T
}

/// Loads the Configuration if capable
public func loadPackageConfig(_ adapter: TypePreservingCodingAdapter) -> PackageConfig? {
	return read(adapter: adapter)
}

func write(packageConfig: PackageConfig, adapter: TypePreservingCodingAdapter) {
	let fileManager = FileManager.default
	let path = NSTemporaryDirectory()
	let packageConfigJSON = path + "package-config.json"
	let encoder = JSONEncoder()
	encoder.userInfo[.typePreservingAdapter] = adapter
	let data = try! encoder.encode(packageConfig)

	if !fileManager.createFile(atPath: packageConfigJSON, contents: data, attributes: nil) {
		print("PackageConfig: Could not create a temporary file for the PackageConfig: \(packageConfigJSON)")
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
func read(adapter: TypePreservingCodingAdapter) -> PackageConfig? {
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

	print(path)

	guard let data = fileManager.contents(atPath: packageConfigJSON) else {
		// Package Manifest did not contain a config object at all
		// so just return an empty dictionary
		debugLog("Could not find a file at \(packageConfigJSON) - so returning an empty object")
		return nil
	}

	debugLog("Got \(String(describing: String(data: data, encoding: .utf8)))")

	let decoder = JSONDecoder()
	decoder.userInfo[.typePreservingAdapter] = adapter

	return try! decoder.decode(PackageConfig.self, from: data)
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

	return libPaths.first(where: {
		print($0)
		return isTheDangerLibPath(path: $0)
	})
}


/// Finds args for the locally built copy of PackageConfig
func getPackageConfigArgs() -> [String] {
	guard let libPackageConfig = getLibPackageConfigPath() else {
		print("PackageConfig: Could not find a libPackageConfig to link against, is it possible you've not built yet?")
		exit(1)
	}
	return ["-L", libPackageConfig, "-I", libPackageConfig, "-lPackageConfig"]
}
