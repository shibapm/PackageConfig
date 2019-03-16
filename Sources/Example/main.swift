
import PackageConfig

let adapter = TypePreservingCodingAdapter()
	.register(aliased: ExampleConfiguration.self)

let example: ExampleConfiguration? = PackageConfig.load(.example, adapter: adapter)

print(example)
