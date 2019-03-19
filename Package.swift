// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PackageConfig",
    products: [
		.library(name: "PackageConfig", targets: ["PackageConfig"]),
		.executable(name: "package-config", targets: ["PackageConfigExecutable"]),

		.library(name: "ExampleConfig", type: .dynamic, targets: ["ExampleConfig"]),
		.executable(name: "package-config-example", targets: ["Example"]),
    ],
    dependencies: [
    ],
    targets: [
		.target(name: "PackageConfig", dependencies: []),
		.target(name: "PackageConfigExecutable", dependencies: []),

		.target(name: "ExampleConfig", dependencies: ["PackageConfig"]),
		.target(name: "Example", dependencies: ["PackageConfig", "ExampleConfig", "ShitConfig"]),

		.target(name: "PackageConfigs", dependencies: ["ExampleConfig"]),
    ]
)

#if canImport(ExampleConfig)
import ExampleConfig

ExampleConfig(value: "example value").write()
#endif
