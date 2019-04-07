import Foundation

enum Writer {

	static func write<T: PackageConfig>(configuration: T) {
        let jsonFolder = NSHomeDirectory() + "/.package-config"
        let jsonPath = jsonFolder + "/" + T.fileName
        
        if !FileManager.default.fileExists(atPath: jsonPath) {
            try! FileManager.default.createDirectory(atPath: jsonPath, withIntermediateDirectories: false, attributes: [:])
        }
		let encoder = JSONEncoder()

		do {
			let data = try encoder.encode(configuration)

			if !FileManager.default.createFile(atPath: jsonPath, contents: data, attributes: nil) {
				debugLog("PackageConfig: Could not create a temporary file for the PackageConfig: \(jsonPath)")
			}
		} catch {
			debugLog("Package config failed to encode configuration \(configuration)")
		}

		debugLog("written to path: \(jsonPath)")
	}
}
