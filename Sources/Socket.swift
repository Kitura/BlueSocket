//
//  Socket.swift
//  BlueSocket
//
//  Created by Bill Abt on 11/9/15.
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

#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
	import Darwin
	import Foundation
#elseif os(Linux)
	import Foundation
	import Glibc
#endif

// MARK: Socket

public class Socket: SocketReader, SocketWriter {
	
	// MARK: Constants
	
	// MARK: -- Generic
	
	public static let SOCKET_MINIMUM_READ_BUFFER_SIZE		= 1024
	public static let SOCKET_DEFAULT_READ_BUFFER_SIZE		= 4096
	public static let SOCKET_DEFAULT_MAX_CONNECTIONS		= 5
	
	public static let SOCKET_INVALID_PORT					= Int32(0)
	public static let SOCKET_INVALID_DESCRIPTOR 			= Int32(-1)
	
	public static let INADDR_ANY							= in_addr_t(0)
	
	public static let NO_HOSTNAME							= "No hostname"
	
	// MARK: -- Errors: Domain and Codes
	
	public static let SOCKET_ERR_DOMAIN						= "com.ibm.oss.Socket.ErrorDomain"
	
	public static let SOCKET_ERR_UNABLE_TO_CREATE_SOCKET    = -9999
	public static let SOCKET_ERR_BAD_DESCRIPTOR				= -9998
	public static let SOCKET_ERR_ALREADY_CONNECTED			= -9997
	public static let SOCKET_ERR_NOT_CONNECTED				= -9996
	public static let SOCKET_ERR_NOT_LISTENING				= -9995
	public static let SOCKET_ERR_ACCEPT_FAILED				= -9994
	public static let SOCKET_ERR_SETSOCKOPT_FAILED			= -9993
	public static let SOCKET_ERR_BIND_FAILED				= -9992
	public static let SOCKET_ERR_INVALID_HOSTNAME			= -9991
	public static let SOCKET_ERR_GETADDRINFO_FAILED			= -9990
	public static let SOCKET_ERR_CONNECT_FAILED				= -9989
	public static let SOCKET_ERR_MISSING_CONNECTION_DATA	= -9988
	public static let SOCKET_ERR_SELECT_FAILED				= -9987
	public static let SOCKET_ERR_LISTEN_FAILED				= -9986
	public static let SOCKET_ERR_INVALID_BUFFER				= -9985
	public static let SOCKET_ERR_INVALID_BUFFER_SIZE		= -9984
	public static let SOCKET_ERR_RECV_FAILED				= -9983
	public static let SOCKET_ERR_RECV_BUFFER_TOO_SMALL		= -9982
	public static let SOCKET_ERR_WRITE_FAILED				= -9981
	public static let SOCKET_ERR_GET_FCNTL_FAILED			= -9980
	public static let SOCKET_ERR_SET_FCNTL_FAILED			= -9979
	public static let SOCKET_ERR_NOT_IMPLEMENTED			= -9978
	public static let SOCKET_ERR_NOT_SUPPORTED_YET			= -9977
	public static let SOCKET_ERR_BAD_SIGNATURE_PARAMETERS	= -9976
	public static let SOCKET_ERR_INTERNAL					= -9975
	public static let SOCKET_ERR_WRONG_PROTOCOL				= -9974
	
	// MARK: Enums
	
	// MARK: -- ProtocolFamily
	
	///
	/// Socket Protocol Family Values
	///
	/// **Note:** Only the following are supported at this time:
	///			INET = AF_INET (IPV4)
	///			INET6 = AF_INET6 (IPV6)
	///
	public enum ProtocolFamily {
		
		case INET, INET6
		
		///
		/// Return the value for a particular case
		///
		var value: Int32 {
			
			switch self {
				
			case .INET:
				return Int32(AF_INET)
				
			case .INET6:
				return Int32(AF_INET6)
			}
		}
		///
		/// Return enum equivalent of a raw value
		///
		/// - Parameter forValue: Value for which enum value is desired
		///
		/// - Returns: Optional contain enum value or nil
		///
		static func getFamily(forValue: Int32) -> ProtocolFamily? {
			
			switch forValue {
				
			case Int32(AF_INET):
				return .INET
			case Int32(AF_INET6):
				return .INET6
			default:
				return nil
			}
		}
		
	}
	
	// MARK: -- SocketType
	
	///
	/// Socket Type Values
	///
	/// **Note:** Only the following are supported at this time:
	///			STREAM = SOCK_STREAM (Provides sequenced, reliable, two-way, connection-based byte streams.)
	///			DGRAM = SOCK_DGRAM (Supports datagrams (connectionless, unreliable messages of a fixed maximum length).)
	///
	public enum SocketType {
		
		case STREAM, DGRAM
		
		///
		/// Return the value for a particular case
		///
		var value: Int32 {
			
			switch self {
				
			case .STREAM:
				#if os(Linux)
					return Int32(SOCK_STREAM.rawValue)
				#else
					return SOCK_STREAM
				#endif
			case .DGRAM:
				#if os(Linux)
					return Int32(SOCK_DGRAM.rawValue)
				#else
					return SOCK_DGRAM
				#endif
			}
		}
		
		///
		/// Return enum equivalent of a raw value
		///
		/// - Parameter forValue: Value for which enum value is desired
		///
		/// - Returns: Optional contain enum value or nil
		///
		static func getType(forValue: Int32) -> SocketType? {
			
			#if os(Linux)
				switch forValue {
					
				case Int32(SOCK_STREAM.rawValue):
					return .STREAM
				case Int32(SOCK_DGRAM.rawValue):
					return .DGRAM
				default:
					return nil
				}
			#else
				switch forValue {
					
				case SOCK_STREAM:
					return .STREAM
				case SOCK_DGRAM:
					return .DGRAM
				default:
					return nil
				}
			#endif
		}
	}
	
	// MARK: -- SocketProtocol
	
	///
	/// Socket Protocol Values
	///
	/// **Note:** Only the following are supported at this time:
	///			TCP = IPPROTO_TCP
	///			UDP = IPPROTO_UDP
	///
	public enum SocketProtocol: Int32 {
		
		case TCP, UDP
		
		///
		/// Return the value for a particular case
		///
		var value: Int32 {
			
			switch self {
				
			case .TCP:
				return Int32(IPPROTO_TCP)
			case .UDP:
				return Int32(IPPROTO_UDP)
			}
		}
		
		///
		/// Return enum equivalent of a raw value
		///
		/// - Parameter forValue: Value for which enum value is desired
		///
		/// - Returns: Optional contain enum value or nil
		///
		static func getProtocol(forValue: Int32) -> SocketProtocol? {
			
			switch forValue {
				
			case Int32(IPPROTO_TCP):
				return .TCP
			case Int32(IPPROTO_UDP):
				return .UDP
			default:
				return nil
			}
		}
	}
	
	// MARK: -- Socket Address
	
