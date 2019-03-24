
import class Foundation.JSONEncoder
import class Foundation.FileManager
import func Foundation.NSTemporaryDirectory

enum Writer {

	static func write<T: PackageConfig>(configuration: T) {
		let packageConfigJSON = NSTemporaryDirectory() + T.fileName
		let encoder = JSONEncoder()

		do {
			let data = try encoder.encode(configuration)

			if !FileManager.default.createFile(atPath: packageConfigJSON, contents: data, attributes: nil) {
				debugLog("PackageConfig: Could not create a temporary file for the PackageConfig: \(packageConfigJSON)")
			}
		} catch {
			debugLog("Package config failed to encode configuration \(configuration)")
		}

		debugLog("written to path: \(packageConfigJSON)")
	}
}
