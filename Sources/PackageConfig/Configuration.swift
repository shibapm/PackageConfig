
public protocol Configuration: Codable {

	static var dynamicLibraries: [String] { get }

	static func load() -> Self?
	func write()
}

extension Configuration {

	public static func load() -> Self? {
		Package(dynamicLibraries: dynamicLibraries + ["PackageConfig"]).compile()
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

/*


	So about how it should work.

	Dependency should conform to dependency and the all of its methods should be available for it.
	So when executing the dependency like this `swift run yourDependency`.
	It will Compile Package.swift dynamically injecting itself and this dependency as linked libraries.

	So when declarin the dependency configuration one would do as follows:

	#if canImport(YourDependency)
	import YourDependency

	DependencyConfiguration().write()

	#endif

	Then in the dependency itself you can load configuration whenever by doing this:

	DependencyConfiguration().load()

*/
