
import Foundation

enum Writer {

	static func write<T: PackageConfig>(configuration: T) {
		let packageConfigJSON = NSTemporaryDirectory() + T.fileName
		let encoder = JSONEncoder()
		let data = try! encoder.encode(configuration)

		if !FileManager.default.createFile(atPath: packageConfigJSON, contents: data, attributes: nil) {
			print("PackageConfig: Could not create a temporary file for the PackageConfig: \(packageConfigJSON)")
		}

		debugLog("written to path: \(packageConfigJSON)")
	}
}
