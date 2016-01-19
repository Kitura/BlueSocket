//
//  Package.swift
//  ETSocket
//
//  Created by Bill Abt on 1/19/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import PackageDescription

let package = Package(
	name: "ETSocket",
	targets: [Target(name: "ETSocket")],
	exclude: ["ETSocket.xcodeproj", "ETSocket.xcworkspace", "README.md", "Sources/Info.plist"]
)
