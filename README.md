# PackageConfig

A Swift Package that allows you to define configuration settings inside a `Package.swift` - this is so that tools can all keep their configs consolidated inside a single place. Tool builders use this dependency to grab their config settings.

### User writes:

```swift
// swift-tools-version:4.0
import PackageDescription

// Traditional Package.swift

let package = Package(
    name: "danger-swift",
    // ...
    swiftLanguageVersions: [4]
)

// Config lives under the package

#if canImport(PackageConfig) && canImport(YourPackage)
import PackageConfig
import YourPackage

let adapter = TypePreservingCodingAdapter()
let config = PackageConfig(
	configurations: [
        .yourPackageName: YourPackageConfig(info: ["this", "and", "that", "whatever"]),
    ],
    adapter: TypePreservingCodingAdapter()
    	.register(aliase: YourPackageConfig.self)
)
#endif
```

### Tool-dev writes:

Add this library to your tool's `Package.swift`:

```diff
let package = Package(
    name: "danger-swift",
    products: [
        .library(name: "Danger", type: .dynamic, targets: ["Danger"]),
        .executable(name: "danger-swift", targets: ["Runner"])
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Marathon.git", from: "3.1.0"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.1.0"),
+        .package(url: "https://github.com/orta/PackageConfig.git", from: "0.0.1"),
    ],
    targets: [
        .target(name: "Danger", dependencies: ["ShellOut"]),
-        .target(name: "Runner", dependencies: ["Danger", "MarathonCore"]),
+        .target(name: "Runner", dependencies: ["Danger", "MarathonCore", "PackageConfig"]),
        .testTarget(name: "DangerTests", dependencies: ["Danger"]),
    ],
)
```

Define your Configuration and extend PackageName with your package name:

```swift
import PackageConfig

// Define your config type.
// Just an example, it can be watever you want as long as it's `Codable`.
// It must conform to `Aliased` and provide an alias.
public struct YourPackageConfig: Aliased { 
    
    public let info: [String]
    public static var alias: Alias = "YourPackageConfig" // alias to preserve type when coding
    
    public init(info: [String]) {
        self.info = info
    }
}

// Define your `PackageName` to make it possible to register and get the config by it in PackageConfig.
extension PackageName {

    public static var yourPackageName: PackageName = "YourPackageName" 
}
```

To grab your configuration:

```swift
import PackageConfig

let adapter = TypePreservingCodingAdapter()
    .register(aliased: YourPackageConfig.self)
let yourConfig: YourPackageConfig? = PackageConfig.load(.yourPackageName, adapter: adapter)

print(yourConfig!)
```

----

# Changelog

- 0.0.1

  Exposes a config for `Package.swift` files

  ```swift
  #if canImport(PackageConfig)
  import PackageConfig

  let config = PackageConfig([
      "danger" : ["disable"],
      "linter": ["rules": ["allowSomething"]]
  ])
  #endif
  ```

  This might be everything, so if in a month or two nothing really changes
  I'll v1 after this release.

# Debugging

### How to see the JSON from a Package.swift file

Use SPM with verbose mode:

```sh
~/d/p/o/i/s/PackageConfig  $ swift build --verbose
```

And grab the bit out after the first sandbox. I then changed the final arg to `-fileno 1` and it printed the JSON.

```sh
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc --driver-mode=swift -L /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/4_2 -lPackageDescription -suppress-warnings -swift-version 4.2 -I /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/4_2 -target x86_64-apple-macosx10.10 -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.14.sdk /Users/ortatherox/dev/projects/orta/ios/spm/PackageConfig/Package.swift -fileno 1

{"errors": [], "package": {"cLanguageStandard": null, "cxxLanguageStandard": null, "dependencies": [], "name": "PackageConfig", "products": [{"name": "PackageConfig", "product_type": "library", "targets": ["PackageConfig"], "type": null}], "targets": [{"dependencies": [], "exclude": [], "name": "PackageConfig", "path": null, "publicHeadersPath": null, "sources": null, "type": "regular"}, {"dependencies": [{"name": "PackageConfig", "type": "byname"}], "exclude": [], "name": "PackageConfigTests", "path": null, "publicHeadersPath": null, "sources": null, "type": "test"}]}}
```

### How I verify this works

I run this command:

```sh
swift build; env DEBUG="*" ./.build/x86_64-apple-macosx10.10/debug/package-config-example
```

if you don't use fish:

```sh
swift build; DEBUG="*" ./.build/x86_64-apple-macosx10.10/debug/package-config-example
```
