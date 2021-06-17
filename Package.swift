// swift-tools-version:5.0

/**
 * Copyright IBM Corporation and the Kitura project authors 2017-2020
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import PackageDescription

struct BuildInfo {
    let product: [Product]
    let dependencies: [Package.Dependency]
    let targets: [Target]
}


let libraryBuildInfo = BuildInfo(
    product: [
        .library(
            name: "Socket",
            targets: ["Socket"]),
        
            .library(
                name: "BlueSocketTestCommonLibrary",
                targets: ["BlueSocketTestCommonLibrary"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Socket",
            dependencies: [],
            exclude: ["BlueSocket.xcodeproj", "BlueSocket.xcworkspace", "README.md", "Sources/Info.plist", "Sources/Socket.h"]
        ),
        .testTarget(
            name: "SocketTests",
            dependencies: ["Socket", "BlueSocketTestCommonLibrary"]
        ),
        
        .target(
            name: "BlueSocketTestCommonLibrary",
            dependencies: [ "Socket" ]
        ),
    ]
)

let toolsBuildInfo = BuildInfo(
    product: [
        .executable(
            name: "BlueSocketTestServer",
            targets: ["BlueSocketTestServer"]),
        .executable(
            name: "BlueSocketTestClient",
            targets: ["BlueSocketTestClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.1"),
    ],
    targets: [
        .target(name: "BlueSocketTestServer",
                dependencies: ["BlueSocketTestCommonLibrary", "ArgumentParser", ]
               ),
        .target(name: "BlueSocketTestClient",
                dependencies: ["BlueSocketTestCommonLibrary", "ArgumentParser" ]
               ),
    ]
)

var products: [Product] = [
    .library(
        name: "Socket",
        targets: ["Socket"]),

    .library(
        name: "BlueSocketTestCommonLibrary",
        targets: ["BlueSocketTestCommonLibrary"]),
    ]
#if swift(>=5.2)
products.append(contentsOf: [
    .executable(
        name: "BlueSocketTestServer",
        targets: ["BlueSocketTestServer"]),
    .executable(
        name: "BlueSocketTestClient",
        targets: ["BlueSocketTestClient"])
])
#endif

let buildInfo: BuildInfo
#if swift(>=5.2)
    buildInfo = BuildInfo(product: libraryBuildInfo.product + toolsBuildInfo.product,
                          dependencies: libraryBuildInfo.dependencies + toolsBuildInfo.dependencies,
                          targets: libraryBuildInfo.targets + toolsBuildInfo.targets)
#else
    buildInfo = BuildInfo(product: libraryBuildInfo.product, dependencies: libraryBuildInfo.dependencies, targets: libraryBuildInfo.targets)
#endif

#if os(Linux) || os(macOS) || os(iOS) || os(tvOS)
let package = Package(
    name: "Socket",
    products: buildInfo.product,
    dependencies: buildInfo.dependencies,
    targets: buildInfo.targets
)
#else
fatalError("Unsupported OS")
#endif
