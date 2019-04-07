final class PackageConfiguration: PackageConfig, Codable {
    static var fileName: String = "package-config.json"
    
    let configuration: [String: String]
    
    init(_ configuration: [String: String]) {
        self.configuration = configuration
    }
    
    public subscript(string: String) -> String? {
        return configuration[string]
    }
}