	///
	/// Socket Address
	///
	public enum Address {
		
		case IPV4(sockaddr_in)
		case IPV6(sockaddr_in6)
		
		///
		/// Size of address
		///
		public var size: Int {
			
			switch self {
				
			case .IPV4(let addr):
				return sizeofValue(addr)
			case .IPV6(let addr):
				return sizeofValue(addr)
			}
		}
		
		///
		/// Cast as sockaddr.
		///
		public var addr: sockaddr {
			
			switch self {
				
			case .IPV4(let addr):
				return addr.asAddr()
				
			case .IPV6(let addr):
				return addr.asAddr()
			}
		}
	}
	
	// MARK: Structs
	
	// MARK: -- Signature
	
	public struct Signature: CustomStringConvertible {
		
		// MARK: -- Public Properties
		
		///
		/// Protocol Family
		///
		public private(set) var protocolFamily: ProtocolFamily
		
		///
		/// Socket Type
		///
		public private(set) var socketType: SocketType
		
		///
		/// Socket Protocol
		///
		public private(set) var proto: SocketProtocol
		
		///
		/// Host name for connection
		///
		public private(set) var hostname: String? = Socket.NO_HOSTNAME
		
		///
		/// Port for connection
		///
		public private(set) var port: Int32 = Socket.SOCKET_INVALID_PORT
		
		///
		/// Address info for socket.
		///
		public private(set) var address: Address? = nil
		
		///
		/// Returns a string description of the error.
		///
		public var description: String {
			
			return "Signature: family: \(protocolFamily), type: \(socketType), protocol: \(proto), address: \(address), hostname: \(hostname), port: \(port)"
		}
		
		// MARK: -- Public Functions
		
		///
		/// Create a socket signature
		///
		/// - Parameters:
		///		- protocolFamily:	The family of the socket to create.
		///		- socketType:		The type of socket to create.
		///		- proto:			The protocool to use for the socket.
		/// 	- address:			Address info for the socket.
		///
		/// - Returns: New Signature instance
		///
		public init?(protocolFamily: Int32, socketType: Int32, proto: Int32, address: Address?) throws {
			
			guard let family = ProtocolFamily.getFamily(forValue: protocolFamily),
				let type = SocketType.getType(forValue: socketType),
				let pro = SocketProtocol.getProtocol(forValue: proto) else {
					
					throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Bad family, type or protocol passed.")
			}
			
			self.protocolFamily = family
			self.socketType = type
			self.proto = pro
			
			self.address = address
			
		}
		
		///
		/// Create a socket signature
		///
		///	- Parameters:
		///		- socketType:		The type of socket to create.
		///		- proto:			The protocool to use for the socket.
		/// 	- hostname:			Hostname for this signature.
		/// 	- port:				Port for this signature.
		///
		/// - Returns: New Signature instance
		///
		public init?(socketType: SocketType, proto: SocketProtocol, hostname: String?, port: Int32?) throws {
			
			// Make sure we have what we need...
			guard let _ = hostname,
				let port = port else {
					
					throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Missing hostname, port or both.")
			}
			
			// Default to IPV4 socket protocol family...
			self.protocolFamily = .INET
			
			self.socketType = socketType
			self.proto = proto
			
			self.hostname = hostname
			self.port = port
		}
		
		///
		/// Create a socket signature
		///
		/// - Parameters:
		///		- protocolFamily:	The family of the socket to create.
		///		- socketType:		The type of socket to create.
		///		- proto:			The protocool to use for the socket.
		/// 	- address:			Address info for the socket.
		/// 	- hostname:			Hostname for this signature.
		/// 	- port:				Port for this signature.
		///
		/// - Returns: New Signature instance
		///
		private init?(protocolFamily: Int32, socketType: Int32, proto: Int32, address: Address?, hostname: String?, port: Int32?) throws {
			
			// This constructor requires all items be present...
			guard let family = ProtocolFamily.getFamily(forValue: protocolFamily),
				let type = SocketType.getType(forValue: socketType),
				let pro = SocketProtocol.getProtocol(forValue: proto),
				let _ = hostname,
				let port = port else {
					
					throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Incomplete parameters.")
			}
			
			self.protocolFamily = family
			self.socketType = type
			self.proto = pro
			
			self.address = address
			
			self.hostname = hostname
			self.port = port
		}
	}
	
	// MARK: -- Error
	
	public class Error: ErrorProtocol, CustomStringConvertible {
		
		// MARK: -- Public Properties
		
		///
		/// The error domain.
		///
		public let domain: String = SOCKET_ERR_DOMAIN
		
		///
		/// The error code: **see constants above for possible errors**
		///
		public var errorCode: Int32
		
		///
		/// The reason for the error **(if available)**
		///
		public var errorReason: String?
		
		///
		/// Returns a string description of the error.
		///
		public var description: String {
			
			let reason = self.errorReason ?? "Reason: Unavailable"
			return "Error code: \(self.errorCode), \(reason)"
		}
		
		///
		/// The buffer size needed to complete the read.
		///
		public var bufferSizeNeeded: Int32
		
		// MARK: -- Public Functions
		
		///
		/// Initializes an Error Instance
		///
		/// - Parameters:
		///		- code:		Error code
		/// 	- reason:	Optional Error Reason
		///
		/// - Returns: Error instance
		///
		init(code: Int, reason: String?) {
			
			self.errorCode = Int32(code)
			self.errorReason = reason
			self.bufferSizeNeeded = 0
		}
		
		///
		/// Initializes an Error Instance for a too small receive buffer error.
		///
		///	- Parameter bufferSize:	Required buffer size
		///
		///	- Returns: Error Instance
		///
		convenience init(bufferSize: Int) {
			
			self.init(code: Socket.SOCKET_ERR_RECV_BUFFER_TOO_SMALL, reason: nil)
			self.bufferSizeNeeded = Int32(bufferSize)
		}
	}
	
	// MARK: Properties
	
	// MARK: -- Private
	
	///
	/// Internal read buffer.
	/// 	**Note:** The readBuffer is actually allocating unmanaged memory that'll
	///			be deallocated when we're done with it.
	///
	var readBuffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>(allocatingCapacity: Socket.SOCKET_DEFAULT_READ_BUFFER_SIZE)
	
	///
	/// Internal Storage Buffer initially created with `Socket.SOCKET_DEFAULT_READ_BUFFER_SIZE`.
	///
	var readStorage: NSMutableData = NSMutableData(capacity: Socket.SOCKET_DEFAULT_READ_BUFFER_SIZE)!
	
	
	// MARK: -- Public
	
