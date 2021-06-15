//
//  ClientController.swift
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

public class ClientController {
    let socket: Socket
    let maxBytes: Int
    var error: Error?
    let packetSize: Int
    
    public var isDone: Bool {
//        return !socket.isConnected && !socket.remoteConnectionClosed
        return self.state != .inProgress
    }
    public var isFailed: Bool {
        switch self.state {
        case .inProgress: return false
        case .success: return false
        case .failure(_): return true
        }
    }

    public private(set) var bytesWritten: Int = 0
    public private(set) var bytesRead: Int = 0
    
    public enum State: CustomStringConvertible, Equatable {
        case inProgress
        case success
        case failure(String)
        
        public var description: String {
            switch self {
            case .inProgress: return "In Progress"
            case .success: return "Success"
            case .failure(let reason): return "Failure: \(reason)"
            }
        }
    }
    public private(set) var state: State
    
    public init(port: Int, maxBytes: Int, packetSize: Int = 1024) throws {
        let signature = try Socket.Signature(protocolFamily: .inet, socketType: .stream, proto: .tcp, hostname: "localhost", port: Int32(port))!
        
        self.socket = try Socket.create(connectedUsing: signature)
        self.maxBytes = maxBytes
        self.packetSize = packetSize
        self.state = .inProgress
    }
    
    public func process() {
        do {
            try self.processInternal()
        } catch {
            self.error = error
        }
    }
    
    private func processInternal() throws {
        guard self.state == .inProgress else {
            return
        }
        if
            bytesWritten == maxBytes &&
            bytesRead == maxBytes
        {
            socket.close()
            self.state = .success
            return
        }
        guard !socket.remoteConnectionClosed else {
            self.state = .failure("Server closed connection prematurely")
            return
        }
        
        let isActive = try! socket.isReadableOrWritable(waitForever: false, timeout: 1)

        if
            bytesWritten < maxBytes,
            isActive.writable
        {
            let packetSize = min( maxBytes - bytesWritten, self.packetSize)
            let outputData = generateData(offset: bytesWritten, length: packetSize)
            let writeCount = try socket.write(from: outputData)
    
            self.bytesWritten += writeCount
        }
        
        if isActive.readable {
            var inData = Data()
            try socket.read(into: &inData)
            
            let compareData = Common.mutateData(data: generateData(offset: bytesRead, length: inData.count) )
            if compareData != inData {
                self.state = .failure("Data does not match at offset: \(bytesRead)")
            }
            bytesRead += inData.count
        }
    }
    
    private func generateData(offset: Int, length: Int) -> Data {
        var data = Data()
        for n in 0..<length {
            let byte = UInt8( (offset + n) & 0xff )
            data.append( byte )
        }
        
        return data
    }
}
