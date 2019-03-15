
import Foundation
import TypePreservingCodingAdapter

public protocol Aliased: Codable {

	static var alias: Alias { get }
}

extension TypePreservingCodingAdapter {

	public func register<T: Aliased>(aliased type: T.Type) -> TypePreservingCodingAdapter {
		return register(type: type).register(alias: T.alias, for: type)
	}
}
