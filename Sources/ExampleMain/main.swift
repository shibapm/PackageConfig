import struct ExampleConfig.ExampleConfig

do {
	let example = try ExampleConfig.load()
	print(example)
} catch {
	print(error)
}