	///
	/// Internal Read buffer size for all open sockets.
	///		**Note:** Changing this value will cause the internal read buffer to
	///			be discarded and reallocated with the new size. The value must be
	///			set to at least `Socket.SOCKET_MINIMUM_READ_BUFFER_SIZE`. If set
	///			to something smaller, it will be automatically set to the minimum
	///			size as defined by `Socket.SOCKET_MINIMUM_READ_BUFFER_SIZE`.
	///
	public var readBufferSize: Int = Socket.SOCKET_DEFAULT_READ_BUFFER_SIZE {
		
		// If the buffer size changes we need to reallocate the buffer...
		didSet {
			
			// Ensure minimum buffer size...
			if readBufferSize < Socket.SOCKET_MINIMUM_READ_BUFFER_SIZE {
				
				readBufferSize = Socket.SOCKET_MINIMUM_READ_BUFFER_SIZE
			}
			
			print("Creating read buffer of size: \(readBufferSize)")
			if readBufferSize != oldValue {
				
				readBuffer.deinitialize()
				readBuffer.deallocateCapacity(oldValue)
				readBuffer = UnsafeMutablePointer<CChar>(allocatingCapacity: readBufferSize)
				readBuffer.initialize(with:0)
			}
		}
	}
	
	///
	/// Maximum number of pending connections per listening socket.
	///		**Note:** Default value is `Socket.SOCKET_DEFAULT_MAX_CONNECTIONS`
	///
	public var maxPendingConnections: Int = Socket.SOCKET_DEFAULT_MAX_CONNECTIONS
	
	///
	/// True if this socket is connected. False otherwise. (Readonly)
	///
	public private(set) var isConnected: Bool = false
	
	///
	/// True if this socket is blocking. False otherwise. (Readonly)
	///
	public private(set) var isBlocking: Bool = true
	
	///
	/// True if this socket is listening. False otherwise. (Readonly)
	///
	public private(set) var isListening: Bool = false
	
	///
	/// Listening port (-1 if not listening)
	///
	public var listeningPort: Int32 {
		
		guard let sig = signature where isListening else {
			return Int32(-1)
		}
		return sig.port
	}
	
	///
	/// The remote host name this socket is connected to. (Readonly)
	///
	public var remoteHostname: String {
		
		guard let sig = signature,
			let host = sig.hostname else {
				return Socket.NO_HOSTNAME
		}
		
		return host
	}
	
	///
	/// The remote port this socket is connected to. (Readonly)
	///
	public var remotePort: Int32 {
		
		guard let sig = signature where sig.port != Socket.SOCKET_INVALID_PORT else {
			return Socket.SOCKET_INVALID_PORT
		}
		
		return sig.port
	}
	
	///
	/// The file descriptor representing this socket. (Readonly)
	///
	public private(set) var socketfd: Int32 = SOCKET_INVALID_DESCRIPTOR
	
	///
	/// The signature for the socket.
	/// 	**Note:** See Signature above.
	///
	public private(set) var signature: Signature? = nil
	
	///
	/// True if this a server, false otherwise.
	///
	public var isServer: Bool {
		
		return isListening
	}
	
	
	// MARK: Class Methods
	
	///
	/// Creates a default pre-configured Socket instance.
	///		Default socket created with family: .INET, type: .STREAM, proto: .TCP
	///
	/// - Returns: New Socket instance
	///
	public class func makeDefault() throws -> Socket {
		
		return try Socket(family: .INET, type: .STREAM, proto: .TCP)
	}
	
	///
	/// Create a configured Socket instance.
	///
	/// - Parameters:
	///		- family:	The family of the socket to create.
	///		- type:		The type of socket to create.
	///		- proto:	The protocool to use for the socket.
	///
	/// - Returns: New Socket instance
	///
	public class func makeConfigured(family: ProtocolFamily, type: SocketType, proto: SocketProtocol) throws -> Socket {
		
		if type == .DGRAM || proto == .UDP {
			
			throw Error(code: Socket.SOCKET_ERR_NOT_SUPPORTED_YET, reason: "Full support for Datagrams and UDP not available yet.")
			
		}
		return try Socket(family: family, type: type, proto: proto)
	}
	
	///
	/// Create a configured and connected Socket instance.
	///
	/// - Parameter signature:	The socket signature containing the connection information.
	///
	/// - Returns: New Socket instance. **Note:** Connection status should be checked via the *isConnected* property on the returned socket.
	///
	public class func makeConnected(using signature: Signature) throws -> Socket {
		
		let socket = try Socket(family: signature.protocolFamily, type: signature.socketType, proto: signature.proto)
		
		try socket.connect(using: signature)
		
		return socket
	}
	
	///
	/// Create an instance for existing open socket fd.
	///
	/// - Parameters:
	///		- fd: 				Open file descriptor.
	///		- remoteAddress: 	The Address associated with the open fd.
	///
	/// - Returns: New Socket instance
	///
	public class func makeFrom(nativeHandle: Int32, address: Address?) throws -> Socket {
		
		guard let addr = address else {
			
			throw Error(code: Socket.SOCKET_ERR_MISSING_CONNECTION_DATA, reason: "Unable to access socket connection data.")
		}
		
		return try Socket(fd: nativeHandle, remoteAddress: addr)
	}
	
	///
	/// Extract the string form of IP address and the port.
	///
	/// - Parameter fromAddress: The Address struct.
	///
	/// - Returns: Optional Tuple containing the hostname and port.
	///
	public class func hostnameAndPort(from address: Address) -> (hostname: String, port: Int32)? {
		
		
		var port: Int32 = 0
		var bufLen: Int = 0
		var buf: [CChar]
		
		switch address {
			
		case .IPV4(let address_in):
			var addr_in = address_in
			let addr = addr_in.asAddr()
			bufLen = Int(INET_ADDRSTRLEN)
			buf = [CChar](repeating: 0, count: bufLen)
			inet_ntop(Int32(addr.sa_family), &addr_in.sin_addr, &buf, socklen_t(bufLen))
			port = Int32(UInt16(addr_in.sin_port).byteSwapped)
			
		case .IPV6(let address_in):
			var addr_in = address_in
			let addr = addr_in.asAddr()
			bufLen = Int(INET6_ADDRSTRLEN)
			buf = [CChar](repeating: 0, count: bufLen)
			inet_ntop(Int32(addr.sa_family), &addr_in.sin6_addr, &buf, socklen_t(bufLen))
			port = Int32(UInt16(addr_in.sin6_port).byteSwapped)
			
		}
		
		if let s = String(validatingUTF8: buf) {
			return (s, port)
			
		}
		
		return nil
	}
	
	///
	/// Check whether one or more sockets are available for reading and/or writing
	///
	/// - Parameter sockets: Array of Sockets to be tested.
	///
	/// - Returns: Tuple containing two arrays of Sockets, one each representing readable and writable sockets.
	///
	public class func checkStatus(for sockets: [Socket]) throws -> (readables: [Socket], writables: [Socket]) {
		
		var readables: [Socket] = []
		var writables: [Socket] = []
		
		for socket in sockets {
			
			let result = try socket.isReadableOrWritable()
			if result.readable {
				readables.append(socket)
			}
			if result.writable {
				writables.append(socket)
			}
		}
		
		return (readables, writables)
	}
	
