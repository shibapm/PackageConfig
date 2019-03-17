
import Foundation

enum Loader {
	static func load<T: PackageConfig>() -> T? {
		let packageConfigJSON = NSTemporaryDirectory() + T.fileName

		print(packageConfigJSON)

		guard let data = FileManager.default.contents(atPath: packageConfigJSON) else {
			debugLog("Could not find a file at \(packageConfigJSON) - so returning an empty object")
			return nil
		}

		return try! JSONDecoder().decode(T.self, from: data)
	}
}
