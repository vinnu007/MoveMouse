// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MoveMouse",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "MoveMouse",
            targets: ["MoveMouse"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "MoveMouse"
        ),
    ],
    swiftLanguageModes: [.v6]
)
