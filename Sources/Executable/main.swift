
import Foundation

let process = Process()
let script =
"""
swift build --target PackageConfigs
mkdir -p ./Sources/PackageConfigs/
touch ./Sources/PackageConfigs/PackageConfigs.swift
echo '// Do not delete this file or it's target, it is requried to build dylibs for the Packages you installed which depend on PackageConfig for their own package configuration' > ./Sources/PackageConfigs/PackageConfigs.swift

"""

process.launchPath = "/bin/bash"
process.arguments = ["-c", script]
process.launch()
process.waitUntilExit()