	// MARK: Lifecycle Methods
	
	// MARK: -- Public
	
	///
	/// Internal initializer to create a configured Socket instance.
	///
	/// - Parameters:
	///		- family:	The family of the socket to create.
	///		- type:		The type of socket to create.
	///		- proto:	The protocool to use for the socket.
	///
	/// - Returns: New Socket instance
	///
	private init(family: ProtocolFamily, type: SocketType, proto: SocketProtocol) throws {
		
		// Initialize the read buffer...
		self.readBuffer.initialize(with: 0)
		
		// Create the socket...
		#if os(Linux)
			self.socketfd = Glibc.socket(family.value, type.value, proto.value)
		#else
			self.socketfd = Darwin.socket(family.value, type.value, proto.value)
		#endif
		
		// If error, throw an appropriate exception...
		if self.socketfd < 0 {
			
			self.socketfd = Socket.SOCKET_INVALID_DESCRIPTOR
			throw Error(code: Socket.SOCKET_ERR_UNABLE_TO_CREATE_SOCKET, reason: self.lastError())
		}
		
		// Create the signature...
		try self.signature = Signature(
			protocolFamily: family.value,
			socketType: type.value,
			proto: proto.value,
			address: nil)
	}
	
	///
	/// Cleanup: close the socket, free memory buffers.
	///
	deinit {
		
		if self.socketfd > 0 {
			
			self.close()
		}
		
		// Destroy and free the readBuffer...
		self.readBuffer.deinitialize()
		self.readBuffer.deallocateCapacity(self.readBufferSize)
	}
	
	// MARK: -- Private
	
	///
	/// Private constructor to create an instance for existing open socket fd.
	///
	/// - Parameters:
	///		- fd: 				Open file descriptor.
	///		- remoteAddress: 	The Address associated with the open fd.
	///
	/// - Returns: New Socket instance
	///
	private init(fd: Int32, remoteAddress: Address) throws {
		
		self.isConnected = true
		self.isListening = false
		self.readBuffer.initialize(with: 0)
		
		self.socketfd = fd
		
		// Create the signature...
		#if os(Linux)
			let type = Int32(SOCK_STREAM.rawValue)
		#else
			let type = SOCK_STREAM
		#endif
		
		if let (hostname, port) = Socket.hostnameAndPort(from: remoteAddress) {
			try self.signature = Signature(
				protocolFamily: Int32(remoteAddress.addr.sa_family),
				socketType: type,
				proto: Int32(IPPROTO_TCP),
				address: remoteAddress,
				hostname: hostname,
				port: port)
		} else {
			try self.signature = Signature(
				protocolFamily: Int32(remoteAddress.addr.sa_family),
				socketType: type,
				proto: Int32(IPPROTO_TCP),
				address: remoteAddress)
		}
	}
	
	// MARK: Public Methods
	
	// MARK: -- Accept
	
	///
	/// Accepts an incoming client connection request on the current instance, leaving the current instance still listening.
	///
	/// - Returns: New Socket instance representing the newly accepted socket.
	///
	public func acceptClientConnection() throws -> Socket {
		
		// The socket must've been created, not connected and listening...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {
			
			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		if self.isConnected {
			
			throw Error(code: Socket.SOCKET_ERR_ALREADY_CONNECTED, reason: nil)
		}
		
		if !self.isListening {
			
			throw Error(code: Socket.SOCKET_ERR_NOT_LISTENING, reason: nil)
		}
		
		// Accept the remote connection...
		var socketfd2: Int32
		var address: Address
		switch self.signature!.protocolFamily {
			
		case .INET:
			var acceptAddr = sockaddr_in()
			var addrSize = socklen_t(sizeofValue(acceptAddr))
			
			#if os(Linux)
				let fd = withUnsafeMutablePointer(&acceptAddr) {
					Glibc.accept(self.socketfd, UnsafeMutablePointer($0), &addrSize)
				}
			#else
				let fd = withUnsafeMutablePointer(&acceptAddr) {
					Darwin.accept(self.socketfd, UnsafeMutablePointer($0), &addrSize)
				}
			#endif
			if fd < 0 {
				
				throw Error(code: Socket.SOCKET_ERR_ACCEPT_FAILED, reason: self.lastError())
			}
			socketfd2 = fd
			address = .IPV4(acceptAddr)
			
		case .INET6:
			var acceptAddr = sockaddr_in6()
			var addrSize = socklen_t(sizeofValue(acceptAddr))
			
			#if os(Linux)
				let fd = withUnsafeMutablePointer(&acceptAddr) {
					Glibc.accept(self.socketfd, UnsafeMutablePointer($0), &addrSize)
				}
			#else
				let fd = withUnsafeMutablePointer(&acceptAddr) {
					Darwin.accept(self.socketfd, UnsafeMutablePointer($0), &addrSize)
				}
			#endif
			if fd < 0 {
				
				throw Error(code: Socket.SOCKET_ERR_ACCEPT_FAILED, reason: self.lastError())
			}
			socketfd2 = fd
			address = .IPV6(acceptAddr)
		}
		
		// Create and return the new socket...
		//	Note: The current socket continues to listen.
		return try Socket(fd: socketfd2, remoteAddress: address)
	}
	
	///
	/// Accepts an incoming connection request replacing the existing socket with the newly accepted one.
	///
	public func acceptConnection() throws {
		
		// The socket must've been created, not connected and listening...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {
			
			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		if self.isConnected {
			
			throw Error(code: Socket.SOCKET_ERR_ALREADY_CONNECTED, reason: nil)
		}
		
		if !self.isListening {
			
			throw Error(code: Socket.SOCKET_ERR_NOT_LISTENING, reason: nil)
		}
		
		// Accept the remote connection...
		var socketfd2: Int32
		var address: Address
		switch self.signature!.protocolFamily {
			
		case .INET:
			var acceptAddr = sockaddr_in()
			var addrSize = socklen_t(sizeofValue(acceptAddr))
			
			#if os(Linux)
				let fd = withUnsafeMutablePointer(&acceptAddr) {
					Glibc.accept(self.socketfd, UnsafeMutablePointer($0), &addrSize)
				}
			#else
				let fd = withUnsafeMutablePointer(&acceptAddr) {
					Darwin.accept(self.socketfd, UnsafeMutablePointer($0), &addrSize)
				}
			#endif
			if fd < 0 {
				
				throw Error(code: Socket.SOCKET_ERR_ACCEPT_FAILED, reason: self.lastError())
			}
			socketfd2 = fd
			address = .IPV4(acceptAddr)
			
		case .INET6:
			var acceptAddr = sockaddr_in6()
			var addrSize = socklen_t(sizeofValue(acceptAddr))
			
			#if os(Linux)
				let fd = withUnsafeMutablePointer(&acceptAddr) {
					Glibc.accept(self.socketfd, UnsafeMutablePointer($0), &addrSize)
				}
			#else
				let fd = withUnsafeMutablePointer(&acceptAddr) {
					Darwin.accept(self.socketfd, UnsafeMutablePointer($0), &addrSize)
				}
			#endif
			if fd < 0 {
				
				throw Error(code: Socket.SOCKET_ERR_ACCEPT_FAILED, reason: self.lastError())
			}
			socketfd2 = fd
			address = .IPV6(acceptAddr)
		}
		
		// Close the old socket...
		self.close()
		
		// Save the address...
		self.signature!.address = address
		
		// Replace the existing socketfd with the new one...
		self.socketfd = socketfd2
		
		if let (hostname, port) = Socket.hostnameAndPort(from: address) {
			self.signature!.hostname = hostname
			self.signature!.port = port
		}
		
		// We're connected but no longer listening...
		self.isConnected = true
		self.isListening = false
	}
	
