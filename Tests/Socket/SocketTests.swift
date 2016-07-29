//
//  SocketTests.swift
//  BlueSocket
//
//  Created by Bill Abt on 3/15/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import XCTest

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

@testable import Socket

class SocketTests: XCTestCase {
    
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
