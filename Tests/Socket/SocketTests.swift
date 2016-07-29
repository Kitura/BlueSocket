//
//  SocketTests.swift
//  BlueSocket
//
//  Created by Bill Abt on 3/15/16.
//  Copyright © 2016 IBM. All rights reserved.
//
// 	Licensed under the Apache License, Version 2.0 (the "License");
// 	you may not use this file except in compliance with the License.
// 	You may obtain a copy of the License at
//
// 	http://www.apache.org/licenses/LICENSE-2.0
//
// 	Unless required by applicable law or agreed to in writing, software
// 	distributed under the License is distributed on an "AS IS" BASIS,
// 	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// 	See the License for the specific language governing permissions and
// 	limitations under the License.
//

import XCTest
@testable import Socket

class SocketTests: XCTestCase {
    
	#if os(Linux)
		static var allTests : [(String, (SocketTests) -> () throws -> Void)] {

			return [
				("testSocket", testSocket)
			]
		}
	#endif
	
	override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSocket() {
        do {
            let port:Int32 = 1337
            
            let socket = try Socket.create()
            XCTAssertNotNil(socket)
            XCTAssertFalse(socket.isConnected)
            XCTAssertTrue(socket.isBlocking)
            
            try socket.listen(on: Int(port), maxBacklogSize: 10)
            XCTAssertTrue(socket.isListening)
            XCTAssertEqual(socket.listeningPort, port)
            
            socket.close()
            XCTAssertFalse(socket.isActive)
            
        } catch let error {
            
            // See if it's a socket error or something else...
            guard let socketError = error as? Socket.Error else {
                
                print("Unexpected error...")
                return
            }
            
            print("Error reported: \(socketError.description)")
        }
    }
}
