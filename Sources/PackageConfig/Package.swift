
import Foundation

struct Package {

	let dynamicLibraries: [String]

	func compile() {
		let swiftC = runXCRun(tool: "swiftc")

		var args = [String]()
		args += ["--driver-mode=swift"] // Eval in swift mode, I think?

		args += getSwiftPMManifestArgs(swiftPath: swiftC) // SwiftPM lib

		args += libraryLinkingArguments() // link libraries

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
	}

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

	func libraryPath(for library: String) -> String? {
		let fileManager = FileManager.default
		let libPaths = [
			".build/debug",
			".build/x86_64-unknown-linux/debug",
			".build/release",
		]

		func isLibPath(path: String) -> Bool {
			return fileManager.fileExists(atPath: path + "/lib\(library).dylib") || // macOS
				fileManager.fileExists(atPath: path + "/lib\(library).so") // Linux
		}

		return libPaths.first(where: isLibPath)
	}

	func libraryLinkingArguments() -> [String] {
		return dynamicLibraries.map { libraryName in
			guard let path = libraryPath(for: libraryName) else {
				print("PackageConfig: Could not find lib\(libraryName) to link against, is it possible you've not built yet?")
				exit(1)
			}

			return [
				"-L", path,
				"-I", path,
				"-l\(libraryName)"
			]
		}.reduce([], +)
	}

	func getSwiftPMManifestArgs(swiftPath: String) -> [String] {
		// using "xcrun --find swift" we get
		// /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc
		// we need to transform it to something like:
		// /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/4_2
		let fileManager = FileManager.default

		let swiftPMDir = swiftPath.replacingOccurrences(of: "bin/swiftc", with: "lib/swift/pm")
		let versions = try! fileManager.contentsOfDirectory(atPath: swiftPMDir)
		#warning("TODO: handle //swift-tools-version:4.2 declarations")
		let latestSPM = versions.sorted().last!
		let libraryPathSPM = swiftPMDir + "/" + latestSPM

		debugLog("Using SPM version: \(libraryPathSPM)")
		return ["-L", libraryPathSPM, "-I", libraryPathSPM, "-lPackageDescription"]
	}

}
