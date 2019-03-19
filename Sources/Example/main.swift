
import ExampleConfig

do {
	let example = try ExampleConfig.load()
	print(example)
} catch {
	print(error)
}
