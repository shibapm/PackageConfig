
public protocol PackageConfig: Codable {

	static var dynamicLibraries: [String] { get }

	static func load() -> Self?
	func write()
}

extension PackageConfig {

	public static func load() -> Self? {
		Package(dynamicLibraries: dynamicLibraries).compile()
		return Loader.load()
	}

	public func write() {
		Writer.write(configuration: self)
	}
}

import Foundation

func debugLog(_ message: String) -> Void {
	let isVerbose = CommandLine.arguments.contains("--verbose") || (ProcessInfo.processInfo.environment["DEBUG"] != nil)
	if isVerbose {
		print(message)
	}
}
