// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PackageConfig",
    products: [
        .library(name: "PackageConfig", type: .dynamic, targets: ["PackageConfig"]),
        .executable(name: "package-config-example", targets: ["Example"])
    ],
    dependencies: [
		.package(url: "https://github.com/IgorMuzyka/Type-Preserving-Coding-Adapter.git", .branch("master")),
	],
    targets: [
        // The lib
        .target(name: "PackageConfig", dependencies: ["TypePreservingCodingAdapter"]),

        // The app I use to verify it all works
        .target(name: "Example", dependencies: ["PackageConfig", "TypePreservingCodingAdapter"]),
        // Not used
        .testTarget(name: "PackageConfigTests", dependencies: ["PackageConfig"]),
    ]
)

#if canImport(PackageConfig)
import PackageConfig

let config = PackageConfig(
	configurations: [
		.example: ExampleConfiguration(value: "example configuration value")
	],
	adapter: TypePreservingCodingAdapter()
		.register(aliased: ExampleConfiguration.self)
)
#endif