	// MARK: -- Close
	
	///
	/// Closes the current socket.
	///
	public func close() {
		
		if self.socketfd != Socket.SOCKET_INVALID_DESCRIPTOR {
			
			// Note: if the socket is listening, we need to shut it down prior to closing
			//		or the socket will be left hanging until it times out.
			#if os(Linux)
				if self.isListening {
					Glibc.shutdown(self.socketfd, Int32(SHUT_RDWR))
				}
				Glibc.close(self.socketfd)
			#else
				if self.isListening {
					Darwin.shutdown(self.socketfd, Int32(SHUT_RDWR))
				}
				Darwin.close(self.socketfd)
			#endif
			
			self.socketfd = Socket.SOCKET_INVALID_DESCRIPTOR
		}
		
		if let _ = self.signature {
			self.signature!.hostname = Socket.NO_HOSTNAME
			self.signature!.port = Socket.SOCKET_INVALID_PORT
		}
		self.isConnected = false
		self.isListening = false
	}
	
	// MARK: -- Connect
	
	///
	/// Connects to the named host on the specified port.
	///
	/// - Parameters:
	///		- host:	The host name to connect to.
	///		- port:	The port to be used.
	///
	public func connect(to host: String, port: Int32) throws {
		
		// The socket must've been created and must not be connected...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {
			
			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		if self.isConnected {
			
			throw Error(code: Socket.SOCKET_ERR_ALREADY_CONNECTED, reason: nil)
		}
		
		if host.utf8.count == 0 {
			
			throw Error(code: Socket.SOCKET_ERR_INVALID_HOSTNAME, reason: nil)
		}
		
		// Create the hints for our search...
		let socketType: SocketType = .STREAM
		#if os(Linux)
			var hints = addrinfo(
				ai_flags: AI_PASSIVE,
				ai_family: AF_UNSPEC,
				ai_socktype: socketType.value,
				ai_protocol: 0,
				ai_addrlen: 0,
				ai_addr: nil,
				ai_canonname: nil,
				ai_next: nil)
		#else
			var hints = addrinfo(
				ai_flags: AI_PASSIVE,
				ai_family: AF_UNSPEC,
				ai_socktype: socketType.value,
				ai_protocol: 0,
				ai_addrlen: 0,
				ai_canonname: nil,
				ai_addr: nil,
				ai_next: nil)
		#endif
		
		var targetInfo: UnsafeMutablePointer<addrinfo>? = UnsafeMutablePointer<addrinfo>(allocatingCapacity: 1)
		
		// Retrieve the info on our target...
		var status: Int32 = getaddrinfo(host, String(port), &hints, &targetInfo)
		if status != 0 {
			
			var errorString: String
			if status == EAI_SYSTEM {
				errorString = String(validatingUTF8: strerror(errno)) ?? "Unknown error code."
			} else {
				errorString = String(validatingUTF8: gai_strerror(errno)) ?? "Unknown error code."
			}
			throw Error(code: Socket.SOCKET_ERR_GETADDRINFO_FAILED, reason: errorString)
		}
		
		// Defer cleanup of our target info...
		defer {
			
			if targetInfo != nil {
				freeaddrinfo(targetInfo)
			}
		}
		
		var socketDescriptor: Int32?
		
		var info = targetInfo
		while (info != nil) {
			
			#if os(Linux)
				socketDescriptor = Glibc.socket(info!.pointee.ai_family, info!.pointee.ai_socktype, info!.pointee.ai_protocol)
			#else
				socketDescriptor = Darwin.socket(info!.pointee.ai_family, info!.pointee.ai_socktype, info!.pointee.ai_protocol)
			#endif
			if socketDescriptor == -1 {
				continue
			}
			
			// Connect to the server...
			#if os(Linux)
				status = Glibc.connect(socketDescriptor!, info!.pointee.ai_addr, info!.pointee.ai_addrlen)
			#else
				status = Darwin.connect(socketDescriptor!, info!.pointee.ai_addr, info!.pointee.ai_addrlen)
			#endif
			
			// Break if successful...
			if status == 0 {
				break
			}
			
			// Close the socket that was opened... Protocol family may have changed...
			#if os(Linux)
				Glibc.close(socketDescriptor!)
			#else
				Darwin.close(socketDescriptor!)
			#endif
			socketDescriptor = nil
			info = info?.pointee.ai_next
		}
		
		// Throw if there is a status error...
		if status != 0 || socketDescriptor == nil {
			
			if socketDescriptor != nil {
				#if os(Linux)
					Glibc.close(socketDescriptor!)
				#else
					Darwin.close(socketDescriptor!)
				#endif
			}
			throw Error(code: Socket.SOCKET_ERR_GETADDRINFO_FAILED, reason: self.lastError())
		}
		
		// Close the existing socket (if open) before replacing it...
		if self.socketfd != Socket.SOCKET_INVALID_DESCRIPTOR {
			
			self.close()
		}
		
		self.socketfd = socketDescriptor!
		self.isConnected = true
		var address: Address
		if info!.pointee.ai_family == Int32(AF_INET6) {
			
			var addr = sockaddr_in6()
			memcpy(&addr, info!.pointee.ai_addr, Int(sizeofValue(addr)))
			address = .IPV6(addr)
			
		} else {
			
			var addr = sockaddr_in()
			memcpy(&addr, info!.pointee.ai_addr, Int(sizeofValue(addr)))
			address = .IPV4(addr)
			
		}
		try self.signature = Signature(
			protocolFamily: Int32(info!.pointee.ai_family),
			socketType: info!.pointee.ai_socktype,
			proto: info!.pointee.ai_protocol,
			address: address,
			hostname: host,
			port: port)
		
	}
	
