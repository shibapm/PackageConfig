# PackageConfig

A Swift Package that allows you to define configuration settings inside a `Package.swift` - this is so that tools can all keep their configs consolidated inside a single place.

Tool builders use this dependency to grab their config settings.

### User writes:

At the very bottom of the `Package.swift`

```swift
#if canImport(ExampleConfig)
import ExampleConfig

ExampleConfig(value: "example value").write()
#endif
```

### Tool-dev writes:

For the sake of example lets assume your library is called Example then `Package.swift` would look like this:

```swift
let package = Package(
    name: "Example",
    products: [
        // notice that library product with your config should be dynamic
        .library(name: "ExampleConfig", type: .dynamic, targets: ["ExampleConfig"]),
        .executable(name: "example", targets: ["Example"]),
    ],
    dependencies: [
        .package(url: "https://github.com/orta/PackageConfig.git", from: "0.0.2"),
    ],
    targets: [
        .target(name: "ExampleConfig", dependencies: ["PackageConfig"]),
        .target(name: "Example", dependencies: ["ExampleConfig"]),
    ]
)
```

In your `ExampleConfig` target define `ExampleConfig` like this.

```swift
import PackageConfig

// it must be public for you to use in your executable target
// also you must conform to Codable and PackageConfig
public struct ExampleConfig: Codable, PackageConfig {

    // here can be whatever you want as long as your config can stay `Codable`
	let value: String

    // here you define a name of ExampleConfig dynamic library product
	public static var dynamicLibraries: [String] = ["ExampleConfig"]

    // public init is also a requirement
	public init(value: String) {
		self.value = value
	}
}


```

Then in your `main.swift` in `Example` target you can load your config like this:

```swift
import ExampleConfig

let config = ExampleConfig.load()
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
