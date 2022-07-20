//
//  main.swift
//  BlueSocket
//
//  Created by Sung, Danny on 2021-04-12.
//  Copyright © 2021 Kitura project. All rights reserved.
//
//     Licensed under the Apache License, Version 2.0 (the "License");
//     you may not use this file except in compliance with the License.
//     You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//     Unless required by applicable law or agreed to in writing, software
//     distributed under the License is distributed on an "AS IS" BASIS,
//     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//     See the License for the specific language governing permissions and
//     limitations under the License.
//

import Foundation
import BlueSocketTestCommonLibrary
import ArgumentParser

let defaultPort = 10217

struct TestServer: ParsableCommand {
    @Option(name: [.customShort("p"), .customLong("port")], help: "TCP Port to connect to (Default: \(defaultPort))")
    var port: Int = defaultPort

    func run() throws {
        print("Listening on port: \(port)")
        let server = try ServerOperation(port: port)
        
        let opQ = OperationQueue()
        opQ.addOperation(server)
        
        print("Server started.")
        opQ.waitUntilAllOperationsAreFinished()
    }
}

TestServer.main()
