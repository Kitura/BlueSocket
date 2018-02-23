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
	let path: String = "/tmp/server.test.socket"
	
	
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
	
	func createUDPHelper(family: Socket.ProtocolFamily = .inet) throws -> Socket {
		
		let socket = try Socket.create(family: family, type: .datagram, proto: .udp)
		XCTAssertNotNil(socket)
		XCTAssertFalse(socket.isConnected)
		XCTAssertTrue(socket.isBlocking)
		
		return socket
	}
	
	func launchServerHelper(family: Socket.ProtocolFamily = .inet) {
		
		let queue: DispatchQueue? = DispatchQueue.global(qos: .userInteractive)
		guard let pQueue = queue else {
			
			print("Unable to access global interactive QOS queue")
			XCTFail()
			return
		}
		
		pQueue.async { [unowned self] in
			
			do {
				
				try self.serverHelper(family: family)
				
			} catch let error {
				
				guard let socketError = error as? Socket.Error else {
					
					print("Unexpected error...")
					XCTFail()
					return
				}
				
				print("launchServerHelper Error reported:\n \(socketError.description)")
				XCTFail()
			}
		}
	}
	
	func serverHelper(family: Socket.ProtocolFamily = .inet) throws {
		
		var keepRunning: Bool = true
		var listenSocket: Socket? = nil
		
		do {
			
			try listenSocket = Socket.create(family: family)
			
			guard let listener = listenSocket else {
				
				print("Unable to unwrap socket...")
				XCTFail()
				return
			}
			
			var socket: Socket
			
			// Are we setting uo a TCP or UNIX based server?
			if family == .inet || family == .inet6 {
			
				// Setting up TCP...
				try listener.listen(on: Int(port), maxBacklogSize: 10)

				print("Listening on port: \(port)")
				
				socket = try listener.acceptClientConnection()
				
				print("Accepted connection from: \(socket.remoteHostname) on port \(socket.remotePort), Secure? \(socket.signature!.isSecure)")
				
			} else {
				
				// Setting up UNIX...
				try listener.listen(on: path, maxBacklogSize: 10)

				print("Listening on path: \(path)")
				
				socket = try listener.acceptClientConnection()
				
				print("Accepted connection from: \(socket.remotePath!), Secure? \(socket.signature!.isSecure)")
				
			}
		
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
					
					// TCP or UNIX?
					if family == .inet || family == .inet6 {
						print("Server received from connection at \(socket.remoteHostname):\(socket.remotePort): \(response) ")
					} else {
						print("Server received from connection at \(socket.remotePath!): \(response) ")
					}
					
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
			
			// This error is expected when we're shutting it down...
			if socketError.errorCode == Int32(Socket.SOCKET_ERR_WRITE_FAILED) {
				return
			}
			print("serverHelper Error reported: \(socketError.description)")
			XCTFail()
		}
	}

	func launchUDPHelper(family: Socket.ProtocolFamily = .inet) {
		
		let queue: DispatchQueue? = DispatchQueue.global(qos: .userInteractive)
		guard let pQueue = queue else {

			print("Unable to access global interactive QOS queue")
			XCTFail()
			return
		}

		pQueue.async { [unowned self] in

			do {

				try self.udpHelper(family: family)

			} catch let error {

				guard let socketError = error as? Socket.Error else {

					print("Unexpected error...")
					XCTFail()
					return
				}

				print("launchUDPHelper Error reported:\n \(socketError.description)")
				XCTFail()
			}
		}
	}

	func udpHelper(family: Socket.ProtocolFamily) throws {
		
		var keepRunning = true
		do {
			let socket = try createUDPHelper()
			try socket.listen(on: Int(port))

			repeat {
				
				var data = Data()
				
				let (bytesRead, address) = try socket.readDatagram(into: &data)

				guard let response = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {

					print("Error decoding response...")
					data.count = 0
					XCTFail()
					return
				}

				if response.hasPrefix(QUIT) {
					keepRunning = false
				}

				let (remoteHost, remotePort) = Socket.hostnameAndPort(from: address!)!
				print("Received \(bytesRead) bytes from \(remoteHost):\(remotePort): \(response)\n")
				print("Sending response")
				let responseString: String = "Server response: \n\(response)\n"
				try socket.write(from: responseString.data(using: String.Encoding.utf8)!, to: address!)
				
			} while keepRunning

		} catch let error {
			
			guard let socketError = error as? Socket.Error else {

				print("Unexpected error...")
				XCTFail()
				return
			}

			// This error is expected when we're shutting it down...
			if socketError.errorCode == Int32(Socket.SOCKET_ERR_WRITE_FAILED) {
				return
			}
			print("udpHelper Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func readAndPrint(socket: Socket, data: inout Data) throws -> String? {
		
		data.count = 0
		let	bytesRead = try socket.read(into: &data)
		if bytesRead > 0 {
			
			print("Read \(bytesRead) from socket...")
			
			guard let response = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) else {
				
				print("Error accessing received data...")
				XCTFail()
				return nil
			}
			
			print("Response:\n\(response)")
			return String(describing: response)
		}

		return nil
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
            
            print("testDefaultCreate Error reported: \(socketError.description)")
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
			
			print("testCreateIPV6 Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testCreateUnix() {
		
		do {
			
			// Create the socket...
			let socket = try createHelper(family: .unix)
			
			// Get the Signature...
			let sig = socket.signature
			XCTAssertNotNil(sig)
			
			// Check to ensure the family, type and protocol are correct...
			XCTAssertEqual(sig!.protocolFamily, Socket.ProtocolFamily.unix)
			XCTAssertEqual(sig!.socketType, Socket.SocketType.stream)
			XCTAssertEqual(sig!.proto, Socket.SocketProtocol.unix)
			
			socket.close()
			XCTAssertFalse(socket.isActive)
			
		} catch let error {
			
			// See if it's a socket error or something else...
			guard let socketError = error as? Socket.Error else {
				
				print("Unexpected error...")
				XCTFail()
				return
			}
			
			print("testCreateUnix Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testCreateUDP() {
		
		do {
			
			// Create the socket...
			let socket = try createUDPHelper()
			
			// Get the Signature...
			let sig = socket.signature
			XCTAssertNotNil(sig)
			
			// Check to ensure the family, type and protocol are correct...
			XCTAssertEqual(sig!.protocolFamily, Socket.ProtocolFamily.inet)
			XCTAssertEqual(sig!.socketType, Socket.SocketType.datagram)
			XCTAssertEqual(sig!.proto, Socket.SocketProtocol.udp)
			
			socket.close()
			XCTAssertFalse(socket.isActive)
			
		} catch let error {
			
			// See if it's a socket error or something else...
			guard let socketError = error as? Socket.Error else {
				
				print("Unexpected error...")
				XCTFail()
				return
			}
			
			print("testCreateUnix Error reported: \(socketError.description)")
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
			
			print("testListen Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testListenPort0() {
		
		do {
			
			// Create the socket..
			let socket = try createHelper()
			
			// Listen on the port...
			try socket.listen(on: Int(0), maxBacklogSize: 10)
			XCTAssertTrue(socket.isListening)
			XCTAssertGreaterThan(socket.listeningPort, 0)
			print("Listening port: \(socket.listeningPort)")
			
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
			
			print("testListenPort0 Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testListenUnix() {
		
		do {
			
			// Create the socket..
			let socket = try createHelper(family: .unix)
			
			// Listen on the port...
			try socket.listen(on: path, maxBacklogSize: 10)
			XCTAssertTrue(socket.isListening)
			XCTAssertEqual(socket.remotePath, path)
			
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
			
			print("testListenUnix Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testListenUDP() {
		
		let queue: DispatchQueue? = DispatchQueue.global(qos: .userInteractive)
		guard let pQueue = queue else {
			
			print("Unable to access global interactive QOS queue")
			XCTFail()
			return
		}
		
		do {
			
			// Create the socket..
			let socket = try createUDPHelper()
			
			pQueue.async { [unowned self, socket] in
				
				do {
					// Listen on the port...
					var data = Data()
					_ = try socket.listen(forMessage: &data, on: Int(self.port))
					
				} catch let error {
					
					// See if it's a socket error or something else...
					guard let socketError = error as? Socket.Error else {
						
						print("Unexpected error...")
						XCTFail()
						return
					}
					
					if socketError.errorCode != Int32(Socket.SOCKET_ERR_RECV_FAILED) {
						print("testListenUDP Error reported: \(socketError.description)")
						XCTFail()
					}
				}
			}
			
			// Give the thread time to start...
			#if os(Linux)
				_ = Glibc.sleep(1)
			#else
				_ = Darwin.sleep(1)
			#endif
			
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
			
			print("testListenUDP Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testListenPort0UDP() {
		
		let queue: DispatchQueue? = DispatchQueue.global(qos: .userInteractive)
		guard let pQueue = queue else {
			
			print("Unable to access global interactive QOS queue")
			XCTFail()
			return
		}
		
		do {
			
			// Create the socket..
			let socket = try createUDPHelper()
			
			pQueue.async { [unowned socket] in
				
				do {
					// Listen on the port...
					var data = Data()
					_ = try socket.listen(forMessage: &data, on: Int(0))
					
				} catch let error {
					
					// See if it's a socket error or something else...
					guard let socketError = error as? Socket.Error else {
						
						print("Unexpected error...")
						XCTFail()
						return
					}
					
					if socketError.errorCode != Int32(Socket.SOCKET_ERR_RECV_FAILED) {
						print("testListenPort0UDP Error reported: \(socketError.description)")
						XCTFail()
					}
				}
			}
			
			// Give the thread time to start...
			#if os(Linux)
				_ = Glibc.sleep(1)
			#else
				_ = Darwin.sleep(1)
			#endif
			
			XCTAssertTrue(socket.isListening)
			XCTAssertGreaterThan(socket.listeningPort, 0)
			print("Listening port: \(socket.listeningPort)")
			
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
			
			print("testListenPort0UDP Error reported: \(socketError.description)")
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
			let signature = try Socket.Signature(protocolFamily: .inet, socketType: .stream, proto: .tcp, hostname: host, port: port)
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
			
			print("testConnect Error reported: \(socketError.description)")
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
			
			print("testConnectTo Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testConnectToWithTimeout() {
		
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
			try socket2.connect(to: host, port: port, timeout: 1)
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
			
			print("testConnectTo Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testConnectToPath() {
		
		do {
			
			// Create the socket..
			let socket = try createHelper(family: .unix)
			
			// Listen on the port...
			try socket.listen(on: path, maxBacklogSize: 10)
			XCTAssertTrue(socket.isListening)
			
			// Create a second socket...
			let socket2 = try createHelper(family: .unix)
			XCTAssertNotNil(socket2)
			
			// Now attempt to connect to the listening socket...
			try socket2.connect(to: path)
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
			
			print("testConnectToPath Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testConnectPort0() {
		
		do {
			
			// Create the socket..
			let socket = try createHelper()
			
			// Listen on the port...
			try socket.listen(on: Int(0), maxBacklogSize: 10)
			XCTAssertTrue(socket.isListening)
			XCTAssertGreaterThan(socket.listeningPort, 0)
			print("Listener signature: \(socket.signature?.description as String?)")
			
			// Create a signature...
			let signature = try Socket.Signature(protocolFamily: .inet, socketType: .stream, proto: .tcp, hostname: socket.remoteHostname, port: socket.remotePort)
			XCTAssertNotNil(signature)
			
			// Create a connected socket using the signature...
			let socket2 = try Socket.create(connectedUsing: signature!)
			XCTAssertNotNil(socket2)
			XCTAssertTrue(socket2.isConnected)
			print("Connect signature: \(socket2.signature?.description as String?)")
			
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
			
			print("testConnectPort0 Error reported: \(socketError.description)")
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
			let signature = try Socket.Signature(protocolFamily: .inet, socketType: .stream, proto: .tcp, hostname: host, port: port)
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
			
			print("testHostnameAndPort Error reported: \(socketError.description)")
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
			
			print("testBlocking Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testSetReadTimeout() {
		
		do {
			
			// Create the socket...
			let socket = try createUDPHelper()
			
			// Set a timeout of 300 ms...
			try socket.setReadTimeout(value: UInt(300))
			
			// Try a read with nobody listening...
			var data: Data = Data()
			let (bytes, addr) = try socket.readDatagram(into: &data)
			XCTAssertEqual(bytes, 0)
			XCTAssertNil(addr)
			XCTAssertEqual(errno, EAGAIN)
			
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
			
			print("testSetReadTimeout Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testSetWriteTimeout() {
		
		do {
			
			// Create the socket...
			let socket = try createUDPHelper()
			
			// Set a timeout of 300 ms...
			try socket.setWriteTimeout(value: UInt(300))
			
			// Try a write to a `bogus` address...
			let addr = Socket.createAddress(for: "foobar.org", on: 2142)
			XCTAssertNotNil(addr)
			
			// It should be noted that this write should succeed...
			//	If this was a TCP socket, the results would be different...
			let bytesWritten = try socket.write(from: "Hello from UDP".data(using: .utf8)!, to: addr!)
			XCTAssertEqual(bytesWritten, 14)
			
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
			
			print("testSetWriteTimeout Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testIsReadableWritableFail() {
		
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
			
			print("testIsReadableWritableFail Error reported: \(socketError.description)")
			XCTAssertEqual(socketError.errorCode, Int32(Socket.SOCKET_ERR_NOT_CONNECTED))
		}
	}
	
	func testIsReadableWritable() {
		
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
			
			// Test to see if it's readable or writable...
			var readable: Bool = false
			var writable: Bool = false
			(readable, writable) = try socket2.isReadableOrWritable()
			print("Socket2 is readable: \(readable), writable: \(writable)")
			
			// Socket should be writable but NOT readable...
			XCTAssertTrue(writable, "Socket 2 is not writable but should be...")
			XCTAssertFalse(readable, "Socket 2 is readable and shouldn't be...")

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
			
			print("testConnectTo Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testFDSetBitFields() {
		var fdSet = fd_set()
		fdSet.zero()
		
		// The default number of max open file descriptors on Linux is 1024. On macOS,
		//	the default is unlimited.  I think checking for 1024 should be enough...
		for i: Int32 in 0...1024 {
			fdSet.set(i)
			XCTAssertTrue(fdSet.isSet(i))
			fdSet.clear(i)
			XCTAssertFalse(fdSet.isSet(i))
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
			
			// Need to wait for the server to come up...
			#if os(Linux)
				_ = Glibc.sleep(2)
			#else
				_ = Darwin.sleep(2)
			#endif
			
			// Create the signature...
			let signature = try Socket.Signature(protocolFamily: .inet, socketType: .stream, proto: .tcp, hostname: hostname, port: port)!
			
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
			
			_ = try readAndPrint(socket: socket, data: &data)
			
			let hello = "Hello from client..."
			try socket.write(from: hello)
			
			print("Wrote '\(hello)' to socket...")
			
			let response = try readAndPrint(socket: socket, data: &data)

			XCTAssertNotNil(response)
			XCTAssertEqual(response, "Server response: \n\(hello)\n")
			
			try socket.write(from: "QUIT")
			
			print("Sent quit to server...")
			
			// Need to wait for the server to go down before continuing...
			#if os(Linux)
				_ = Glibc.sleep(1)
			#else
				_ = Darwin.sleep(1)
			#endif
			
		} catch let error {
			
			// See if it's a socket error or something else...
			guard let socketError = error as? Socket.Error else {
				
				print("Unexpected error...")
				XCTFail()
				return
			}
			
			print("testReadWrite Error reported: \(socketError.description)")
			XCTFail()
		}
		
	}

	func testTruncateTCP() {

		let hostname = "127.0.0.1"
		let port: Int32 = 1337

		let bufSize = 4096
		var data = Data()

		do {

			// Launch the server helper...
			launchServerHelper()

			// Need to wait for the server to come up...
			#if os(Linux)
				_ = Glibc.sleep(2)
			#else
				_ = Darwin.sleep(2)
			#endif

			// Create the signature...
			let signature = try Socket.Signature(protocolFamily: .inet, socketType: .stream, proto: .tcp, hostname: hostname, port: port)!

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

			_ = try readAndPrint(socket: socket, data: &data)

			let hello = "Hello from client..."
			try socket.write(from: hello)

			print("Wrote '\(hello)' to socket...")

			let buf = UnsafeMutablePointer<CChar>.allocate(capacity: 19)
			#if swift(>=4.1)
				buf.initialize(repeating: 0, count: 19)
			#else
				buf.initialize(to: 0, count: 19)
			#endif

			defer {
				#if swift(>=4.1)
					buf.deinitialize(count: 19)
					buf.deallocate()
				#else
					buf.deinitialize()
					buf.deallocate(capacity: 19)
				#endif
			}

			// Save room for a null character...
			_ = try socket.read(into: buf, bufSize: 18, truncate: true)
			let response = String(cString: buf)

			XCTAssertEqual(response, "Server response: \n")

			let response2 = try readAndPrint(socket: socket, data: &data)

			XCTAssertEqual(response2, "\(hello)\n")

			try socket.write(from: "QUIT")

			print("Sent quit to server...")

			// Need to wait for the server to go down before continuing...
			#if os(Linux)
				_ = Glibc.sleep(1)
			#else
				_ = Darwin.sleep(1)
			#endif

		} catch let error {

			// See if it's a socket error or something else...
			guard let socketError = error as? Socket.Error else {

				print("Unexpected error...")
				XCTFail()
				return
			}

			print("testTruncateTCP Error reported: \(socketError.description)")
			XCTFail()
		}
		
	}

	func testReadWriteUDP() {
		
		let hostname = "127.0.0.1"
		let port: Int32 = 1337

		let bufSize = 4096
		var data = Data()

		do {
			
			self.launchUDPHelper()

			// Need to wait for the helper to come up...
			#if os(Linux)
				_ = Glibc.sleep(2)
			#else
				_ = Darwin.sleep(2)
			#endif

			let socket = try self.createUDPHelper()

			// Defer cleanup...
			defer {
				// Close the socket...
				socket.close()
				XCTAssertFalse(socket.isActive)
			}

			let addr = Socket.createAddress(for: hostname, on: port)

			XCTAssertNotNil(addr)
			try socket.write(from: "Hello from UDP".data(using: .utf8)!, to: addr!)

			var data = Data()
			var (_, address) = try socket.readDatagram(into: &data)

			guard let response = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {

				print("Error decoding response...")
				data.count = 0
				XCTFail()
				return
			}

			var (remoteHost, remotePort) = Socket.hostnameAndPort(from: address!)!
			print("Received from \(remoteHost):\(remotePort): \(response)\n")

			try socket.write(from: "Hello again".data(using: .utf8)!, to: addr!)

			let buf = UnsafeMutablePointer<CChar>.allocate(capacity: 10)
			#if swift(>=4.1)
				buf.initialize(repeating: 0, count: 10)
			#else
				buf.initialize(to: 0, count: 10)
			#endif

			defer {
				#if swift(>=4.1)
					buf.deinitialize(count: 10)
					buf.deallocate()
				#else
					buf.deinitialize()
					buf.deallocate(capacity: 10)
				#endif
			}
			
			// Save room for a null character...
			(_, address) = try socket.readDatagram(into: buf, bufSize: 9)

			let response2 = String(cString: buf)
			(remoteHost, remotePort) = Socket.hostnameAndPort(from: address!)!
			print("Received from \(remoteHost):\(remotePort): \(response2)\n")

			print("Sending quit to server...")
			try socket.write(from: "QUIT".data(using: .utf8)!, to: addr!)

			// Need to wait for the server to go down before continuing...
			#if os(Linux)
				_ = Glibc.sleep(1)
			#else
				_ = Darwin.sleep(1)
			#endif

		} catch let error {
			// See if it's a socket error or something else...
			guard let socketError = error as? Socket.Error else {

				print("Unexpected error...")
				XCTFail()
				return
			}

			print("testReadWriteUDP Error reported: \(socketError.description)")
			XCTFail()
		}
	}
	
	func testReadWriteUnix() {
		
		let bufSize = 4096
		var data = Data()
		
		do {
			
			// Launch the server helper...
			launchServerHelper(family: .unix)
			
			// Need to wait for the server to come up...
			#if os(Linux)
				_ = Glibc.sleep(2)
			#else
				_ = Darwin.sleep(2)
			#endif
			
			// Create the signature...
			let signature = try Socket.Signature(socketType: .stream, proto: .unix, path: path)!
			
			// Create the socket...
			let socket = try createHelper(family: .unix)
			
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
			
			print("\nConnected to path: \(path)")
			print("\tSocket signature: \(socket.signature!.description)\n")
			
			_ = try readAndPrint(socket: socket, data: &data)
			
			let hello = "Hello from client..."
			try socket.write(from: hello)
			
			print("Wrote '\(hello)' to socket...")
			
			let response = try readAndPrint(socket: socket, data: &data)

			XCTAssertNotNil(response)
			XCTAssertEqual(response!, "Server response: \n\(hello)\n")
			
			try socket.write(from: "QUIT")
			
			print("Sent quit to server...")
			
			// Need to wait for the server to go down before continuing...
			#if os(Linux)
				_ = Glibc.sleep(1)
			#else
				_ = Darwin.sleep(1)
			#endif
			
		} catch let error {
			
			// See if it's a socket error or something else...
			guard let socketError = error as? Socket.Error else {
				
				print("Unexpected error...")
				XCTFail()
				return
			}
			
			print("testReadWriteUnix Error reported: \(socketError.description)")
			XCTFail()
		}
	}
    
	static var allTests = [
		("testDefaultCreate", testDefaultCreate),
		("testCreateIPV6", testCreateIPV6),
		("testCreateUnix", testCreateUnix),
		("testCreateUDP", testCreateUDP),
		("testListen", testListen),
		("testListenPort0", testListenPort0),
		("testListenUnix", testListenUnix),
		("testListenUDP", testListenUDP),
		("testListenPort0UDP", testListenPort0UDP),
		("testConnect", testConnect),
		("testConnectTo", testConnectTo),
		("testConnectToWithTimeout", testConnectToWithTimeout),
		("testConnectToPath", testConnectToPath),
		("testConnectPort0", testConnectPort0),
		("testHostnameAndPort", testHostnameAndPort),
		("testBlocking", testBlocking),
		("testSetReadTimeout", testSetReadTimeout),
		("testSetWriteTimeout", testSetWriteTimeout),
		("testIsReadableWritableFail", testIsReadableWritableFail),
		("testIsReadableWritable", testIsReadableWritable),
		("testFDSetBitFields", testFDSetBitFields),
		("testReadWrite", testReadWrite),
		("testTruncateTCP", testTruncateTCP),
		("testReadWriteUDP", testReadWriteUDP),
		("testReadWriteUnix", testReadWriteUnix),
	]
}
