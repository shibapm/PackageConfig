
import Foundation
import PackageConfig

public struct ExampleConfig: Codable, PackageConfig {

	let value: String

	public static var fileName: String = "example.config.json"

	public init(value: String) {
		self.value = value
	}
}
