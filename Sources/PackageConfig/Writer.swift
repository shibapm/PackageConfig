
import Foundation

enum Writer {

	static func write<T: Codable>(configuration: T) {
		let packageConfigJSON = NSTemporaryDirectory() + "package-config.json"
		let encoder = JSONEncoder()
		let data = try! encoder.encode(configuration)

		if !FileManager.default.createFile(atPath: packageConfigJSON, contents: data, attributes: nil) {
			print("PackageConfig: Could not create a temporary file for the PackageConfig: \(packageConfigJSON)")
		}

		debugLog("written to path: \(packageConfigJSON)")
	}
}
