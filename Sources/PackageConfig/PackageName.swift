
public struct PackageName: ExpressibleByStringLiteral, Codable, Hashable, Equatable {

	public typealias StringLiteralType = String

	private let name: String

	public init(_ name: String) {
		self.name = name
	}

	public init(stringLiteral name: String) {
		self.name = name
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		self.name = try container.decode(String.self)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(name)
	}
}
