
/// Just an example configuration to test against
public struct ExampleConfiguration: Aliased {

	let value: String

	public init(value: String) {
		self.value = value
	}

	public static var alias: Alias = "ExampleConfiguration"
}

extension PackageName {

	public static var example: PackageName = "ExampleConfiguration"
}
