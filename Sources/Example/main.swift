
import PackageConfig

let adapter = TypePreservingCodingAdapter()
	.register(aliased: ExampleConfiguration.self)

let example: ExampleConfiguration? = loadConfigurationFromPackageConfig(.example, adapter: adapter)

print(example)
