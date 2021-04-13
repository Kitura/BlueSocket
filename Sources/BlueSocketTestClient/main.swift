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
import ArgumentParser
import BlueSocketTestCommonLibrary

let defaultPort = 10217
let defaultMaxBytes = 1_000_000
let defaultNumConnections = 1

struct TestClient: ParsableCommand {
    @Option(name: [.customShort("p"), .customLong("port")], help: "TCP Port to connect to (Default: \(defaultPort))")
    var port: Int = defaultPort
    
    @Option(name: [.customShort("b"), .customLong("bytes")], help: "Number of bytes to send (Default: \(defaultMaxBytes))")
    var maxBytes: Int = defaultMaxBytes

    @Option(name: [.customShort("c"), .customLong("connections")], help: "Number of simultaneous connections (Default: \(defaultNumConnections))")
    var numConnections: Int = defaultNumConnections

    func run() throws {
        print("Connecting to port: \(port)")

        var clientList: [ClientController] = []
        
        for _ in 0..<numConnections {
            let client = try ClientController(port: port, maxBytes: maxBytes)
            clientList.append(client)
        }
        
        while clientList.activeClients.count > 0 {
            clientList.process()
        }
        
        for client in clientList {
            print("Wrote \(client.bytesWritten) bytes  Read \(client.bytesRead) bytes")
            print("\(client.state)")
        }
    }
}

TestClient.main()


