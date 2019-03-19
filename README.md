# PackageConfig

A Swift Package that allows you to define configuration settings inside a `Package.swift` - this is so that tools can all keep their configs consolidated inside a single place.

Tool builders use this dependency to grab their config settings.

### User writes:

Anywhere in the list of targets in `Package.swift`

```swift
.target(name: "PackageConfigs", dependencies: [
    "ExampleConfig" // your library config dylib
])
```

At the very bottom of the `Package.swift`

```swift
#if canImport(ExampleConfig) // your library config dynamic library
import ExampleConfig

ExampleConfig(value: "example value").write()
#endif
```

If more than one dependency uses `PackageConfig` be sure to wrap each in 

```swift
#if canImport(SomeLibraryConfig)
import SomeLibraryConfig

SomeLibraryConfig().write()
#endif
```

Also be sure to invoke `write` method of the `Config` otherwise this won't work.

And then to use your executable user would need to run this in the same directory as his/her project `Package.swift`:

```bash
swift run package-config	# compiles PackageConfigs target, expecting to find a dylib in `.build` directory for each of the listed libraries configs
swift run example		# runs your library executable
```

### Tool-dev writes:

For the sake of example lets assume your library is called Example then `Package.swift` would look like this:

```swift
let package = Package(
    name: "Example",
    products: [
        // notice that product with your library config should be dynamic library in order to produce dylib and allow PackageConfig to link it when building Package.swift
        .library(name: "ExampleConfig", type: .dynamic, targets: ["ExampleConfig"]),
        // 
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
// also you must conform to `Codable` and `PackageConfig`
public struct ExampleConfig: Codable, PackageConfig {

    // here can be whatever you want as long as your config can stay `Codable`
    let value: String

   	// here you must define your config fileName which will be used to write and read it to/from temporary directory
    public static var fileName: String { return "example-config.json" }

    // public init is also a requirement
    public init(value: String) {
	self.value = value
    }
}
```

Then for example in your `main.swift` in `Example` target you can load your config like this:

```swift
import ExampleConfig

do {
    let config = try ExampleConfig.load()
    print(config)
} catch {
    print(error)
}
```

### Notes for library developers

Since `YourConfig` target is a dynamic library you must ensure that you have built it everytime when using either `read` or `write`  methods of `PackageConfig`. When building from terminal this can be done by just running `swift build`.

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

# How it all works

When you invoke `YourPackage.load()` it will compile the `Package.swift` in the current directory the using `swiftc`.

While compiling it will try to link list of `dynamicLibraries: [String]` provided by your custom config conforming to `PackageConfig`.

When it get's compiled it will run and when `YourPackage.write()` get's called your package configuration json will be written to temporary directory.

After that it will try to read the json and decode it as if it was `YourPackage` type, providing it back to where you have invoked `load` method.

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
swift build; env DEBUG="*" swift run package-config-example
```

if you don't use fish:

```sh
swift build; DEBUG="*" swift run package-config-example
```
