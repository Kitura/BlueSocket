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

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
	import Darwin
#elseif os(Linux)
	import Glibc
#endif

import Foundation

// MARK: Socket

///
/// **Socket:** Low level BSD sockets wrapper.
///
public class Socket: SocketReader, SocketWriter {
	
	// MARK: Constants
	
	// MARK: -- Generic
	
	public static let SOCKET_MINIMUM_READ_BUFFER_SIZE		= 1024
	public static let SOCKET_DEFAULT_READ_BUFFER_SIZE		= 4096
	public static let SOCKET_DEFAULT_MAX_BACKLOG			= 50
	#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
	public static let SOCKET_MAX_DARWIN_BACKLOG				= 128
	#endif
	
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
	public static let SOCKET_ERR_INVALID_PORT				= -9990
	public static let SOCKET_ERR_GETADDRINFO_FAILED			= -9989
	public static let SOCKET_ERR_CONNECT_FAILED				= -9988
	public static let SOCKET_ERR_MISSING_CONNECTION_DATA	= -9987
	public static let SOCKET_ERR_SELECT_FAILED				= -9986
	public static let SOCKET_ERR_LISTEN_FAILED				= -9985
	public static let SOCKET_ERR_INVALID_BUFFER				= -9984
	public static let SOCKET_ERR_INVALID_BUFFER_SIZE		= -9983
	public static let SOCKET_ERR_RECV_FAILED				= -9982
	public static let SOCKET_ERR_RECV_BUFFER_TOO_SMALL		= -9981
	public static let SOCKET_ERR_WRITE_FAILED				= -9980
	public static let SOCKET_ERR_GET_FCNTL_FAILED			= -9979
	public static let SOCKET_ERR_SET_FCNTL_FAILED			= -9978
	public static let SOCKET_ERR_NOT_IMPLEMENTED			= -9977
	public static let SOCKET_ERR_NOT_SUPPORTED_YET			= -9976
	public static let SOCKET_ERR_BAD_SIGNATURE_PARAMETERS	= -9975
	public static let SOCKET_ERR_INTERNAL					= -9974
	public static let SOCKET_ERR_WRONG_PROTOCOL				= -9973
	public static let SOCKET_ERR_NOT_ACTIVE					= -9972
	public static let SOCKET_ERR_CONNECTION_RESET			= -9971
	

	///
	/// Flag to indicate the endian-ness of the host. (Readonly)
	///
	public static let isLittleEndian: Bool 					= Int(littleEndian: 42) == 42

	// MARK: Enums
	
	// MARK: -- ProtocolFamily
	
	///
	/// Socket Protocol Family Values
	///
	/// **Note:** Only the following are supported at this time:
	///			inet = AF_INET (IPV4)
	///			inet6 = AF_INET6 (IPV6)
	///			unix = AF_UNIX
	///
	public enum ProtocolFamily {
		
		/// AF_INET (IPV4)
		case inet
		
		/// AF_INET6 (IPV6)
		case inet6
		
		/// AF_UNIX
		case unix
		
