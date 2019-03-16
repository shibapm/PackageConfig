
public struct ExampleConfig: Codable, PackageConfig {

	let value: String

	public static var dynamicLibraries: [String] = []

	public init(value: String) {
		self.value = value
	}
}
