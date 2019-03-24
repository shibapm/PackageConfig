
struct Error: Swift.Error, ExpressibleByStringLiteral {

	let reason: String

	init(_ reason: String) {
		self.reason = reason
	}

	init(stringLiteral reason: String) {
		self.reason = reason
	}

	var localizedDescription: String {
		return reason
	}
}
