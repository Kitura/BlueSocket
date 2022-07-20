// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Examples",
    products: [
        .executable(
            name: "BlueSocketTestServer",
            targets: ["BlueSocketTestServer"]),
        .executable(
            name: "BlueSocketTestClient",
            targets: ["BlueSocketTestClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.1"),
        .package(name: "BlueSocket", path: ".."),
    ],
    targets: [
        .target(
            name: "BlueSocketTestServer",
            dependencies: [
                .product(name: "BlueSocketTestCommonLibrary", package: "BlueSocket"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        .target(
            name: "BlueSocketTestClient",
            dependencies: [
                .product(name: "BlueSocketTestCommonLibrary", package: "BlueSocket"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
    ]
)
