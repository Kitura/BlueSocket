//
//  BasicSocketTests.swift
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
	
	let port: Int32 = 1337
	let host: String = "127.0.0.1"
	
	
	override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
	func createHelper(family: Socket.ProtocolFamily = .inet) throws -> Socket {
		
		let socket = try Socket.create(family: family)
		XCTAssertNotNil(socket)
		XCTAssertFalse(socket.isConnected)
		XCTAssertTrue(socket.isBlocking)
		
		return socket
	}
	
	func testDefaultCreate() {
		
		do {
			
			// Create the socket...
			let socket = try createHelper()
			
			// Get the Signature...
			let sig = socket.signature
			XCTAssertNotNil(sig)
			
			// Check to ensure the family, type and protocol are correct...
			XCTAssertEqual(sig!.protocolFamily, Socket.ProtocolFamily.inet)
			XCTAssertEqual(sig!.socketType, Socket.SocketType.stream)
			XCTAssertEqual(sig!.proto, Socket.SocketProtocol.tcp)
            
			socket.close()
			XCTAssertFalse(socket.isActive)
			
        } catch let error {
			
           // See if it's a socket error or something else...
            guard let socketError = error as? Socket.Error else {
                
                print("Unexpected error...")
				XCTFail()
				return
            }
            
            print("Error reported: \(socketError.description)")
			XCTFail()
        }
	}
	
	func testCreateIPV6() {
		
		do {
			
			// Create the socket...
			let socket = try createHelper(family: .inet6)
			
			// Get the Signature...
			let sig = socket.signature
			XCTAssertNotNil(sig)
			
			// Check to ensure the family, type and protocol are correct...
			XCTAssertEqual(sig!.protocolFamily, Socket.ProtocolFamily.inet6)
			XCTAssertEqual(sig!.socketType, Socket.SocketType.stream)
			XCTAssertEqual(sig!.proto, Socket.SocketProtocol.tcp)
			
			socket.close()
			XCTAssertFalse(socket.isActive)
			
		} catch let error {
			
			// See if it's a socket error or something else...
			guard let socketError = error as? Socket.Error else {
				
				print("Unexpected error...")
				XCTFail()
				return
			}
			
			print("Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testListen() {
		
		do {

			// Create the socket..
			let socket = try createHelper()
			
			// Listen on the port...
			try socket.listen(on: Int(port), maxBacklogSize: 10)
			XCTAssertTrue(socket.isListening)
			XCTAssertEqual(socket.listeningPort, port)
			
			// Close the socket...
			socket.close()
			XCTAssertFalse(socket.isActive)
			
		} catch let error {
			
			// See if it's a socket error or something else...
			guard let socketError = error as? Socket.Error else {
				
				print("Unexpected error...")
				XCTFail()
				return
			}
			
			print("Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testConnect() {
		
		do {
			
			// Create the socket..
			let socket = try createHelper()
			
			// Listen on the port...
			try socket.listen(on: Int(port), maxBacklogSize: 10)
			XCTAssertTrue(socket.isListening)
			XCTAssertEqual(socket.listeningPort, port)
			
			// Create a signature...
			let signature = try Socket.Signature(socketType: .stream, proto: .tcp, hostname: host, port: port)
			XCTAssertNotNil(signature)
			
			// Create a connected socket using the signature...
			let socket2 = try Socket.create(connectedUsing: signature!)
			XCTAssertNotNil(socket2)
			XCTAssertTrue(socket2.isConnected)
			
			// Close the socket...
			socket.close()
			XCTAssertFalse(socket.isActive)
			socket2.close()
			XCTAssertFalse(socket2.isActive)
			
		} catch let error {
			
			// See if it's a socket error or something else...
			guard let socketError = error as? Socket.Error else {
				
				print("Unexpected error...")
				XCTFail()
				return
			}
			
			print("Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testConnectTo() {
		
		do {
			
			// Create the socket..
			let socket = try createHelper()
			
			// Listen on the port...
			try socket.listen(on: Int(port), maxBacklogSize: 10)
			XCTAssertTrue(socket.isListening)
			XCTAssertEqual(socket.listeningPort, port)
			
			// Create a second socket...
			let socket2 = try createHelper()
			XCTAssertNotNil(socket2)
			
			// Now attempt to connect to the listening socket...
			try socket2.connect(to: host, port: port)
			XCTAssertTrue(socket2.isConnected)
			
			// Close the socket...
			socket.close()
			XCTAssertFalse(socket.isActive)
			socket2.close()
			XCTAssertFalse(socket2.isActive)
			
		} catch let error {
			
			// See if it's a socket error or something else...
			guard let socketError = error as? Socket.Error else {
				
				print("Unexpected error...")
				XCTFail()
				return
			}
			
			print("Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testHostnameAndPort() {
		
		do {
			
			// Create the socket..
			let socket = try createHelper()
			
			// Listen on the port...
			try socket.listen(on: Int(port), maxBacklogSize: 10)
			XCTAssertTrue(socket.isListening)
			XCTAssertEqual(socket.listeningPort, port)
			
			// Create a signature...
			let signature = try Socket.Signature(socketType: .stream, proto: .tcp, hostname: host, port: port)
			XCTAssertNotNil(signature)
			
			// Create a connected socket using the signature...
			let socket2 = try Socket.create(connectedUsing: signature!)
			XCTAssertNotNil(socket2)
			XCTAssertTrue(socket2.isConnected)
			
			let address = socket2.signature?.address
			XCTAssertNotNil(address)
			
			let (theHost, thePort) = Socket.hostnameAndPort(from: address!)!
			XCTAssertEqual(host, theHost)
			XCTAssertEqual(port, thePort)
			
			// Close the socket...
			socket.close()
			XCTAssertFalse(socket.isActive)
			socket2.close()
			XCTAssertFalse(socket2.isActive)
			
		} catch let error {
			
			// See if it's a socket error or something else...
			guard let socketError = error as? Socket.Error else {
				
				print("Unexpected error...")
				XCTFail()
				return
			}
			
			print("Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testBlocking() {
		
		do {
			
			// Create the socket...
			let socket = try createHelper()

			// Should be blocking...
			XCTAssertTrue(socket.isBlocking)
			
			// Set to non-blocking...
			try socket.setBlocking(mode: false)
			XCTAssertFalse(socket.isBlocking)
			
			// Close the socket...
			socket.close()
			XCTAssertFalse(socket.isActive)
			
		} catch let error {
			
			// See if it's a socket error or something else...
			guard let socketError = error as? Socket.Error else {
				
				print("Unexpected error...")
				XCTFail()
				return
			}
			
			print("Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	static var allTests = [
		("testDefaultCreate", testDefaultCreate),
		("testCreateIPV6", testCreateIPV6),
		("testListen", testListen),
		("testConnect", testConnect),
		("testConnectTo", testConnectTo),
		("testHostnameAndPort", testHostnameAndPort),
		("testBlocking", testBlocking),
	]
}
