//
//  ServerHandler.swift
//  BlueSocket
//
//  Created by Sung, Danny on 2021-04-10.
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
// swiftlint:disable force_try

import Foundation
import Socket

class ServerHandler: SocketHandler {
    var error: Error?
        
    var socket: Socket
    
    var hasActivity: Bool {
        let isActive = try! socket.isReadableOrWritable(waitForever: false, timeout: 1)
        return isActive.readable
    }
    
    public var onNewConnection: (Socket) -> Void = { _ in }
    
    init(port: Int) throws {
        let socket = try Socket.create(family: .inet)
        try socket.listen(on: Int(port), node: "localhost")
        self.socket = socket
    }
    
    func processInternal() throws {
        guard self.hasActivity else { return }

        let clientSocket = try socket.acceptClientConnection()
        self.onNewConnection(clientSocket)
    }
}
