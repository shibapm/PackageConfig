
import class Foundation.Process

let process = Process()
let script =
"""
mkdir -p ./Sources/PackageConfigs/
touch ./Sources/PackageConfigs/PackageConfigs.swift
swift package resolve
swift build --target PackageConfigs
"""
process.launchPath = "/bin/bash"
process.arguments = ["-c", script]
process.launch()
process.waitUntilExit()
