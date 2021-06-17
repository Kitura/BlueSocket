//
//  Array+SocketHandler.swift
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
// swiftlint:disable force_try

import Foundation
import Socket

extension Array where Element == SocketHandler {
    
    /// Wait for any socket to have activity that needs to be handled via `process()`
    /// - Parameter timeout: Amount of time to wait; wait forever if value is not finite
    /// - Returns: List of `SocketHandler` that need to be `process()`ed
    func wait(timeout: TimeInterval) -> [SocketHandler] {
        // Find handlers with pending output
        let clientsPendingOutput = (self.filter { $0 is ClientHandler } as! [ClientHandler])
            .filter { $0.hasPendingOutput }
        
        
        // Create lookup to return SocketHandlers
        var socketList: [Socket:SocketHandler] = [:]
        for handler in self {
            socketList[handler.socket] = handler
        }
        let sockets = self.map { $0.socket }
        
        let activeSockets: [Socket]
        let waitParam: (timeout: UInt, waitForever: Bool)
        if clientsPendingOutput.count > 0 {
            waitParam = (timeout: 10, waitForever: false)
        } else if timeout.isFinite {
            waitParam = (timeout: UInt(timeout*1000), waitForever: false)
        } else {
            waitParam = (timeout: 1000_000, waitForever: true)
        }
        
        activeSockets = try! Socket.wait(for: sockets, timeout: waitParam.timeout, waitForever: waitParam.waitForever) ?? []
        
        let activeSocketHandlers = activeSockets.map { socketList[$0]! }
        return activeSocketHandlers + clientsPendingOutput
    }
    
    
    func process() {
        for handler in self {
            handler.process()
        }
    }
}
