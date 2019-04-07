public struct PackageConfiguration: PackageConfig {
    public static var fileName: String = "package-config"
    
    public let configuration: [String: Any]
    
    public init(_ configuration: [String: Any]) {
        self.configuration = configuration
    }
    
    public subscript(string: String) -> Any? {
        return configuration[string]
    }
}