	///
	/// Connect to the address or hostname/port pointed to by the signature passed.
	///
	/// - Parameter signature:	Signature containing the address hostname/port to connect to.
	///
	public func connect(using signature: Signature) throws {
		
		// Ensure we've got a proper address...
		if signature.hostname == nil || signature.port == Socket.SOCKET_INVALID_PORT {
			
			guard let _ = signature.address else {
				
				throw Error(code: Socket.SOCKET_ERR_MISSING_CONNECTION_DATA, reason: "Unable to access connection data.")
			}
			
		} else {
			
			// Otherwise, make sure we've got a hostname and port...
			guard let hostname = signature.hostname
				where signature.port != Socket.SOCKET_INVALID_PORT else {
					
					throw Error(code: Socket.SOCKET_ERR_MISSING_CONNECTION_DATA, reason: "Unable to access hostname and port.")
			}
			
			// Connect using hostname and port....
			try self.connect(to: hostname, port: signature.port)
			return
		}
		
		// Now, do the connection using the supplied address...
		var remoteAddr = signature.address!.addr
		
		#if os(Linux)
			let rc = withUnsafeMutablePointer(&remoteAddr) {
				Glibc.connect(self.socketfd, UnsafeMutablePointer($0), socklen_t(signature.address!.size))
			}
		#else
			let rc = withUnsafeMutablePointer(&remoteAddr) {
				Darwin.connect(self.socketfd, UnsafeMutablePointer($0), socklen_t(signature.address!.size))
			}
		#endif
		if rc < 0 {
			
			throw Error(code: Socket.SOCKET_ERR_CONNECT_FAILED, reason: self.lastError())
		}
		
		if let (hostname, port) = Socket.hostnameAndPort(from: signature.address!) {
			
			var sig = signature
			sig.hostname = hostname
			sig.port = Int32(port)
			self.signature = sig
			self.isConnected = true
		}
	}
	
	// MARK: -- Listen
	
	///
	/// Listen on a port using the default for max pending connections.
	///
	/// - Parameter port: The port to listen on.
	///
	public func listen(on port: Int) throws {
		
		return try self.listen(on: port, maxPendingConnections: self.maxPendingConnections)
	}
	
	///
	/// Listen on a port, limiting the maximum number of pending connections.
	///
	/// - Parameters:
	///		- port: 					The port to listen on.
	/// 	- maxPendingConnections: 	The maximum number of pending connections to allow.
	///
	public func listen(on port: Int, maxPendingConnections: Int) throws {
		
		// Set a flag so that this address can be re-used immediately after the connection
		// closes.  (TCP normally imposes a delay before an address can be re-used.)
		var on: Int32 = 1
		if setsockopt(self.socketfd, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(sizeof(Int32.self))) < 0 {
			
			throw Error(code: Socket.SOCKET_ERR_SETSOCKOPT_FAILED, reason: self.lastError())
		}
		
		// Set the socket to ignore SIGPIPE to avoid dying on interrupted connections...
		//	Note: Linux does not support the SO_NOSIGPIPE option. Instead, we use the
		//		  MSG_NOSIGNAL flags passed to send.  See the writeData() functions below.
		#if !os(Linux)
			if setsockopt(self.socketfd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(sizeof(Int32.self))) < 0 {
				
				throw Error(code: Socket.SOCKET_ERR_SETSOCKOPT_FAILED, reason: self.lastError())
			}
		#endif
		
		// Get the signature for the socket...
		guard let sig = self.signature else {
			
			throw Error(code: Socket.SOCKET_ERR_INTERNAL, reason: "Socket signature not found.")
		}
		
		// Create the hints for our search...
		#if os(Linux)
			var hints = addrinfo(
				ai_flags: AI_PASSIVE,
				ai_family: sig.protocolFamily.value,
				ai_socktype: sig.socketType.value,
				ai_protocol: 0,
				ai_addrlen: 0,
				ai_addr: nil,
				ai_canonname: nil,
				ai_next: nil)
		#else
			var hints = addrinfo(
				ai_flags: AI_PASSIVE,
				ai_family: sig.protocolFamily.value,
				ai_socktype: sig.socketType.value,
				ai_protocol: 0,
				ai_addrlen: 0,
				ai_canonname: nil,
				ai_addr: nil,
				ai_next: nil)
		#endif
		
		var targetInfo: UnsafeMutablePointer<addrinfo>? = UnsafeMutablePointer<addrinfo>(allocatingCapacity: 1)
		
		// Retrieve the info on our target...
		let status: Int32 = getaddrinfo(nil, String(port), &hints, &targetInfo)
		if status != 0 {
			
			var errorString: String
			if status == EAI_SYSTEM {
				errorString = String(validatingUTF8: strerror(errno)) ?? "Unknown error code."
			} else {
				errorString = String(validatingUTF8: gai_strerror(errno)) ?? "Unknown error code."
			}
			throw Error(code: Socket.SOCKET_ERR_GETADDRINFO_FAILED, reason: errorString)
		}
		
		// Defer cleanup of our target info...
		defer {
			
			if targetInfo != nil {
				freeaddrinfo(targetInfo)
			}
		}
		
		var info = targetInfo
		var bound = false
		while (info != nil) {
			
			// Try to bind the socket to the address...
			#if os(Linux)
				if Glibc.bind(self.socketfd, info!.pointee.ai_addr, info!.pointee.ai_addrlen) == 0 {
					
					// Success... We've found our address...
					bound = true
					break
				}
			#else
				if Darwin.bind(self.socketfd, info!.pointee.ai_addr, info!.pointee.ai_addrlen) == 0 {
					
					// Success... We've found our address...
					bound = true
					break
				}
			#endif
			
			// Try the next one...
			info = info?.pointee.ai_next
		}
		
		// Throw an error if we weren't able to bind to an address...
		if !bound {
			
			throw Error(code: Socket.SOCKET_ERR_BIND_FAILED, reason: self.lastError())
		}
		
		// Save the address info...
		var address: Address
		if info!.pointee.ai_family == Int32(AF_INET6) {
			
			var addr = sockaddr_in6()
			memcpy(&addr, info!.pointee.ai_addr, Int(sizeofValue(addr)))
			address = .IPV6(addr)
			
		} else {
			
			var addr = sockaddr_in()
			memcpy(&addr, info!.pointee.ai_addr, Int(sizeofValue(addr)))
			address = .IPV4(addr)
			
		}
		
		self.signature?.address = address
		
		// Update our hostname and port...
		if let (hostname, port) = Socket.hostnameAndPort(from: address) {
			self.signature?.hostname = hostname
			self.signature?.port = Int32(port)
		}
		
		// Now listen for connections...
		#if os(Linux)
			if Glibc.listen(self.socketfd, Int32(maxPendingConnections)) < 0 {
				
				throw Error(code: Socket.SOCKET_ERR_LISTEN_FAILED, reason: self.lastError())
			}
		#else
			if Darwin.listen(self.socketfd, Int32(maxPendingConnections)) < 0 {
				
				throw Error(code: Socket.SOCKET_ERR_LISTEN_FAILED, reason: self.lastError())
			}
		#endif
		
		self.isListening = true
	}
	
	// MARK: -- Read
	
