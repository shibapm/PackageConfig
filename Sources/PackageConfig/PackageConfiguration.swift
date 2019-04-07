import Foundation

public struct PackageConfiguration: PackageConfig {
    public static var fileName: String = "package-config"
    
    public let configuration: [String: AnyType]
    
    public init(_ configuration: [String: Any]) {
        self.configuration = configuration.mapValues(AnyType.init)
    }
    
    public subscript(string: String) -> Any? {
        return configuration[string]?.jsonValue
    }
}


public protocol ConfigType: Codable {
    var jsonValue: Any { get }
}

extension Int: ConfigType {
    public var jsonValue: Any { return self }
}
extension String: ConfigType {
    public var jsonValue: Any { return self }
}
extension Double: ConfigType {
    public var jsonValue: Any { return self }
}
extension Bool: ConfigType {
    public var jsonValue: Any { return self }
}

public struct AnyType: ConfigType {
    public var jsonValue: Any
    
    init(_ jsonValue: Any) {
        self.jsonValue = jsonValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            jsonValue = intValue
        } else if let stringValue = try? container.decode(String.self) {
            jsonValue = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            jsonValue = boolValue
        } else if let doubleValue = try? container.decode(Double.self) {
            jsonValue = doubleValue
        } else if let doubleValue = try? container.decode(Array<AnyType>.self) {
            jsonValue = doubleValue
        } else if let doubleValue = try? container.decode(Dictionary<String, AnyType>.self) {
            jsonValue = doubleValue
        } else {
            throw DecodingError.typeMismatch(ConfigType.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let value = jsonValue as? Int {
            try container.encode(value)
        } else if let value = jsonValue as? String {
            try container.encode(value)
        } else if let value = jsonValue as? Bool {
            try container.encode(value)
        } else if let value = jsonValue as? Double {
            try container.encode(value)
        } else if let value = jsonValue as? [AnyType] {
            try container.encode(value)
        } else if let value = jsonValue as? [String: AnyType] {
            try container.encode(value)
        } else {
            throw DecodingError.typeMismatch(ConfigType.self, DecodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}
