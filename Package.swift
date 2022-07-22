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

#if os(Linux) || os(macOS) || os(iOS) || os(tvOS)
let package = Package(
    name: "Socket",
    products: [
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
            exclude: ["Info.plist", "Socket.h"]
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
#else
fatalError("Unsupported OS")
#endif