		///
		/// Return the value for a particular case. (Readonly)
		///
		var value: Int32 {
			
			switch self {
				
			case .inet:
				return Int32(AF_INET)
				
			case .inet6:
				return Int32(AF_INET6)
				
			case .unix:
				return Int32(AF_UNIX)
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
				return .inet
			case Int32(AF_INET6):
				return .inet6
			case Int32(AF_UNIX):
				return .unix
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
	///			stream = SOCK_STREAM (Provides sequenced, reliable, two-way, connection-based byte streams.)
	///			datagram = SOCK_DGRAM (Supports datagrams (connectionless, unreliable messages of a fixed maximum length).)
	///
	public enum SocketType {
		
		/// SOCK_STREAM (Provides sequenced, reliable, two-way, connection-based byte streams.)
		case stream
		
		/// SOCK_DGRAM (Supports datagrams (connectionless, unreliable messages of a fixed maximum length).)
		case datagram
		
		///
		/// Return the value for a particular case. (Readonly)
		///
		var value: Int32 {
			
			switch self {
				
			case .stream:
				#if os(Linux)
					return Int32(SOCK_STREAM.rawValue)
				#else
					return SOCK_STREAM
				#endif
			case .datagram:
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
					return .stream
				case Int32(SOCK_DGRAM.rawValue):
					return .datagram
				default:
					return nil
				}
			#else
				switch forValue {
					
				case SOCK_STREAM:
					return .stream
				case SOCK_DGRAM:
					return .datagram
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
	///			tcp = IPPROTO_TCP
	///			udp = IPPROTO_UDP
	///			unix = Unix Domain Socket (raw value = 0)
	///
	public enum SocketProtocol: Int32 {
		
		/// IPPROTO_TCP
		case tcp
		
		/// IPPROTO_UDP
		case udp
		
		/// Unix Domain
		case unix
		
		///
		/// Return the value for a particular case. (Readonly)
		///
		var value: Int32 {
			
			switch self {
				
			case .tcp:
				return Int32(IPPROTO_TCP)
			case .udp:
				return Int32(IPPROTO_UDP)
			case .unix:
				return Int32(0)
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
				return .tcp
			case Int32(IPPROTO_UDP):
				return .udp
			case Int32(0):
				return .unix
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
		
		/// sockaddr_in
		case ipv4(sockaddr_in)
		
		/// sockaddr_in6
		case ipv6(sockaddr_in6)
		
		/// sockaddr_un
		case unix(sockaddr_un)
		
		///
		/// Size of address. (Readonly)
		///
		public var size: Int {
			
			switch self {
				
			case .ipv4( _):
				return MemoryLayout<(sockaddr_in)>.size
			case .ipv6( _):
				return MemoryLayout<(sockaddr_in6)>.size
			case .unix( _):
				return MemoryLayout<(sockaddr_un)>.size
			}
		}
		
		///
		/// Cast as sockaddr. (Readonly)
		///
		public var addr: sockaddr {
			
			switch self {
				
			case .ipv4(let addr):
				return addr.asAddr()
				
			case .ipv6(let addr):
				return addr.asAddr()

			case .unix(let addr):
				return addr.asAddr()
			}
		}
	}
	
	// MARK: Structs
	
	// MARK: -- Signature
	
	///
	/// Socket signature: contains the characteristics of the socket.
	///
	public struct Signature: CustomStringConvertible {
		
		// MARK: -- Public Properties
		
		///
		/// Protocol Family
		///
		public internal(set) var protocolFamily: ProtocolFamily
		
		///
		/// Socket Type. (Readonly)
		///
		public internal(set) var socketType: SocketType
		
		///
		/// Socket Protocol. (Readonly)
		///
		public internal(set) var proto: SocketProtocol
		
		///
		/// Host name for connection. (Readonly)
		///
		public internal(set) var hostname: String? = Socket.NO_HOSTNAME
		
		///
		/// Port for connection. (Readonly)
		///
		public internal(set) var port: Int32 = Socket.SOCKET_INVALID_PORT
		
		///
		/// Path for .unix type sockets. (Readonly)
		public internal(set) var path: String? = nil
		
		///
		/// Address info for socket. (Readonly)
		///
		public internal(set) var address: Address? = nil
		
		///
		/// Flag to indicate whether `Socket` is secure or not. (Readonly)
		///
		public internal(set) var isSecure: Bool = false
		
		///
		/// Returns a string description of the error.
		///
		public var description: String {
			
			return "Signature: family: \(protocolFamily), type: \(socketType), protocol: \(proto), address: \(address as Socket.Address?), hostname: \(hostname as String?), port: \(port), path: \(path), secure: \(isSecure)"
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
			self.protocolFamily = .inet
			
			self.socketType = socketType
			self.proto = proto
			
			self.hostname = hostname
			self.port = port
		}
		
		///
		/// Create a socket signature
		///
		///	- Parameters:
		///		- socketType:		The type of socket to create.
		///		- proto:			The protocool to use for the socket.
		/// 	- path:				Pathname for this signature.
		///
		/// - Returns: New Signature instance
		///
		public init?(socketType: SocketType, proto: SocketProtocol, path: String?) throws {
			
			// Make sure we have what we need...
			guard let _ = path else {
					
				throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Missing pathname.")
			}
			
			// Default to Unix socket protocol family...
			self.protocolFamily = .unix
			
			self.socketType = socketType
			self.proto = proto
			
			self.path = path

			if path!.utf8.count == 0 {
				
				throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Specified path contains zero (0) bytes.")
			}

			// Create the address...
			var remoteAddr = sockaddr_un()
			remoteAddr.sun_family = sa_family_t(AF_UNIX)
			
			let lengthOfPath = path!.utf8.count
			
			// Validate the length...
			guard lengthOfPath < MemoryLayout.size(ofValue: remoteAddr.sun_path) else {
				
				throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Pathname supplied is too long.")
			}
			
			_ = withUnsafeMutablePointer(to: &remoteAddr.sun_path.0) { ptr in
				
				path!.withCString {
					strncpy(ptr, $0, lengthOfPath)
				}
			}
			
			#if !os(Linux)
			    remoteAddr.sun_len = UInt8(MemoryLayout<UInt8>.size + MemoryLayout<sa_family_t>.size + path!.utf8.count + 1)
			#endif
			
			self.address = .unix(remoteAddr)
			print("Socket Signature:\(self)")
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
		internal init?(protocolFamily: Int32, socketType: Int32, proto: Int32, address: Address?, hostname: String?, port: Int32?) throws {
			
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
	
	///
	/// `Socket` specific error structure.
	///
	public struct Error: Swift.Error, CustomStringConvertible {
		
		// MARK: -- Public Properties
		
		///
		/// The error domain.
		///
		public let domain: String = SOCKET_ERR_DOMAIN
		
		///
		/// The error code: **see constants above for possible errors** (Readonly)
		///
		public internal(set) var errorCode: Int32
		
		///
		/// The reason for the error **(if available)** (Readonly)
		///
		public internal(set) var errorReason: String?
		
		///
		/// Returns a string description of the error. (Readonly)
		///
		public var description: String {
			
			let reason: String = self.errorReason ?? "Reason: Unavailable"
			return "Error code: \(self.errorCode), \(reason)"
		}
		
		///
		/// The buffer size needed to complete the read. (Readonly)
		///
		public internal(set) var bufferSizeNeeded: Int32
		
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
		init(bufferSize: Int) {
			
			self.init(code: Socket.SOCKET_ERR_RECV_BUFFER_TOO_SMALL, reason: nil)
			self.bufferSizeNeeded = Int32(bufferSize)
		}
		
		///
		/// Initializes an Error instance using SSLError
		///
		/// - Parameter error: SSLError instance to be transformed
		///
		/// - Returns: Error Instance
		init(with error: SSLError) {
			
			self.init(code: error.code, reason: error.description)
		}
	}
	
	// MARK: Properties
	
	// MARK: -- Private
	
	///
	/// Internal read buffer.
	/// 	**Note:** The readBuffer is actually allocating unmanaged memory that'll
	///			be deallocated when we're done with it.
	///
	var readBuffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: Socket.SOCKET_DEFAULT_READ_BUFFER_SIZE)
	
	///
	/// Internal Storage Buffer initially created with `Socket.SOCKET_DEFAULT_READ_BUFFER_SIZE`.
	///
	var readStorage: NSMutableData = NSMutableData(capacity: Socket.SOCKET_DEFAULT_READ_BUFFER_SIZE)!
	
	
	// MARK: -- Public
	
	///
	/// The file descriptor representing this socket. (Readonly)
	///
	public internal(set) var socketfd: Int32 = SOCKET_INVALID_DESCRIPTOR
	
	///
	/// The signature for the socket. (Readonly)
	/// 	**Note:** See Signature above.
	///
	public internal(set) var signature: Signature? = nil
	
	///
	/// The delegate that provides the SSL implementation.
	///
	public var delegate: SSLServiceDelegate?
	
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
				readBuffer.deallocate(capacity: oldValue)
				readBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: readBufferSize)
				readBuffer.initialize(to:0)
			}
		}
	}
	
	///
	/// Maximum size of the queue containing pending connections.
	///		**Note:** Default value is `Socket.SOCKET_DEFAULT_MAX_BACKLOG`
	///
	public var maxBacklogSize: Int = Socket.SOCKET_DEFAULT_MAX_BACKLOG
	
	///
	/// True if this socket is connected. False otherwise. (Readonly)
	///
	public internal(set) var isConnected: Bool = false
	
	///
	/// True if this socket is blocking. False otherwise. (Readonly)
	///
	public internal(set) var isBlocking: Bool = true
	
	///
	/// True if this socket is listening. False otherwise. (Readonly)
	///
	public internal(set) var isListening: Bool = false
	
	///
	/// True if this socket's remote connection has closed. (Readonly)
	///		**Note:** This is only valid after a Socket is connected.
	///
	public internal(set) var remoteConnectionClosed: Bool = false
	
	///
	/// True if the socket is listening or connected. (Readonly)
	///
	public var isActive: Bool {
		
		return isListening || isConnected
	}
	
	///
	/// True if this a server, false otherwise. (Readonly)
	///
	public var isServer: Bool {
		
		return isListening
	}
	
	///
	/// True if this socket is secure, false otherwise. (Readonly)
	///
	public var isSecure: Bool {
		
		guard let sig = signature else {
			return false
		}
		return sig.isSecure
	}
	
	///
	/// Listening port (-1 if not listening). (Readonly)
	///
	public var listeningPort: Int32 {
		
		guard let sig = signature, isListening else {
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
		
		guard let sig = signature, sig.port != Socket.SOCKET_INVALID_PORT else {
			return Socket.SOCKET_INVALID_PORT
		}
		
		return sig.port
	}
	
	///
	/// The path this socket is connected to or listening on. (Readonly)
	///
	public var remotePath: String? {
		
		guard let sig = signature,
			let path = sig.path else {
			return nil
		}
		
		return path
	}
	
	
	// MARK: Class Methods
	
	///
	/// Create a configured Socket instance.
	/// **Note:** Calling with no passed parameters will create a default socket: IPV4, stream, TCP.
	///
	/// - Parameters:
	///		- family:	The family of the socket to create.
	///		- type:		The type of socket to create.
	///		- proto:	The protocool to use for the socket.
	///
	/// - Returns: New Socket instance
	///
	public class func create(family: ProtocolFamily = .inet, type: SocketType = .stream, proto: SocketProtocol = .tcp) throws -> Socket {
		
		if type == .datagram || proto == .udp {
			
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
	public class func create(connectedUsing signature: Signature) throws -> Socket {
		
		let socket = try Socket(family: signature.protocolFamily, type: signature.socketType, proto: signature.proto)
		
		try socket.connect(using: signature)
		
		return socket
	}
	
	///
	/// Create an instance for existing open socket fd.
	///
	/// - Parameters:
	///		- nativeHandle: Open file descriptor.
	///		- address: 		The Address associated with the open fd.
	///
	/// - Returns: New Socket instance
	///
	public class func create(fromNativeHandle nativeHandle: Int32, address: Address?) throws -> Socket {
		
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
			
		case .ipv4(let address_in):
			var addr_in = address_in
			let addr = addr_in.asAddr()
			bufLen = Int(INET_ADDRSTRLEN)
			buf = [CChar](repeating: 0, count: bufLen)
			inet_ntop(Int32(addr.sa_family), &addr_in.sin_addr, &buf, socklen_t(bufLen))
			if isLittleEndian {
				port = Int32(UInt16(addr_in.sin_port).byteSwapped)
			} else {
				port = Int32(UInt16(addr_in.sin_port))
			}

		case .ipv6(let address_in):
			var addr_in = address_in
			let addr = addr_in.asAddr()
			bufLen = Int(INET6_ADDRSTRLEN)
			buf = [CChar](repeating: 0, count: bufLen)
			inet_ntop(Int32(addr.sa_family), &addr_in.sin6_addr, &buf, socklen_t(bufLen))
			if isLittleEndian {
				port = Int32(UInt16(addr_in.sin6_port).byteSwapped)
			} else {
				port = Int32(UInt16(addr_in.sin6_port))
			}

		default:
			return nil
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
	
	///
	/// Monitor an array of sockets, returning when data is available or timeout occurs.
	///
	/// - Parameters:
	///		- sockets:		An array of sockets to be monitored.
	///		- timeout:		Timeout (in msec) before returning.  A timeout value of 0 will return immediately.
	///		- waitForever:	If true, this function will wait indefinitely regardless of timeout value. Defaults to false.
	///
	/// - Returns: An optional array of sockets which have data available or nil if a timeout expires.
	///
	public class func wait(for sockets: [Socket], timeout: UInt, waitForever: Bool = false) throws -> [Socket]? {
		
		// Validate we have sockets to look for and they are valid...
		for socket in sockets {
			
			if socket.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {
				
				throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
			}
			if !socket.isActive {
				
				throw Error(code: Socket.SOCKET_ERR_NOT_ACTIVE, reason: nil)
			}
		}
		
		// Setup the timeout...
		var timer = timeval()
		if timeout > 0  && !waitForever {
			
			// First get seconds...
			let secs = Int(Double(timeout / 1000))
			timer.tv_sec = secs
			
			// Now get the leftover millisecs...
			let msecs = Int32(Double(timeout % 1000))
			
			// Note: timeval expects microseconds, convert now...
			let uSecs = msecs * 1000
			
			// Now the leftover microseconds...
			#if os(Linux)
				timer.tv_usec = Int(uSecs)
			#else
				timer.tv_usec = Int32(uSecs)
			#endif
		}
		
		// Setup the array of readfds...
		var readfds = fd_set()
		FD.ZERO(set: &readfds)
		
		var highSocketfd: Int32 = 0
		for socket in sockets {
			
			if socket.socketfd > highSocketfd {
				highSocketfd = socket.socketfd
			}
			FD.SET(fd: socket.socketfd, set: &readfds)
		}
		
		// Issue the select...
		var count: Int32 = 0
		if waitForever {
			count = select(highSocketfd + 1, &readfds, nil, nil, nil)
		} else {
			count = select(highSocketfd + 1, &readfds, nil, nil, &timer)
		}
		
		// A count of less than zero indicates select failed...
		if count < 0 {
			
			throw Error(code: Socket.SOCKET_ERR_SELECT_FAILED, reason: String(validatingUTF8: strerror(errno)) ?? "Error: \(errno)")
		}
		
		// A count equal zero, indicates we timed out...
		if count == 0 {
			return nil
		}
		
		// Build the array of returned sockets...
		var dataSockets = [Socket]()
		for socket in sockets {
			
			if FD.ISSET(fd: socket.socketfd, set: &readfds) {
				dataSockets.append(socket)
			}
		}
		
		return dataSockets
	}
	
	// MARK: Lifecycle Methods
	
	// MARK: -- Private
	
	///
	/// Internal initializer to create a configured Socket instance.
	///
	/// - Parameters:
	///		- family:	The family of the socket to create.
	///		- type:		The type of socket to create.
	///		- proto:	The protocol to use for the socket.
	///
	/// - Returns: New Socket instance
	///
	private init(family: ProtocolFamily, type: SocketType, proto: SocketProtocol) throws {
		
		// Initialize the read buffer...
		self.readBuffer.initialize(to: 0)
		
		// If the family is .unix, set the protocol to .unix as well...
		var sockProto = proto
		if family == .unix {
			sockProto = .unix
		}
		
		// Create the socket...
		#if os(Linux)
			self.socketfd = Glibc.socket(family.value, type.value, sockProto.value)
		#else
			self.socketfd = Darwin.socket(family.value, type.value, sockProto.value)
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
			proto: sockProto.value,
			address: nil)
	}

	///
	/// Private constructor to create an instance for existing open socket fd.
	///
	/// - Parameters:
	///		- fd: 				Open file descriptor.
	///		- remoteAddress: 	The Address associated with the open fd.
	///
	/// - Returns: New Socket instance
	///
	private init(fd: Int32, remoteAddress: Address, path: String? = nil) throws {
		
		self.isConnected = true
		self.isListening = false
		self.readBuffer.initialize(to: 0)
		
		self.socketfd = fd
		
		// Create the signature...
		#if os(Linux)
			let type = Int32(SOCK_STREAM.rawValue)
		#else
			let type = SOCK_STREAM
		#endif
		
		if path != nil {
			
			try self.signature = Signature(socketType: .stream, proto: .unix, path: path)
			
		} else {
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
        self.readBuffer.deallocate(capacity: self.readBufferSize)

        // If we have a delegate, tell it to cleanup too...
        self.delegate?.deinitialize()
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
		var socketfd2: Int32 = Socket.SOCKET_INVALID_DESCRIPTOR
		var address: Address? = nil
		
		var keepRunning: Bool = true
		repeat {
			
			switch self.signature!.protocolFamily {
				
			case .inet:
				var acceptAddr = sockaddr_in()
				var addrSize = socklen_t(MemoryLayout<sockaddr_in>.size)
				
				#if os(Linux)
					let fd = withUnsafeMutablePointer(to: &acceptAddr) {
						Glibc.accept(self.socketfd, UnsafeMutableRawPointer($0).assumingMemoryBound(to: sockaddr.self), &addrSize)
					}
				#else
					let fd = withUnsafeMutablePointer(to: &acceptAddr) {
						Darwin.accept(self.socketfd, UnsafeMutableRawPointer($0).assumingMemoryBound(to: sockaddr.self), &addrSize)
					}
				#endif
				if fd < 0 {
					
					if errno == EINTR {
						continue
					}
					
					throw Error(code: Socket.SOCKET_ERR_ACCEPT_FAILED, reason: self.lastError())
				}
				socketfd2 = fd
				address = .ipv4(acceptAddr)
				
			case .inet6:
				var acceptAddr = sockaddr_in6()
				var addrSize = socklen_t(MemoryLayout<sockaddr_in6>.size)
				
				#if os(Linux)
					let fd = withUnsafeMutablePointer(to: &acceptAddr) {
						Glibc.accept(self.socketfd, UnsafeMutableRawPointer($0).assumingMemoryBound(to: sockaddr.self), &addrSize)
					}
				#else
					let fd = withUnsafeMutablePointer(to: &acceptAddr) {
						Darwin.accept(self.socketfd, UnsafeMutableRawPointer($0).assumingMemoryBound(to: sockaddr.self), &addrSize)
					}
				#endif
				if fd < 0 {
					
					if errno == EINTR {
						continue
					}
					
					throw Error(code: Socket.SOCKET_ERR_ACCEPT_FAILED, reason: self.lastError())
				}
				socketfd2 = fd
				address = .ipv6(acceptAddr)
				
			case .unix:
				var acceptAddr = sockaddr_un()
				var addrSize = socklen_t(MemoryLayout<sockaddr_un>.size)
				
				#if os(Linux)
					let fd = withUnsafeMutablePointer(to: &acceptAddr) {
						Glibc.accept(self.socketfd, UnsafeMutableRawPointer($0).assumingMemoryBound(to: sockaddr.self), &addrSize)
					}
				#else
					let fd = withUnsafeMutablePointer(to: &acceptAddr) {
						Darwin.accept(self.socketfd, UnsafeMutableRawPointer($0).assumingMemoryBound(to: sockaddr.self), &addrSize)
					}
				#endif
				if fd < 0 {
					
					if errno == EINTR {
						continue
					}
					
					throw Error(code: Socket.SOCKET_ERR_ACCEPT_FAILED, reason: self.lastError())
				}
				socketfd2 = fd
				address = .unix(acceptAddr)
				
			}
			
			keepRunning = false
			
		} while keepRunning
		
		// Create the new socket...
		//	Note: The current socket continues to listen.
		let newSocket = try Socket(fd: socketfd2, remoteAddress: address!, path: self.signature?.path)
		
		// Let the delegate do post accept handling and verification...
		do {
			
			if self.delegate != nil {
				try self.delegate?.onAccept(socket: newSocket)
				newSocket.signature?.isSecure = true
			}
			
		} catch let error {
			
			guard let sslError = error as? SSLError else {
				
				throw error
			}
			
			throw Error(with: sslError)
		}
		
		// Return the new socket...
		return newSocket
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
		var socketfd2: Int32 = Socket.SOCKET_INVALID_DESCRIPTOR
		var address: Address? = nil
		
		var keepRunning: Bool = true
		repeat {
			
			switch self.signature!.protocolFamily {
				
			case .inet:
				var acceptAddr = sockaddr_in()
				var addrSize = socklen_t(MemoryLayout<sockaddr_in>.size)
				
				#if os(Linux)
					let fd = withUnsafeMutablePointer(to: &acceptAddr) {
						Glibc.accept(self.socketfd, UnsafeMutableRawPointer($0).assumingMemoryBound(to: sockaddr.self), &addrSize)
					}
				#else
					let fd = withUnsafeMutablePointer(to: &acceptAddr) {
						Darwin.accept(self.socketfd, UnsafeMutableRawPointer($0).assumingMemoryBound(to: sockaddr.self), &addrSize)
					}
				#endif
				if fd < 0 {
					
					if errno == EINTR {
						continue
					}
					
					throw Error(code: Socket.SOCKET_ERR_ACCEPT_FAILED, reason: self.lastError())
				}
				socketfd2 = fd
				address = .ipv4(acceptAddr)
				
			case .inet6:
				var acceptAddr = sockaddr_in6()
				var addrSize = socklen_t(MemoryLayout<sockaddr_in6>.size)
				
				#if os(Linux)
					let fd = withUnsafeMutablePointer(to: &acceptAddr) {
						Glibc.accept(self.socketfd, UnsafeMutableRawPointer($0).assumingMemoryBound(to: sockaddr.self), &addrSize)
					}
				#else
					let fd = withUnsafeMutablePointer(to: &acceptAddr) {
						Darwin.accept(self.socketfd, UnsafeMutableRawPointer($0).assumingMemoryBound(to: sockaddr.self), &addrSize)
					}
				#endif
				if fd < 0 {
					
					if errno == EINTR {
						continue
					}
					
					throw Error(code: Socket.SOCKET_ERR_ACCEPT_FAILED, reason: self.lastError())
				}
				socketfd2 = fd
				address = .ipv6(acceptAddr)

			case .unix:
				var acceptAddr = sockaddr_un()
				var addrSize = socklen_t(MemoryLayout<sockaddr_un>.size)
				
				#if os(Linux)
					let fd = withUnsafeMutablePointer(to: &acceptAddr) {
						Glibc.accept(self.socketfd, UnsafeMutableRawPointer($0).assumingMemoryBound(to: sockaddr.self), &addrSize)
					}
				#else
					let fd = withUnsafeMutablePointer(to: &acceptAddr) {
						Darwin.accept(self.socketfd, UnsafeMutableRawPointer($0).assumingMemoryBound(to: sockaddr.self), &addrSize)
					}
				#endif
				if fd < 0 {
					
					if errno == EINTR {
						continue
					}
					
					throw Error(code: Socket.SOCKET_ERR_ACCEPT_FAILED, reason: self.lastError())
				}
				socketfd2 = fd
				address = .unix(acceptAddr)
				
			}
			
			keepRunning = false
			
		} while keepRunning
		
		// Close the old socket...
		self.close()
		
		// Save the address...
		self.signature!.address = address
		
		// Replace the existing socketfd with the new one...
		self.socketfd = socketfd2
		
		if let (hostname, port) = Socket.hostnameAndPort(from: address!) {
			self.signature!.hostname = hostname
			self.signature!.port = port
		}
		
		// We're connected but no longer listening...
		self.isConnected = true
		self.isListening = false
		
		// Let the delegate do post accept handling and verification...
		do {
			
			if self.delegate != nil {
				try self.delegate?.onAccept(socket: self)
				self.signature?.isSecure = true
			}
			
		} catch let error {
			
			guard let sslError = error as? SSLError else {
				
				throw error
			}
			
			throw Error(with: sslError)
		}
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
					_ = Glibc.shutdown(self.socketfd, Int32(SHUT_RDWR))
				}
				_ = Glibc.close(self.socketfd)
			#else
				if self.isListening {
					_ = Darwin.shutdown(self.socketfd, Int32(SHUT_RDWR))
				}
				_ = Darwin.close(self.socketfd)
			#endif
			
			self.socketfd = Socket.SOCKET_INVALID_DESCRIPTOR
		}
		
		if let _ = self.signature {
			self.signature!.hostname = Socket.NO_HOSTNAME
			self.signature!.port = Socket.SOCKET_INVALID_PORT
			self.signature!.path = nil
			self.signature!.isSecure = false
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
		
		if port == 0 {
			
			throw Error(code: Socket.SOCKET_ERR_INVALID_PORT, reason: "Connect to port cannot be zero (0).")
		}
		
		// Tell the delegate to initialize as a client...
		do {
			
			try self.delegate?.initialize(asServer: false)
			
		} catch let error {
			
			guard let sslError = error as? SSLError else {
				
				throw error
			}
			
			throw Error(with: sslError)
		}
		
		// Create the hints for our search...
		let socketType: SocketType = .stream
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
		
		var targetInfo: UnsafeMutablePointer<addrinfo>? = UnsafeMutablePointer<addrinfo>.allocate(capacity: 1)
		
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
		while info != nil {
			
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
				_ = Glibc.close(socketDescriptor!)
			#else
				_ = Darwin.close(socketDescriptor!)
			#endif
			socketDescriptor = nil
			info = info?.pointee.ai_next
		}
		
		// Throw if there is a status error...
		if status != 0 || socketDescriptor == nil {
			
			if socketDescriptor != nil {
				#if os(Linux)
					_ = Glibc.close(socketDescriptor!)
				#else
					_ = Darwin.close(socketDescriptor!)
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
			memcpy(&addr, info!.pointee.ai_addr, Int(MemoryLayout<sockaddr_in6>.size))
			address = .ipv6(addr)
			
		} else if info!.pointee.ai_family == Int32(AF_INET) {
			
			var addr = sockaddr_in()
			memcpy(&addr, info!.pointee.ai_addr, Int(MemoryLayout<sockaddr_in>.size))
			address = .ipv4(addr)
			
		} else {
			
			throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "Unable to determine connected socket protocol family.")
		}
		
		try self.signature = Signature(
			protocolFamily: Int32(info!.pointee.ai_family),
			socketType: info!.pointee.ai_socktype,
			proto: info!.pointee.ai_protocol,
			address: address,
			hostname: host,
			port: port)
		
		// Let the delegate do post connect handling and verification...
		do {
			
			if self.delegate != nil {
				try self.delegate?.onConnect(socket: self)
				self.signature?.isSecure = true
			}
			
		} catch let error {
			
			guard let sslError = error as? SSLError else {
				
				throw error
			}
			
			throw Error(with: sslError)
		}
	}
	
	///
	/// Connects to the named host on the specified port.
	///
	/// - Parameters path:	Path to connect to.
	///
	public func connect(to path: String) throws {
		
		// Make sure this is a UNIX socket...
		guard let sig = self.signature, sig.protocolFamily == .unix else {
			
			throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: nil)
		}
		
		// The socket must've been created and must not be connected...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {
			
			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		if self.isConnected {
			
			throw Error(code: Socket.SOCKET_ERR_ALREADY_CONNECTED, reason: nil)
		}
		
		// Create the signature...
		self.signature = try Signature(socketType: .stream, proto: .unix, path: path)
		guard let signature = self.signature else {
			
			throw Error(code: Socket.SOCKET_ERR_MISSING_CONNECTION_DATA, reason: "Unable to access connection data.")
		}
		
		// Now, do the connection using the supplied address...
		var remoteAddr = signature.address!.addr
		
		#if os(Linux)
			let rc = withUnsafeMutablePointer(to: &remoteAddr) {
				Glibc.connect(self.socketfd, UnsafeMutablePointer($0), socklen_t(signature.address!.size))
			}
		#else
			let rc = withUnsafeMutablePointer(to: &remoteAddr) {
				Darwin.connect(self.socketfd, UnsafeMutablePointer($0), socklen_t(signature.address!.size))
			}
		#endif
		if rc < 0 {
			
			throw Error(code: Socket.SOCKET_ERR_CONNECT_FAILED, reason: self.lastError())
		}
		
		self.isConnected = true
	}

	///
	/// Connect to the address or hostname/port or path pointed to by the signature passed.
	///
	/// - Parameter signature:	Signature containing the address hostname/port to connect to.
	///
	public func connect(using signature: Signature) throws {
		
		// Ensure we've got a proper address...
		//	Handle the Unix style socket first...
		if let path = signature.path {
			
			try self.connect(to: path)
			return
		}
		
		if signature.hostname == nil || signature.port == Socket.SOCKET_INVALID_PORT  {
			
			guard let _ = signature.address else {
				
				throw Error(code: Socket.SOCKET_ERR_MISSING_CONNECTION_DATA, reason: "Unable to access connection data.")
			}
			
		} else {
			
			// Otherwise, make sure we've got a hostname and port...
			guard let hostname = signature.hostname,
				signature.port != Socket.SOCKET_INVALID_PORT else {
					
					throw Error(code: Socket.SOCKET_ERR_MISSING_CONNECTION_DATA, reason: "Unable to access hostname and port.")
			}
			
			// Connect using hostname and port....
			try self.connect(to: hostname, port: signature.port)
			return
		}
		
		// Tell the delegate to initialize as a client...
		do {
			
			try self.delegate?.initialize(asServer: false)
			
		} catch let error {
			
			guard let sslError = error as? SSLError else {
				
				throw error
			}
			
			throw Error(with: sslError)
		}
		
		// Now, do the connection using the supplied address...
		var remoteAddr = signature.address!.addr
		
		#if os(Linux)
			let rc = withUnsafeMutablePointer(to: &remoteAddr) {
				Glibc.connect(self.socketfd, UnsafeMutablePointer($0), socklen_t(signature.address!.size))
			}
		#else
			let rc = withUnsafeMutablePointer(to: &remoteAddr) {
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
		
		// Let the delegate do post connect handling and verification...
		do {
			
			if self.delegate != nil {
				try self.delegate?.onConnect(socket: self)
				self.signature?.isSecure = true
			}
			
		} catch let error {
			
			guard let sslError = error as? SSLError else {
				
				throw error
			}
			
			throw Error(with: sslError)
		}
	}
	
	// MARK: -- Listen
	
	///
	/// Listen on a port, limiting the maximum number of pending connections.
	///
	/// - Parameters:
	///		- port: 				The port to listen on.
	/// 	- maxBacklogSize: 		The maximum size of the queue containing pending connections. Default is *Socket.SOCKET_DEFAULT_MAX_BACKLOG*.
	///
	public func listen(on port: Int, maxBacklogSize: Int = Socket.SOCKET_DEFAULT_MAX_BACKLOG) throws {
		
		// Set a flag so that this address can be re-used immediately after the connection
		// closes.  (TCP normally imposes a delay before an address can be re-used.)
		var on: Int32 = 1
		if setsockopt(self.socketfd, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
			
			throw Error(code: Socket.SOCKET_ERR_SETSOCKOPT_FAILED, reason: self.lastError())
		}
		
		#if !os(Linux)
			// Set the socket to ignore SIGPIPE to avoid dying on interrupted connections...
			//	Note: Linux does not support the SO_NOSIGPIPE option. Instead, we use the
			//		  MSG_NOSIGNAL flags passed to send.  See the writeData() functions below.
			if setsockopt(self.socketfd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
				
				throw Error(code: Socket.SOCKET_ERR_SETSOCKOPT_FAILED, reason: self.lastError())
			}
		#endif
		
		// Get the signature for the socket...
		guard let sig = self.signature else {
			
			throw Error(code: Socket.SOCKET_ERR_INTERNAL, reason: "Socket signature not found.")
		}
		
		// Tell the delegate to initialize as a server...
		do {
			
			try self.delegate?.initialize(asServer: true)
			
		} catch let error {
			
			guard let sslError = error as? SSLError else {
				
				throw error
			}
			
			throw Error(with: sslError)
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
		
		var targetInfo: UnsafeMutablePointer<addrinfo>? = UnsafeMutablePointer<addrinfo>.allocate(capacity: 1)
		
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
		while info != nil {
			
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
		
		// If the port was set to zero, we need to retrieve the port that assigned by the OS...
		if port == 0 {
		
			let addr = sockaddr_storage()
			var length = socklen_t(MemoryLayout<sockaddr_storage>.size)
			var addrPtr = addr.asAddr()
			if getsockname(self.socketfd, &addrPtr, &length) == 0 {
				
				if addrPtr.sa_family == sa_family_t(AF_INET6) {
					
					var addr = sockaddr_in6()
					memcpy(&addr, &addrPtr, Int(MemoryLayout<sockaddr_in6>.size))
					address = .ipv6(addr)
					
				} else if addrPtr.sa_family == sa_family_t(AF_INET) {
					
					var addr = sockaddr_in()
					memcpy(&addr, &addrPtr, Int(MemoryLayout<sockaddr_in>.size))
					address = .ipv4(addr)
					
				} else {
					
					throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "Unable to determine listening socket protocol family.")
				}
				
			} else {
				
				throw Error(code: Socket.SOCKET_ERR_BIND_FAILED, reason: "Unable to determine listening socket address after bind.")
			}
		
		} else {
		
			if info!.pointee.ai_family == Int32(AF_INET6) {
			
				var addr = sockaddr_in6()
				memcpy(&addr, info!.pointee.ai_addr, Int(MemoryLayout<sockaddr_in6>.size))
				address = .ipv6(addr)
		
			} else if info!.pointee.ai_family == Int32(AF_INET) {
		
				var addr = sockaddr_in()
				memcpy(&addr, info!.pointee.ai_addr, Int(MemoryLayout<sockaddr_in>.size))
				address = .ipv4(addr)
		
			} else {
			
				throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "Unable to determine listening socket protocol family.")
			}
			
		}
		
		self.signature?.address = address
		
		// Update our hostname and port...
		if let (hostname, port) = Socket.hostnameAndPort(from: address) {
			self.signature?.hostname = hostname
			self.signature?.port = Int32(port)
		}
		
		// Now listen for connections...
		#if os(Linux)
			if Glibc.listen(self.socketfd, Int32(maxBacklogSize)) < 0 {
				
				throw Error(code: Socket.SOCKET_ERR_LISTEN_FAILED, reason: self.lastError())
			}
		#else
			if Darwin.listen(self.socketfd, Int32(maxBacklogSize)) < 0 {
				
				throw Error(code: Socket.SOCKET_ERR_LISTEN_FAILED, reason: self.lastError())
			}
		#endif
		
		self.isListening = true
		self.signature?.isSecure = self.delegate != nil ? true : false
	}
	
	///
	/// Listen on a path, limiting the maximum number of pending connections.
	///
	/// - Parameters:
	///		- path: 				The path to listen on.
	/// 	- maxBacklogSize: 		The maximum size of the queue containing pending connections. Default is *Socket.SOCKET_DEFAULT_MAX_BACKLOG*.
	///
	public func listen(on path: String, maxBacklogSize: Int = Socket.SOCKET_DEFAULT_MAX_BACKLOG) throws {

		// Make sure this is a UNIX socket...
		guard let sockSig = self.signature, sockSig.protocolFamily == .unix else {
			
			throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: nil)
		}
		
		// Set a flag so that this address can be re-used immediately after the connection
		// closes.  (TCP normally imposes a delay before an address can be re-used.)
		var on: Int32 = 1
		if setsockopt(self.socketfd, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
			
			throw Error(code: Socket.SOCKET_ERR_SETSOCKOPT_FAILED, reason: self.lastError())
		}
		
		#if !os(Linux)
			// Set the socket to ignore SIGPIPE to avoid dying on interrupted connections...
			//	Note: Linux does not support the SO_NOSIGPIPE option. Instead, we use the
			//		  MSG_NOSIGNAL flags passed to send.  See the writeData() functions below.
			if setsockopt(self.socketfd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
				
				throw Error(code: Socket.SOCKET_ERR_SETSOCKOPT_FAILED, reason: self.lastError())
			}
		#endif

		// Create the signature...
		let sig = try Signature(socketType: .stream, proto: .unix, path: path)
		guard let signature = sig else {
			
			throw Error(code:Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: nil)
		}
		
		// Ensure the path doesn't exist...
		#if os(Linux)
			_ = Glibc.unlink(path)
		#else
			_ = Darwin.unlink(path)
		#endif
		
		// Try to bind the socket to the address...
		var localAddr = signature.address!.addr
		#if os(Linux)
			let rc = Glibc.bind(self.socketfd, &localAddr, socklen_t(signature.address!.size))
		#else
			let rc = Darwin.bind(self.socketfd, &localAddr, socklen_t(signature.address!.size))
		#endif
		
		if rc < 0 {
			
			throw Error(code: Socket.SOCKET_ERR_LISTEN_FAILED, reason: self.lastError())
		}

		// Now listen for connections...
		#if os(Linux)
			if Glibc.listen(self.socketfd, Int32(maxBacklogSize)) < 0 {
				
				throw Error(code: Socket.SOCKET_ERR_LISTEN_FAILED, reason: self.lastError())
			}
		#else
			if Darwin.listen(self.socketfd, Int32(maxBacklogSize)) < 0 {
				
				throw Error(code: Socket.SOCKET_ERR_LISTEN_FAILED, reason: self.lastError())
			}
		#endif
		
		self.isListening = true
		self.signature?.path = path
		self.signature?.isSecure = false
		self.signature?.address = signature.address
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
			
			throw Error(code: Socket.SOCKET_ERR_INTERNAL, reason: "Unable to create temporary NSMutableData...")
		}
		
		let rc = try self.read(into: data)
		
		guard let str = NSString(bytes: data.bytes, length: data.length, encoding: String.Encoding.utf8.rawValue),
			rc > 0 else {
				
				throw Error(code: Socket.SOCKET_ERR_INTERNAL, reason: "Unable to convert data to NSString.")
		}
		
		return String(describing: str)
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
			
			data.append(self.readStorage.bytes, length: self.readStorage.length)

			returnCount = self.readStorage.length
			
			// - Reset the storage buffer...
			self.readStorage.length = 0
		}
		
		return returnCount
	}
	
	///
	/// Read data from the socket.
	///
	/// - Parameter data: The buffer to return the data in.
	///
	/// - Returns: The number of bytes returned in the buffer.
	///
	public func read(into data: inout Data) throws -> Int {
		
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
			data.append(self.readStorage.bytes.assumingMemoryBound(to: UInt8.self), count: self.readStorage.length)
			
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
		guard let sig = self.signature,
			sig.proto == .udp else {
			
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
		guard let sig = self.signature,
			sig.proto == .udp else {
			
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
	/// - Returns: Integer representing the number of bytes written.
	///
	@discardableResult public func write(from buffer: UnsafeRawPointer, bufSize: Int) throws -> Int {
		
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
			
			var s = 0
			if self.delegate != nil {
				
				repeat {
					
					do {
					
						s = try self.delegate!.send(buffer: buffer.advanced(by: sent), bufSize: Int(bufSize - sent))
						
						break
					
					} catch let error {
					
						guard let err = error as? SSLError else {
						
							throw error
						}
						
						switch err {
	
						case .success:
							break
							
						case .retryNeeded:
							do {
								
								try wait(forRead: false)
								
							} catch let waitError {
								
								throw waitError
							}
							continue
							
						default:
							throw Error(with: err)
						}
					
					}
					
				} while true
				
			} else {
				#if os(Linux)
					s = Glibc.send(self.socketfd, buffer.advanced(by: sent), Int(bufSize - sent), sendFlags)
				#else
					s = Darwin.send(self.socketfd, buffer.advanced(by: sent), Int(bufSize - sent), sendFlags)
				#endif
			}
			if s <= 0 {
				
				if errno == EAGAIN && !isBlocking {
					
					// We have written out as much as we can...
					return sent
				}
				
				// - Handle a connection reset by peer (ECONNRESET) and throw a different exception...
				if errno == ECONNRESET {
					
					throw Error(code: Socket.SOCKET_ERR_CONNECTION_RESET, reason: self.lastError())
				}
				
				throw Error(code: Socket.SOCKET_ERR_WRITE_FAILED, reason: self.lastError())
			}
			sent += s
		}
		
		return sent
	}
	
	///
	/// Write data to the socket.
	///
	/// - Parameter data: The NSData object containing the data to write.
	///
	/// - Returns: Integer representing the number of bytes written.
	///
	@discardableResult public func write(from data: NSData) throws -> Int {
		
		// If there's no data in the NSData object, why bother? Fail silently...
		if data.length == 0 {
			return 0
		}
		
		return try write(from: data.bytes.assumingMemoryBound(to: UInt8.self), bufSize: data.length)
	}
	
	///
	/// Write data to the socket.
	///
	/// - Parameter data: The Data object containing the data to write.
	///
	/// - Returns: Integer representing the number of bytes written.
	///
	@discardableResult public func write(from data: Data) throws -> Int {
		
		// If there's no data in the Data object, why bother? Fail silently...
		if data.count == 0 {
			return 0
		}
		
		return try data.withUnsafeBytes() { [unowned self] (buffer: UnsafePointer<UInt8>) throws -> Int in
			
			return try self.write(from: buffer, bufSize: data.count)
		}
	}

	///
	/// Write a string to the socket.
	///
	/// - Parameter string: The string to write.
	///
	/// - Returns: Integer representing the number of bytes written.
	///
	@discardableResult public func write(from string: String) throws -> Int {
		
		return try string.utf8CString.withUnsafeBufferPointer() {
			
			// The count returned by nullTerminatedUTF8 includes the null terminator...
			return try self.write(from: $0.baseAddress!, bufSize: $0.count-1)
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
	public func write(from buffer: UnsafeRawPointer, bufSize: Int, to addresss: Address) throws {
		
		// Make sure the buffer is valid...
		if bufSize == 0 {
			
			throw Error(code: Socket.SOCKET_ERR_INVALID_BUFFER, reason: nil)
		}
		
		// The socket must've been created and must be connected...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {
			
			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		// The socket must've been created for UDP...
		guard let sig = self.signature,
			sig.proto == .udp else {
			
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
		guard let sig = self.signature,
			sig.proto == .udp else {
			
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
	/// - Parameters:
 	///		- waitForever:	True to wait forever, false to check and return.  Default: false.
	///		- timeout:		Timeout (in msec) before returning.  A timeout value of 0 will return immediately.
	///
	/// - Returns: Tuple containing two boolean values, one for readable and one for writable.
	///
	public func isReadableOrWritable(waitForever: Bool = false, timeout: UInt = 0) throws -> (readable: Bool, writable: Bool) {
		
		// The socket must've been created and must be connected...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {
			
			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		if !self.isConnected {
			
			throw Error(code: Socket.SOCKET_ERR_NOT_CONNECTED, reason: nil)
		}
		
		// Create a read and write file descriptor set for this socket...
		var readfds = fd_set()
		FD.ZERO(set: &readfds)
		FD.SET(fd: self.socketfd, set: &readfds)
		
		var writefds = fd_set()
		FD.ZERO(set: &writefds)
		FD.SET(fd: self.socketfd, set: &writefds)
		
		// Do the wait...
		var count: Int32 = 0
		if waitForever {
			
			// Wait forever for data...
			count = select(self.socketfd + 1, &readfds, &writefds, nil, nil)
		
		} else {
		
			// Default timeout of zero (i.e. don't wait)...
			var timer = timeval()
			
			// But honor callers desires...
			if timeout > 0 {
				
				// First get seconds...
				let secs = Int(Double(timeout / 1000))
				timer.tv_sec = secs
				
				// Now get the leftover millisecs...
				let msecs = Int32(Double(timeout % 1000))
				
				// Note: timeval expects microseconds, convert now...
				let uSecs = msecs * 1000
				
				// Now the leftover microseconds...
				#if os(Linux)
					timer.tv_usec = Int(uSecs)
				#else
					timer.tv_usec = Int32(uSecs)
				#endif
			}
			
			// See if there's data on the socket...
			count = select(self.socketfd + 1, &readfds, &writefds, nil, &timer)
		}
		
		// A count of less than zero indicates select failed...
		if count < 0 {
			
			throw Error(code: Socket.SOCKET_ERR_SELECT_FAILED, reason: self.lastError())
		}
		
		// Return a tuple containing whether or not this socket is readable and/or writable...
		return (FD.ISSET(fd: self.socketfd, set: &readfds), FD.ISSET(fd: self.socketfd, set: &writefds))
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
		self.readBuffer.initialize(to: 0x0)
		memset(self.readBuffer, 0x0, self.readBufferSize)
		
		// Read all the available data...
		var count: Int = 0
		repeat {
			
			if self.delegate != nil {
				
				repeat {
					
					do {

						count = try self.delegate!.recv(buffer: self.readBuffer, bufSize: self.readBufferSize)
						
						break
					
					} catch let error {
						
						guard let err = error as? SSLError else {
							
							throw error
						}
						
						switch err {
							
						case .success:
							break
							
						case .retryNeeded:
							do {
								
								try wait(forRead: true)
								
							} catch let waitError {
								
								throw waitError
							}
							continue
							
						default:
							throw Error(with: err)
						}
						
					}
					
				} while true
				
			} else {
				#if os(Linux)
					count = Glibc.recv(self.socketfd, self.readBuffer, self.readBufferSize, 0)
				#else
					count = Darwin.recv(self.socketfd, self.readBuffer, self.readBufferSize, 0)
				#endif
			}
			
			// Check for error...
			if count < 0 {
				
				// - Could be an error, but if errno is EAGAIN or EWOULDBLOCK (if a non-blocking socket),
				//		it means there was NO data to read...
				if errno == EAGAIN || errno == EWOULDBLOCK {
					
					return 0
				}
				
				// - Handle a connection reset by peer (ECONNRESET) and throw a different exception...
				if errno == ECONNRESET {
					
					throw Error(code: Socket.SOCKET_ERR_CONNECTION_RESET, reason: self.lastError())
				}
				
				// - Something went wrong...
				throw Error(code: Socket.SOCKET_ERR_RECV_FAILED, reason: self.lastError())
			}
			
			if count == 0 {
				
				self.remoteConnectionClosed = true
				return 0
			}
			
			if count > 0 {
				self.readStorage.append(self.readBuffer, length: count)
			}
			
			// Didn't fill the buffer so we've got everything available...
			if count < self.readBufferSize {
				
				break
			}
			
		} while count > 0
		
		return self.readStorage.length
	}
	
	///
	/// Private method to wait for this instance to be either readable or writable.
	///
	///	- Parameter forRead:	True to wait for socket to be readable, false waits for it to be writable.
	///
	private func wait(forRead: Bool) throws {
		
		repeat {
			
			let result = try self.isReadableOrWritable(waitForever: true)
				
			if forRead {
					
				if result.readable {
					return
				} else {
					continue
				}
				
			} else {
				
				if result.writable {
					return
				} else {
					continue
				}
			}
			
		} while true
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
