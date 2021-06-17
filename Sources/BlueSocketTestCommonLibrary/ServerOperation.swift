//
//  ServerOperation.swift
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

import Foundation
import Socket

public class ServerOperation: Operation {
    let serverHandler: ServerHandler
    var clientHandlers: [ClientHandler]
    
    public init(port: Int) throws {
        self.serverHandler = try ServerHandler(port: port)
        self.clientHandlers = []
    }

    public override func main() {
        self.serverHandler.onNewConnection = { socket in
            let client = ClientHandler(socket: socket)
            client.onClose = { [weak self, weak client] in
                guard let self = self, let client = client else { return }
                
                self.clientHandlers.removeAll(where: { $0 == client })
//                print("client closed  read \(client.totalReadCount) bytes  write \(client.totalWriteCount) bytes  (count: \(self.clientHandlers.count))")
            }
            self.clientHandlers.append(client)
        }

        while !self.isCancelled {
            autoreleasepool {
                let socketHandlers: [SocketHandler] = [serverHandler] + clientHandlers
                
                let activeHandlers = socketHandlers.wait(timeout: 12)
                activeHandlers.process()
            }
        }
    }
}

#if os(Linux)
/// Compatibility layer for Linux.
///
/// Autoreleasepools are not necessary for Linux: https://forums.swift.org/t/autoreleasepool-for-ubuntu/4419/14
@discardableResult
func autoreleasepool<Result>(invoking body: () throws -> Result) rethrows -> Result {
    try body()
}
#endif
