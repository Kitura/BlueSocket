//
//  ClientHandler.swift
//  BlueSocket
//
//  Created by Sung, Danny on 2021-04-11.
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

public class ClientHandler: BufferedSocketHandler, ClientSocketHandler, Equatable {
    public private(set) var socket: Socket
    public var error: Error? = nil
    
    var pendingOutput = Data()
    public var totalReadCount: Int = 0
    public var totalWriteCount: Int = 0

    var hasActivity: Bool {
        let isActive = try! socket.isReadableOrWritable(waitForever: false, timeout: 1)
        
        if self.hasPendingOutput && isActive.writable {
            return true
        }
        return isActive.readable
    }
    
    var onClose: () -> Void = { }
    
    private var isClosed: Bool
    
    init(socket: Socket) {
        self.socket = socket
        self.isClosed = false
    }
    
    func processInternal() throws {
        guard let isActive = try? socket.isReadableOrWritable(waitForever: false, timeout: 1) else {
            return
        }
        guard !isClosed else {
            return
        }
        guard !socket.remoteConnectionClosed else {
            self.isClosed = true
            self.onClose()
            return
        }
        if isActive.writable && self.hasPendingOutput {
            let writeCount = try socket.write(from: pendingOutput)
            self.totalWriteCount += writeCount
            pendingOutput.removeFirst(writeCount)
        }
        
        if isActive.readable {
            var inputData = Data()
            try socket.read(into: &inputData)
            self.totalReadCount += inputData.count
            
            let outputData = Common.mutateData(data: inputData)
            self.pendingOutput.append(outputData)
        }
    }
    
    public static func == (lhs: ClientHandler, rhs: ClientHandler) -> Bool {
        return lhs === rhs
    }
    
}
