
public protocol PackageConfig: Codable {

	static var fileName: String { get }

	static func load() throws -> Self
	func write()
}

extension PackageConfig {

	public static func load() throws -> Self {
		try Package.compile()
		return try Loader.load()
	}

	public func write() {
		Writer.write(configuration: self)
	}
}

import class Foundation.ProcessInfo

func debugLog(_ message: String) -> Void {
	let isVerbose = CommandLine.arguments.contains("--verbose") || (ProcessInfo.processInfo.environment["DEBUG"] != nil)
	if isVerbose {
		print(message)
	}
}
