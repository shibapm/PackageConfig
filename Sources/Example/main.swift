import PackageConfig
import Foundation
import TypePreservingCodingAdapter

let adapter = TypePreservingCodingAdapter().register(aliased: ExampleConfiguration.self)
let config = PackageConfig.load(adapter)

print(config?[package: "example"])
