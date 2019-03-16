
import Foundation

enum Writer {

	static func write<T: Codable>(configuration: T) { //}, adapter: TypePreservingCodingAdapter) {
		let fileManager = FileManager.default
		let path = NSTemporaryDirectory()
		let packageConfigJSON = path + "package-config.json"
		let encoder = JSONEncoder()
//		encoder.userInfo[.typePreservingAdapter] = adapter
		let data = try! encoder.encode(configuration)

		if !fileManager.createFile(atPath: packageConfigJSON, contents: data, attributes: nil) {
			print("PackageConfig: Could not create a temporary file for the PackageConfig: \(packageConfigJSON)")
		}
	}
}
