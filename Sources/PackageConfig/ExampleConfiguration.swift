
public struct ExampleConfiguration: Codable, Configuration {

	let value: String

	public static var dynamicLibraries: [String] = []

	public init(value: String) {
		self.value = value
	}
}
