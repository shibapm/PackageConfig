
import PackageConfig

let adapter = TypePreservingCodingAdapter()
	.register(aliased: ExampleConfiguration.self)

let config = PackageConfig.load(adapter)
let exampleConfiguration = config?[package: .example] as? ExampleConfiguration

print(exampleConfiguration!)
