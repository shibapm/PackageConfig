
import class Foundation.Process
import class Foundation.Pipe

enum DynamicLibraries {

	private static func read() -> [String] {
		let process = Process()
		let pipe = Pipe()

		process.launchPath = "/bin/bash"
		process.arguments = ["-c", "cat Package.swift"]
		process.standardOutput = pipe
		process.launch()
		process.waitUntilExit()

		return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!
			.split(separator: "\n").map(String.init)
	}

	static func list() throws -> [String] {
		let lines = read()

		guard let start = lines.lastIndex(where: { $0.contains("PackageConfigs") }) else {
			throw Error("Could not find PackageConfigs target definition")
		}

		let definition = lines.suffix(from: start)
			.joined(separator: "\n")
			.drop { !["["].contains($0) }
			.map(String.init)
			.joined()
			.split(separator: "\n")

		guard let end = definition.firstIndex(where: { $0.contains("]") }) else {
			throw Error("Could not end PackageConfigs target definition")
		}

		return definition.prefix(end + 1)
			.reversed()
			.drop { "]".contains($0) }
			.reversed()
			.map(String.init)
			.map {
				guard let comment = $0.range(of: "//")?.lowerBound else { return $0 }
				return String($0.prefix(comment.encodedOffset))
			}
			.joined()
			.replacingOccurrences(of: "\t", with: "")
			.replacingOccurrences(of: " ", with: "")
			.replacingOccurrences(of: "[", with: "")
			.replacingOccurrences(of: "]", with: "")
			.replacingOccurrences(of: ")", with: "")
			.replacingOccurrences(of: ",", with: "")
			.replacingOccurrences(of: "\"\"", with: "\"")
			.split(separator: "\"").map(String.init)
	}
}
