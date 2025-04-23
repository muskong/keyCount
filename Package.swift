// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeyCount",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "KeyCount", targets: ["KeyCount"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "KeyCount",
            dependencies: [],
            path: "Sources"
        )
    ]
)