	///
	/// Read data from the socket.
	///
	/// - Parameters:
	///		- buffer: The buffer to return the data in.
	/// 	- bufSize: The size of the buffer.
	///
	/// - Throws: `Socket.SOCKET_ERR_RECV_BUFFER_TOO_SMALL` if the buffer provided is too small.
	///		Call again with proper buffer size (see `Error.bufferSizeNeeded`) or
	///		use `readData(data: NSMutableData)`.
	///
	/// - Returns: The number of bytes returned in the buffer.
	///
	public func read(into buffer: UnsafeMutablePointer<CChar>, bufSize: Int) throws -> Int {
		
		// Make sure the buffer is valid...
		if bufSize == 0 {
			
			throw Error(code: Socket.SOCKET_ERR_INVALID_BUFFER, reason: nil)
		}
		
		// The socket must've been created and must be connected...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {
			
			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		if !self.isConnected {
			
			throw Error(code: Socket.SOCKET_ERR_NOT_CONNECTED, reason: nil)
		}
		
		// See if we have cached data to send back...
		if self.readStorage.length > 0 {
			
			if bufSize < self.readStorage.length {
				
				throw Error(bufferSize: self.readStorage.length)
			}
			
			let returnCount = self.readStorage.length
			
			// - We've got data we've already read, copy to the caller's buffer...
			memcpy(buffer, self.readStorage.bytes, self.readStorage.length)
			
			// - Reset the storage buffer...
			self.readStorage.length = 0
			
			return returnCount
		}
		
		// Read all available bytes...
		let count = try self.readDataIntoStorage()
		
		// Check for disconnect...
		if count == 0 {
			
			return count
		}
		
		// Did we get data?
		var returnCount: Int = 0
		if self.readStorage.length > 0 {
			
			// Is the caller's buffer big enough?
			if bufSize < self.readStorage.length {
				
				// Nope, throw an exception telling the caller how big the buffer must be...
				throw Error(bufferSize: self.readStorage.length)
			}
			
			// - We've read data, copy to the callers buffer...
			memcpy(buffer, self.readStorage.bytes, self.readStorage.length)
			
			returnCount = self.readStorage.length
			
			// - Reset the storage buffer...
			self.readStorage.length = 0
		}
		
		return returnCount
	}
	
	///
	/// Read a string from the socket
	///
	/// - Returns: String containing the data read from the socket.
	///
	public func readString() throws -> String? {
		
		guard let data = NSMutableData(capacity: 2000) else {
			
			throw Error(code: Socket.SOCKET_ERR_INTERNAL, reason: "Unable to create temporary NSData...")
		}
		
		try self.read(into: data)
		
		guard let str = NSString(data: data, encoding: NSUTF8StringEncoding) else {
			
			throw Error(code: Socket.SOCKET_ERR_INTERNAL, reason: "Unable to convert data to NSString.")
		}
		
		#if os(Linux)
			return str.bridge()
		#else
			return str as String
		#endif
		
	}
	
	
	///
	/// Read data from the socket.
	///
	/// - Parameter data: The buffer to return the data in.
	///
	/// - Returns: The number of bytes returned in the buffer.
	///
	public func read(into data: NSMutableData) throws -> Int {
		
		// The socket must've been created and must be connected...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {
			
			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		if !self.isConnected {
			
			throw Error(code: Socket.SOCKET_ERR_NOT_CONNECTED, reason: nil)
		}
		
		// Read all available bytes...
		let count = try self.readDataIntoStorage()
		
		// Check for disconnect...
		if count == 0 {
			
			return count
		}
		
		// Did we get data?
		var returnCount: Int = 0
		if count > 0 {
			
			// - Yes, move to caller's buffer...
			//		@TODO: Fix this when Linux Foundation catches up...
			#if os(Linux)
				data.appendData(self.readStorage)
			#else
				data.append(self.readStorage)
			#endif
			
			returnCount = self.readStorage.length
			
			// - Reset the storage buffer...
			self.readStorage.length = 0
		}
		
		return returnCount
	}
	
	///
	/// Read data from a UDP socket.
	///
	/// - Parameters:
	///		- data: 	The buffer to return the data in.
	///		- address: 	Address to write data to.
	///
	/// - Returns: The number of bytes returned in the buffer.
	///
	public func read(into data: NSMutableData, from address: Address) throws -> Int {
		
		// The socket must've been created...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {
			
			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		// The socket must've been created for UDP...
		guard let sig = self.signature where sig.proto == .UDP else {
			
			throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "This is not a UDP socket.")
		}
		
