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
import Foundation
import Dispatch

#if os(Linux)
import Glibc
#endif

@testable import Socket

class SocketTests: XCTestCase {
	
	let QUIT: String = "QUIT"
	let port: Int32 = 1337
	let host: String = "127.0.0.1"
	
	
	override func setUp() {

		super.setUp()
    }
    
    override func tearDown() {

		super.tearDown()
    }
	
	func createHelper(family: Socket.ProtocolFamily = .inet) throws -> Socket {
		
		let socket = try Socket.create(family: family)
		XCTAssertNotNil(socket)
		XCTAssertFalse(socket.isConnected)
		XCTAssertTrue(socket.isBlocking)
		
		return socket
	}
	
	func launchServerHelper() {
		
		let queue: DispatchQueue? = DispatchQueue.global(qos: .userInteractive)
		guard let pQueue = queue else {
			
			print("Unable to access global interactive QOS queue")
			XCTFail()
			return
		}
		
		pQueue.async { [unowned self] in
			
			do {
				
				try self.serverHelper()
				
			} catch let error {
				
				guard let socketError = error as? Socket.Error else {
					
					print("Unexpected error...")
					XCTFail()
					return
				}
				
				print("Error reported:\n \(socketError.description)")
				XCTFail()
			}
		}
	}
	
	func serverHelper() throws {
		
		var keepRunning: Bool = true
		var listenSocket: Socket? = nil
		
		do {
			
			try listenSocket = Socket.create()
			
			guard let listener = listenSocket else {
				
				print("Unable to unwrap socket...")
				XCTFail()
				return
			}
			
			try listener.listen(on: Int(port), maxBacklogSize: 10)
			
			print("Listening on port: \(port)")
			
			let socket = try listener.acceptClientConnection()
			
			print("Accepted connection from: \(socket.remoteHostname) on port \(socket.remotePort), Secure? \(socket.signature!.isSecure)")
			
			try socket.write(from: "Hello, type 'QUIT' to end session\n")
			
			var bytesRead = 0
			repeat {
				
				var readData = Data()
				bytesRead = try socket.read(into: &readData)
				
				if bytesRead > 0 {
					
					guard let response = NSString(data: readData, encoding: String.Encoding.utf8.rawValue) else {
						
						print("Error decoding response...")
						readData.count = 0
						XCTFail()
						break
					}
					
					if response.hasPrefix(QUIT) {
						
						keepRunning = false
					}
					
					print("Server received from connection at \(socket.remoteHostname):\(socket.remotePort): \(response) ")
					let reply = "Server response: \n\(response)\n"
					try socket.write(from: reply)
					
				}
				
				if bytesRead == 0 {
					
					break
				}
				
			} while keepRunning
			
			socket.close()
			XCTAssertFalse(socket.isActive)
			
		} catch let error {
			
			guard let socketError = error as? Socket.Error else {
				
				print("Unexpected error...")
				XCTFail()
				return
			}
			
			print("Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func readAndPrint(socket: Socket, data: inout Data) throws {
		
		data.count = 0
		let	bytesRead = try socket.read(into: &data)
		if bytesRead > 0 {
			
			print("Read \(bytesRead) from socket...")
			
			guard let response = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) else {
				
				print("Error accessing received data...")
				XCTFail()
				return
			}
			
			print("Response:\n\(response)")
			
		}
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
			
			// Now back to blocking...
			try socket.setBlocking(mode: true)
			XCTAssertTrue(socket.isBlocking)
			
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
	
	func testIsReadableWritable() {
		
		do {
			
			// Create the socket...
			let socket = try createHelper()

			defer {
				// Close the socket...
				socket.close()
				XCTAssertFalse(socket.isActive)
			}
			
			// Expect this to fail with Socket.SOCKET_ERR_NOT_CONNECTED exception...
			_ = try socket.isReadableOrWritable()
			XCTFail()
			
		} catch let error {
			
			// See if it's a socket error or something else...
			guard let socketError = error as? Socket.Error else {
				
				print("Unexpected error...")
				XCTFail()
				return
			}
			
			print("Error reported: \(socketError.description)")
			XCTAssertEqual(socketError.errorCode, Int32(Socket.SOCKET_ERR_NOT_CONNECTED))
		}
	}
	
	func testReadWrite() {
		
		let hostname = "127.0.0.1"
		let port: Int32 = 1337
		
		let bufSize = 4096
		var data = Data()
		
		do {
			
			// Launch the server helper...
			launchServerHelper()
			
			#if os(Linux)
				// On Linux need to wait for the server to come up...
				_ = Glibc.sleep(2)
				
			#endif
			
			// Create the signature...
			let signature = try Socket.Signature(socketType: .stream, proto: .tcp, hostname: hostname, port: port)!
			
			// Create the socket...
			let socket = try createHelper()

			// Defer cleanup...
			defer {
				// Close the socket...
				socket.close()
				XCTAssertFalse(socket.isActive)
			}
			
			// Connect to the server helper...
			try socket.connect(using: signature)
			if !socket.isConnected {
				
				fatalError("Failed to connect to the server...")
			}
			
			print("\nConnected to host: \(hostname):\(port)")
			print("\tSocket signature: \(socket.signature!.description)\n")
			
			try readAndPrint(socket: socket, data: &data)
			
			let hello = "Hello from client..."
			try socket.write(from: hello)
			
			print("Wrote '\(hello)' to socket...")
			
			try readAndPrint(socket: socket, data: &data)
			
			try socket.write(from: "QUIT")
			
			print("Sent quit to server...")
			
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
		("testIsReadableWritable", testIsReadableWritable),
		("testReadWrite", testReadWrite),
	]
}
