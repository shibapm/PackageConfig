public struct PackageConfiguration: PackageConfig, Codable {
    public static var fileName: String = "package-config.json"
    
    public let configuration: [String: String]
    
    public init(_ configuration: [String: String]) {
        self.configuration = configuration
    }
    
    public subscript(string: String) -> String? {
        return configuration[string]
    }
}