		return 0
	}
	
	///
	/// Read data from a UDP socket.
	///
	/// - Parameters:
	///		- buffer: 	The buffer to return the data in.
	/// 	- bufSize: 	The size of the buffer.
	///		- address: 	Address to write data to.
	///
	/// - Throws: `Socket.SOCKET_ERR_RECV_BUFFER_TOO_SMALL` if the buffer provided is too small.
	///		Call again with proper buffer size (see `Error.bufferSizeNeeded`) or
	///		use `readData(data: NSMutableData)`.
	///
	/// - Returns: The number of bytes returned in the buffer.
	///
	public func read(into buffer: UnsafeMutablePointer<CChar>, bufSize: Int, from address: Address) throws -> Int {
		
		// Make sure the buffer is valid...
		if bufSize == 0 {
			
			throw Error(code: Socket.SOCKET_ERR_INVALID_BUFFER, reason: nil)
		}
		
		// The socket must've been created...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {
			
			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		// The socket must've been created for UDP...
		guard let sig = self.signature where sig.proto == .UDP else {
			
			throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "This is not a UDP socket.")
		}
		
		return 0
	}
	
	// MARK: -- Write
	
	///
	/// Write data to the socket.
	///
	/// - Parameters:
	///		- buffer: 	The buffer containing the data to write.
	/// 	- bufSize: 	The size of the buffer.
	///
	public func write(from buffer: UnsafePointer<Void>, bufSize: Int) throws {
		
		// Make sure the buffer is valid...
		if bufSize == 0 {
			
			throw Error(code: Socket.SOCKET_ERR_INVALID_BUFFER, reason: nil)
		}
		
		// The socket must've been created and must be connected...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {
			
			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		if !self.isConnected {
			
			throw Error(code: Socket.SOCKET_ERR_NOT_CONNECTED, reason: nil)
		}
		
		var sent = 0
		var sendFlags: Int32 = 0
		#if os(Linux)
			if self.isListening {
				sendFlags = Int32(MSG_NOSIGNAL)
			}
		#endif
		while sent < bufSize {
			
			#if os(Linux)
				let s = Glibc.send(self.socketfd, buffer.advanced(by: sent), Int(bufSize - sent), sendFlags)
			#else
				let s = Darwin.send(self.socketfd, buffer.advanced(by: sent), Int(bufSize - sent), sendFlags)
			#endif
			if s <= 0 {
				
				throw Error(code: Socket.SOCKET_ERR_WRITE_FAILED, reason: self.lastError())
			}
			sent += s
		}
	}
	
	///
	/// Write data to the socket.
	///
	/// - Parameter data: The NSData object containing the data to write.
	///
	public func write(from data: NSData) throws {
		
		// The socket must've been created and must be connected...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {
			
			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		if !self.isConnected {
			
			throw Error(code: Socket.SOCKET_ERR_NOT_CONNECTED, reason: nil)
		}
		
		// If there's no data in the NSData object, why bother? Fail silently...
		if data.length == 0 {
			return
		}
		
		var sent = 0
		var sendFlags: Int32 = 0
		#if os(Linux)
			if self.isListening {
				sendFlags = Int32(MSG_NOSIGNAL)
			}
		#endif
		let buffer = data.bytes
		while sent < data.length {
			
			#if os(Linux)
				let s = Glibc.send(self.socketfd, buffer.advanced(by: sent), Int(data.length - sent), sendFlags)
			#else
				let s = Darwin.send(self.socketfd, buffer.advanced(by: sent), Int(data.length - sent), sendFlags)
			#endif
			if s <= 0 {
				
				throw Error(code: Socket.SOCKET_ERR_WRITE_FAILED, reason: self.lastError())
			}
			sent += s
		}
	}
	
	///
	/// Write a string to the socket.
	///
	/// - Parameter string: The string to write.
	///
	public func write(from string: String) throws {
		
		try string.nulTerminatedUTF8.withUnsafeBufferPointer() {
			
			// The count returned by nullTerminatedUTF8 includes the null terminator...
			try self.write(from: $0.baseAddress!, bufSize: $0.count-1)
		}
	}
	
	///
	/// Write data to the socket.
	///
	/// - Parameters:
	///		- buffer: 	The buffer containing the data to write.
	/// 	- bufSize: 	The size of the buffer.
	///		- address: 	Address to write data to.
	///
	public func write(from buffer: UnsafePointer<Void>, bufSize: Int, to addresss: Address) throws {
		
		// Make sure the buffer is valid...
		if bufSize == 0 {
			
			throw Error(code: Socket.SOCKET_ERR_INVALID_BUFFER, reason: nil)
		}
		
		// The socket must've been created and must be connected...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {
			
			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		// The socket must've been created for UDP...
		guard let sig = self.signature where sig.proto == .UDP else {
			
			throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "This is not a UDP socket.")
		}
		
	}
	
	///
	/// Write data to a UDP socket.
	///
	/// - Parameters:
	///		- data: 	The NSData object containing the data to write.
	///		- address: 	Address to write data to.
	///
	public func write(from data: NSData, to addresss: Address) throws {
		
		// The socket must've been created...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {
			
			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		// The socket must've been created for UDP...
		guard let sig = self.signature where sig.proto == .UDP else {
			
			throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "This is not a UDP socket.")
		}
		
		// If there's no data in the NSData object, why bother? Fail silently...
		if data.length == 0 {
			return
		}
	}
	
	// MARK: -- Utility
	
	///
	/// Determines if this socket can be read from or written to.
	///
	/// - Returns: Tuple containing two boolean values, one for readable and one for writable.
	///
	public func isReadableOrWritable() throws -> (readable: Bool, writable: Bool) {
		
		// The socket must've been created and must be connected...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {
			
			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		if !self.isConnected {
			
			throw Error(code: Socket.SOCKET_ERR_NOT_CONNECTED, reason: nil)
		}
		
		// Create a read and write file descriptor set for this socket...
		var readfds = fd_set()
		fdZero(set: &readfds)
		fdSet(fd: self.socketfd, set: &readfds)
		
		var writefds = fd_set()
		fdZero(set: &writefds)
		fdSet(fd: self.socketfd, set: &writefds)
		
		// Create a timeout of zero (i.e. don't wait)...
		var timeout = timeval()
		
		// See if there's data on the socket...
		let count = select(self.socketfd + 1, &readfds, &writefds, nil, &timeout)
		
		// A count of less than zero indicates select failed...
		if count < 0 {
			
			throw Error(code: Socket.SOCKET_ERR_SELECT_FAILED, reason: self.lastError())
		}
		
		// Return a tuple containing whether or not this socket is readable and/or writable...
		return (fdIsSet(fd: self.socketfd, set: &readfds), fdIsSet(fd: self.socketfd, set: &writefds))
	}
	
	///
	/// Set blocking mode for socket.
	///
	/// - Parameter shouldBlock: True to block, false to not.
	///
	public func setBlocking(mode shouldBlock: Bool) throws {
		
		let flags = fcntl(self.socketfd, F_GETFL)
		if flags < 0 {
			
			throw Error(code: Socket.SOCKET_ERR_GET_FCNTL_FAILED, reason: self.lastError())
		}
		
		var result: Int32 = 0
		if shouldBlock {
			
			result = fcntl(self.socketfd, F_SETFL, flags & ~O_NONBLOCK)
			
		} else {
			
			result = fcntl(self.socketfd, F_SETFL, flags | O_NONBLOCK)
		}
		
		if result < 0 {
			
			throw Error(code: Socket.SOCKET_ERR_SET_FCNTL_FAILED, reason: self.lastError())
		}
		
		self.isBlocking = shouldBlock
	}
	
	// MARK: Private Methods
	
	///
	/// Private method that reads all available data on an open socket into storage.
	///
	/// - Returns: number of bytes read.
	///
	private func readDataIntoStorage() throws -> Int {
		
		// Clear the buffer...
		self.readBuffer.deinitialize()
		self.readBuffer.initialize(with: 0x0)
		memset(self.readBuffer, 0x0, self.readBufferSize)
		
		// Read all the available data...
		var count: Int = 0
		repeat {
			
			#if os(Linux)
				count = Glibc.recv(self.socketfd, self.readBuffer, self.readBufferSize, 0)
			#else
				count = Darwin.recv(self.socketfd, self.readBuffer, self.readBufferSize, 0)
			#endif
			
			// Check for error...
			if count < 0 {
				
				// - Could be an error, but if errno is EAGAIN or EWOULDBLOCK (if a non-blocking socket),
				//		it means there was NO data to read...
				if errno == EAGAIN || errno == EWOULDBLOCK {
					
					return 0
				}
				
				// - Something went wrong...
				throw Error(code: Socket.SOCKET_ERR_RECV_FAILED, reason: self.lastError())
			}
			
			if count > 0 {
				#if os(Linux)
					self.readStorage.appendBytes(self.readBuffer, length: count)
				#else
					self.readStorage.append(self.readBuffer, length: count)
				#endif
			}
			
			// Didn't fill the buffer so we've got everything available...
			if count < self.readBufferSize {
				
				break
			}
			
		} while count > 0
		
		return self.readStorage.length
	}
	
	///
	/// Private method to return the last error based on the value of errno.
	///
	/// - Returns: String containing relevant text about the error.
	///
	private func lastError() -> String {
		
		return String(validatingUTF8: strerror(errno)) ?? "Error: \(errno)"
	}
	
}
