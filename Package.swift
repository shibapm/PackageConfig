// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PackageConfig",
    products: [
        .library(name: "PackageConfig", type: .dynamic, targets: ["PackageConfig"]),
        .executable(name: "package-config-example", targets: ["Example"])
    ],
    dependencies: [],
    targets: [
        // The lib
        .target(name: "PackageConfig", dependencies: []),

        // The app I use to verify it all works
        .target(name: "Example", dependencies: ["PackageConfig"]),
        // Not used
        .testTarget(name: "PackageConfigTests", dependencies: ["PackageConfig"]),
    ]
)

#if canImport(PackageConfig)
import PackageConfig

let config = PackageConfig([
    "danger" : ["disable"],
    "linter": ["rules": ["allowSomething"]]
])
#endif

