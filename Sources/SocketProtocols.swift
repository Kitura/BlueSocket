//
//  SocketProtocols.swift
//  BlueSocket
//
//  Created by Bill Abt on 1/7/16.
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

import Foundation

// MARK: Reader

///
/// Socket reader protocol
///
public protocol SocketReader {
	
	///
	/// Reads a string.
	///
	/// - Returns: Optional String
	///
	func readString() throws -> String?
	
	///
	/// Reads all available data into an Data object.
	///
	/// - Parameter data: Data object to contain read data.
	///
	/// - Returns: Integer representing the number of bytes read.
	///
	func read(into data: inout Data) throws -> Int
	
	///
	/// Reads all available data into an NSMutableData object.
	///
	/// - Parameter data: NSMutableData object to contain read data.
	///
	/// - Returns: Integer representing the number of bytes read.
	///
	func read(into data: NSMutableData) throws -> Int
}

// MARK: Writer

///
/// Socket writer protocol
///
public protocol SocketWriter {
	
	///
	/// Writes data from Data object.
	///
	/// - Parameter data: Data object containing the data to be written.
	///
	@discardableResult func write(from data: Data) throws -> Int
	
	///
	/// Writes data from NSData object.
	///
	/// - Parameter data: NSData object containing the data to be written.
	///
	@discardableResult func write(from data: NSData) throws -> Int
	
	///
	/// Writes a string
	///
	/// - Parameter string: String data to be written.
	///
	@discardableResult func write(from string: String) throws -> Int
}

// MARK: SSLServiceDelegate

///
/// SSL Service Delegate Protocol
///
public protocol SSLServiceDelegate {
	
	///
	/// Initialize SSL Service
	///
	/// - Parameter asServer:	True for initializing a server, otherwise a client.
	///
	func initialize(asServer: Bool) throws
	
	///
	/// Deinitialize SSL Service
	///
	func deinitialize()
	
	///
	/// Processing on acceptance from a listening socket
	///
	/// - Parameter socket:	The connected Socket instance.
	///
	func onAccept(socket: Socket) throws
	
	///
	/// Processing on connection to a listening socket
	///
	/// - Parameter socket:	The connected Socket instance.
	///
	func onConnect(socket: Socket) throws
	
	///
	/// Low level writer
	///
	/// - Parameters:
	///		- buffer:		Buffer pointer.
	///		- bufSize:		Size of the buffer.
	///
	///	- Returns the number of bytes written. Zero indicates SSL shutdown, less than zero indicates error.
	///
	func send(buffer: UnsafeRawPointer, bufSize: Int) throws -> Int
	
	///
	/// Low level reader
	///
	/// - Parameters:
	///		- buffer:		Buffer pointer.
	///		- bufSize:		Size of the buffer.
	///
	///	- Returns the number of bytes read. Zero indicates SSL shutdown, less than zero indicates error.
	///
	func recv(buffer: UnsafeMutableRawPointer, bufSize: Int) throws -> Int
	
	#if os(Linux)

		// MARK: ALPN
		
		///
		/// Add a protocol to the list of supported ALPN protocol names. E.g. 'http/1.1' and 'h2'.
		///
		/// - Parameters:
		///		- proto:		The protocol name to be added (e.g. 'h2').
		///
		func addSupportedAlpnProtocol(proto: String)
		
		///
		/// The negotiated ALPN protocol that has been agreed upon during the handshaking phase.
		/// Will be nil if ALPN hasn't been used or requestsed protocol is not available.
		///
		var negotiatedAlpnProtocol: String? { get }
		
	#endif
	
}

// MARK: SSLError

///
/// SSL Service Error
///
public enum SSLError: Swift.Error, CustomStringConvertible {
	
	/// Success
	case success
	
	/// Retry needed
	case retryNeeded
	
	/// Failure with error code and reason
	case fail(Int, String)
	
	/// The error code itself
	public var code: Int {
		
		switch self {
			
		case .success:
			return 0
			
		case .retryNeeded:
			return -1
			
		case .fail(let (code, _)):
			return Int(code)
		}
	}
	
	/// Error description
	public var description: String {
		
		switch self {
			
		case .success:
			return "Success"
			
		case .retryNeeded:
			return "Retry operation"
			
		case .fail(let (_, reason)):
			return reason
		}
	}
}

