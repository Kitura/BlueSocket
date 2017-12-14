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

#if os(macOS) || os(iOS) || os(tvOS)
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
	public static let SOCKET_DEFAULT_SSL_READ_BUFFER_SIZE	= 32768
	public static let SOCKET_MAXIMUM_SSL_READ_BUFFER_SIZE	= 8000000
	public static let SOCKET_DEFAULT_MAX_BACKLOG			= 50
	#if os(macOS) || os(iOS) || os(tvOS)
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
	public static let SOCKET_ERR_SET_RECV_TIMEOUT_FAILED	= -9970
	public static let SOCKET_ERR_SET_WRITE_TIMEOUT_FAILED	= -9969
	public static let SOCKET_ERR_CONNECT_TIMEOUT			= -9968
	public static let SOCKET_ERR_GETSOCKOPT_FAILED			= -9967
	public static let SOCKET_ERR_INVALID_DELEGATE_CALL		= -9966
	public static let SOCKET_ERR_MISSING_SIGNATURE			= -9965
	
	///
	/// Specialized Operation Exception
	///
	enum OperationInterrupted: Swift.Error {
	
		/// Low level socket accept was interrupted.
		/// - **Note:** This is typically _NOT_ an error.
		case accept
		
		/// Low level datagram read was interrupted.
		/// - **Note:** This is typically _NOT_ an error.
		case readDatagram(length: Int)
	}
	
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
		
		public var family: ProtocolFamily {
			switch self {
			case .ipv4(_):
				return ProtocolFamily.inet
			case .ipv6(_):
				return ProtocolFamily.inet6
			case .unix(_):
				return ProtocolFamily.unix
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
		/// True is socket bound, false otherwise.
		///
		public internal(set) var isBound: Bool = false

		///
		/// Returns a string description of the error.
		///
		public var description: String {

			return "Signature: family: \(protocolFamily), type: \(socketType), protocol: \(proto), address: \(address as Socket.Address?), hostname: \(hostname as String?), port: \(port), path: \(String(describing: path)), bound: \(isBound), secure: \(isSecure)"
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

			// Validate the parameters...
			if type == .stream {
				guard pro == .tcp || pro == .unix else {

					throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Stream socket must use either .tcp or .unix for the protocol.")
				}
			}
			if type == .datagram {
				guard pro == .udp || pro == .unix else {

					throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Datagram socket must use .udp or .unix for the protocol.")
				}
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
		///		- protocolFamily:	The protocol family to use (only `.inet` and `.inet6` supported by this `init` function).
		///		- socketType:		The type of socket to create.
		///		- proto:			The protocool to use for the socket.
		/// 	- hostname:			Hostname for this signature.
		/// 	- port:				Port for this signature.
		///
		/// - Returns: New Signature instance
		///
		public init?(protocolFamily: ProtocolFamily, socketType: SocketType, proto: SocketProtocol, hostname: String?, port: Int32?) throws {

			// Make sure we have what we need...
			guard let _ = hostname,
				let port = port, protocolFamily == .inet || protocolFamily == .inet6 else {

					throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Missing hostname, port or both or invalid protocol family.")
			}

			self.protocolFamily = protocolFamily

			// Validate the parameters...
			if socketType == .stream {
				guard proto == .tcp || proto == .unix else {

					throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Stream socket must use either .tcp or .unix for the protocol.")
				}
			}
			if socketType == .datagram {
				guard proto == .udp || proto == .unix else {

					throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Datagram socket must use .udp or .unix for the protocol.")
				}
			}

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
			guard let path = path, !path.isEmpty else {

				throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Missing pathname.")
			}

			// Default to Unix socket protocol family...
			self.protocolFamily = .unix

			self.socketType = socketType
			self.proto = proto

			// Validate the parameters...
			if socketType == .stream {
				guard proto == .tcp || proto == .unix else {

					throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Stream socket must use either .tcp or .unix for the protocol.")
				}
			}
			if socketType == .datagram {
				guard proto == .udp || proto == .unix else {

					throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Datagram socket must use .udp or .unix for the protocol.")
				}
			}

			self.path = path

			// Create the address...
			var remoteAddr = sockaddr_un()
			remoteAddr.sun_family = sa_family_t(AF_UNIX)

			let lengthOfPath = path.utf8.count

			// Validate the length...
			guard lengthOfPath < MemoryLayout.size(ofValue: remoteAddr.sun_path) else {

				throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Pathname supplied is too long.")
			}

			_ = withUnsafeMutablePointer(to: &remoteAddr.sun_path.0) { ptr in

				let buf = UnsafeMutableBufferPointer(start: ptr, count: MemoryLayout.size(ofValue: remoteAddr.sun_path))
				for (i, b) in path.utf8.enumerated() {
					buf[i] = Int8(b)
				}
			}

			#if !os(Linux)
			    remoteAddr.sun_len = UInt8(MemoryLayout<UInt8>.size + MemoryLayout<sa_family_t>.size + path.utf8.count + 1)
			#endif

			self.address = .unix(remoteAddr)
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

			// Validate the parameters...
			if type == .stream {
				guard pro == .tcp || pro == .unix else {

					throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Stream socket must use either .tcp or .unix for the protocol.")
				}
			}
			if type == .datagram {
				guard pro == .udp else {

					throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Datagram socket must use .udp for the protocol.")
				}
			}

			self.address = address

			self.hostname = hostname
			self.port = port
		}

		///
		///	Retrieve the UNIX address as an UnsafeMutablePointer
		///
		///	- Returns: Tuple containing the pointer plus the size.  **Needs to be deallocated after use.**
		///
		internal func unixAddress() throws -> (UnsafeMutablePointer<UInt8>, Int) {

			// Throw an exception if the path is not set...
			if path == nil {

				throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Specified path contains zero (0) bytes.")
			}

			let utf8 = path!.utf8

			// macOS has a size identifier in front, Linux does not...
			#if os(Linux)
				let addrLen = MemoryLayout<sockaddr_un>.size
			#else
				let addrLen = MemoryLayout<UInt8>.size + MemoryLayout<sa_family_t>.size + utf8.count + 1
			#endif
			let addrPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: addrLen)

			var memLoc = 0

			// macOS uses one byte for sa_family_t, Linux uses two...
			#if os(Linux)
				let afUnixShort = UInt16(AF_UNIX)
				addrPtr[memLoc] = UInt8(afUnixShort & 0xFF)
				memLoc += 1
				addrPtr[memLoc] = UInt8((afUnixShort >> 8) & 0xFF)
				memLoc += 1
			#else
				addrPtr[memLoc] = UInt8(addrLen)
				memLoc += 1
				addrPtr[memLoc] = UInt8(AF_UNIX)
				memLoc += 1
			#endif

			// Copy the pathname...
			for char in utf8 {
				addrPtr[memLoc] = char
				memLoc += 1
			}

			addrPtr[memLoc] = 0

			return (addrPtr, addrLen)
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
			return "Error code: \(self.errorCode)(0x\(String(self.errorCode, radix: 16, uppercase: true))), \(reason)"
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
	
	///
	/// True if a delegate accept is pending.
	///
	var needsAcceptDelegateCall: Bool = false


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
	public var delegate: SSLServiceDelegate? = nil {

		didSet {

			// If setting an SSL delegate, bump up the read buffer size...
			if delegate != nil {
				readBufferSize = Socket.SOCKET_DEFAULT_SSL_READ_BUFFER_SIZE
			}
		}
	}

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


	// MARK: Class Functions

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

		// Validate the parameters...
		if type == .stream {
			guard proto == .tcp || proto == .unix else {

				throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Stream socket must use either .tcp or .unix for the protocol.")
			}
		}
		if type == .datagram {
			guard proto == .udp || proto == .unix else {

				throw Error(code: Socket.SOCKET_ERR_BAD_SIGNATURE_PARAMETERS, reason: "Datagram socket must use .udp or .unix for the protocol.")
			}
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
			bufLen = Int(INET_ADDRSTRLEN)
			buf = [CChar](repeating: 0, count: bufLen)
			inet_ntop(Int32(addr_in.sin_family), &addr_in.sin_addr, &buf, socklen_t(bufLen))
			if isLittleEndian {
				port = Int32(UInt16(addr_in.sin_port).byteSwapped)
			} else {
				port = Int32(UInt16(addr_in.sin_port))
			}

		case .ipv6(let address_in):
			var addr_in = address_in
			bufLen = Int(INET6_ADDRSTRLEN)
			buf = [CChar](repeating: 0, count: bufLen)
			inet_ntop(Int32(addr_in.sin6_family), &addr_in.sin6_addr, &buf, socklen_t(bufLen))
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
			if socket.signature == nil {
				
				throw Error(code: Socket.SOCKET_ERR_MISSING_SIGNATURE, reason: nil)
			}
			if !socket.isActive && !socket.signature!.isBound {

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
			count = select(highSocketfd + Int32(1), &readfds, nil, nil, nil)
		} else {
			count = select(highSocketfd + Int32(1), &readfds, nil, nil, &timer)
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

	///
	/// Creates an Address for a given host and port.
	///
	///	- Parameters:
	/// 	- hostname:			Hostname for this signature.
	/// 	- port:				Port for this signature.
	///
	/// - Returns: An Address instance, or nil if the hostname and port are not valid.
	///
	public class func createAddress(for host: String, on port: Int32) -> Address? {

		var info: UnsafeMutablePointer<addrinfo>?

		// Retrieve the info on our target...
		var status: Int32 = getaddrinfo(host, String(port), nil, &info)
		if status != 0 {

			return nil
		}

		// Defer cleanup of our target info...
		defer {

			if info != nil {
				freeaddrinfo(info)
			}
		}

		var address: Address
		if info!.pointee.ai_family == Int32(AF_INET) {

			var addr = sockaddr_in()
			memcpy(&addr, info!.pointee.ai_addr, Int(MemoryLayout<sockaddr_in>.size))
			address = .ipv4(addr)

		} else if info!.pointee.ai_family == Int32(AF_INET6) {

			var addr = sockaddr_in6()
			memcpy(&addr, info!.pointee.ai_addr, Int(MemoryLayout<sockaddr_in6>.size))
			address = .ipv6(addr)

		} else {

			return nil
		}

		return address
	}

	// MARK: Lifecycle Functions

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

		#if !os(Linux)
			// Set the socket to ignore SIGPIPE to avoid dying on interrupted connections...
			// Note: Linux does not support the SO_NOSIGPIPE option. Instead, we use the
			// MSG_NOSIGNAL flags passed to send.  See the write() functions below.
			var on: Int32 = 1
			if setsockopt(self.socketfd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
				throw Error(code: Socket.SOCKET_ERR_SETSOCKOPT_FAILED, reason: self.lastError())
			}
		#endif

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

			// Set the socket to ignore SIGPIPE to avoid dying on interrupted connections...
			// Note: Linux does not support the SO_NOSIGPIPE option. Instead, we use the
			// MSG_NOSIGNAL flags passed to send.  See the write() functions below.
			var on: Int32 = 1
			if setsockopt(self.socketfd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
				throw Error(code: Socket.SOCKET_ERR_SETSOCKOPT_FAILED, reason: self.lastError())
			}
		#endif

		if path != nil {

			try self.signature = Signature(socketType: .stream, proto: .unix, path: path)

		} else {
			if let (hostname, port) = Socket.hostnameAndPort(from: remoteAddress) {
				try self.signature = Signature(
					protocolFamily: remoteAddress.family.value,
					socketType: type,
					proto: Int32(IPPROTO_TCP),
					address: remoteAddress,
					hostname: hostname,
					port: port)
			} else {
				try self.signature = Signature(
					protocolFamily: remoteAddress.family.value,
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
    }

	// MARK: Public Functions

	// MARK: -- Accept

	///
	/// Accepts an incoming client connection request on the current instance, leaving the current instance still listening.
    ///
    /// - Parameters:
    ///		- invokeDelegate: 		Whether to invoke the delegate's `onAccept()` function after accepting
    ///                             a new connection. Defaults to `true`
	///
	/// - Returns: New Socket instance representing the newly accepted socket.
	///
    public func acceptClientConnection(invokeDelegate: Bool = true) throws -> Socket {

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
			do {
				guard let acceptAddress = try Address(addressProvider: { (addressPointer, addressLengthPointer) in
					#if os(Linux)
						let fd = Glibc.accept(self.socketfd, addressPointer, addressLengthPointer)
					#else
						let fd = Darwin.accept(self.socketfd, addressPointer, addressLengthPointer)
					#endif
					
					if fd < 0 {
						
						// The operation was interrupted, continue the loop...
						if errno == EINTR {
							throw OperationInterrupted.accept
						}
						
						// Note: if you're running tests inside Xcode and the tests stop on this line
						//  and the tests fail, but they work if you run `swift test` on the
						//  command line, Hit `Deactivate Breakpoints` in Xcode and try again
						throw Error(code: Socket.SOCKET_ERR_ACCEPT_FAILED, reason: self.lastError())
					}
					socketfd2 = fd
				}) else {
					throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "Unable to determine incoming socket protocol family.")
				}
				address = acceptAddress
				
			} catch OperationInterrupted.accept {
				
				continue
			}

			keepRunning = false

		} while keepRunning

		// Create the new socket...
		//	Note: The current socket continues to listen.
		let newSocket = try Socket(fd: socketfd2, remoteAddress: address!, path: self.signature?.path)
		
		// If there's a delegate, turn on the needs accept flag...
		if self.delegate != nil {
			newSocket.needsAcceptDelegateCall = true
		}

        // Let the delegate do post accept handling and verification...
        if invokeDelegate, self.delegate != nil {
            try invokeDelegateOnAccept(for: newSocket)
        }
		
        // Return the new socket...
        return newSocket
    }
	
	///
    /// Invokes the delegate's `onAccept()` function for a client socket. This should be performed
    /// only with a Socket obtained by calling `acceptClientConnection(invokeDelegate: false)`.
    ///
    /// - Parameters:
    ///		- newSocket: 		The newly accepted Socket that requires further processing by our delegate
    ///
    public func invokeDelegateOnAccept(for newSocket: Socket) throws {
		
		// Only allow this if the socket needs it, otherwise it's a error...
		if !newSocket.needsAcceptDelegateCall {
			
			throw Error(code: Socket.SOCKET_ERR_INVALID_DELEGATE_CALL, reason: nil)
		}
		
		do {
			
			if self.delegate != nil {
				try self.delegate?.onAccept(socket: newSocket)
				newSocket.signature?.isSecure = true
				self.needsAcceptDelegateCall = false
            }
			
        } catch let error {
			
			guard let sslError = error as? SSLError else {
				throw error
			}
			
			throw Error(with: sslError)
		}
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
			do {
				guard let acceptAddress = try Address(addressProvider: { (addressPointer, addressLengthPointer) in
					#if os(Linux)
						let fd = Glibc.accept(self.socketfd, addressPointer, addressLengthPointer)
					#else
						let fd = Darwin.accept(self.socketfd, addressPointer, addressLengthPointer)
					#endif
					
					if fd < 0 {
						
						// The operation was interrupted, continue the loop...
						if errno == EINTR {
							throw OperationInterrupted.accept
						}
						
						// Note: if you're running tests inside Xcode and the tests stop on this line
						//  and the tests fail, but they work if you run `swift test` on the
						//  command line, Hit `Deactivate Breakpoints` in Xcode and try again
						throw Error(code: Socket.SOCKET_ERR_ACCEPT_FAILED, reason: self.lastError())
					}
					socketfd2 = fd
				}) else {
					throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "Unable to determine incoming socket protocol family.")
				}
				address = acceptAddress
				
			} catch OperationInterrupted.accept {
				
				continue
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

		self.close(withSSLCleanup: true)
	}

	// MARK: -- Connect

	///
	/// Connects to the named host on the specified port.
	///
	/// - Parameters:
	///		- host:		The host name to connect to.
	///		- port:		The port to be used.
	///		- timeout:	Timeout to use (in msec). *Note: If the socket is in blocking mode it
	///					will be changed to non-blocking mode temporarily if a timeout greater
	///					than zero (0) is provided. The returned socket will be set back to its
	///					original setting (blocking or non-blocking).*
	///
	public func connect(to host: String, port: Int32, timeout: UInt = 0) throws {

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

		if port == 0 || port > 65535 {

			throw Error(code: Socket.SOCKET_ERR_INVALID_PORT, reason: "The port specified is invalid. Must be in the range of 1-65535.")
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

		var targetInfo: UnsafeMutablePointer<addrinfo>?

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
			
			// Check to see if the socket is in non-blocking mode or if a timeout is provided
			// 	If either is the case, set our trial socket to be non-blocking as well...
			if !self.isBlocking || timeout > 0 {
				
				let flags = fcntl(socketDescriptor!, F_GETFL)
				if flags < 0 {
					
					throw Error(code: Socket.SOCKET_ERR_GET_FCNTL_FAILED, reason: self.lastError())
				}
				
				let result = fcntl(socketDescriptor!, F_SETFL, flags | O_NONBLOCK)
				if result < 0 {
					
					throw Error(code: Socket.SOCKET_ERR_SET_FCNTL_FAILED, reason: self.lastError())
				}
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
			
			// If this is a non-blocking socket, check errno for EINPROGRESS and if set we've got a timeout, wait the appropriate time...
			if errno == EINPROGRESS {
				
				if timeout > 0 {
					
					// Set up for the select call...
					var writefds = fd_set()
					FD.ZERO(set: &writefds)
					FD.SET(fd: socketDescriptor!, set: &writefds)
					
					var timer = timeval()
					
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
					
					let count = select(socketDescriptor! + Int32(1), nil, &writefds, nil, &timer)
					if count < 0 {
						
						throw Error(code: Socket.SOCKET_ERR_SELECT_FAILED, reason: self.lastError())
					}
					
					// If the socket is writable, we're probably connected, but check anyway to be sure...
					//	Otherwise, we've timed out waiting to connect.
					if FD.ISSET(fd: socketDescriptor!, set: &writefds) {
						
						// Check the socket...
						var result: Int = 0
						var resultLength = socklen_t(MemoryLayout<Int>.size)
						if getsockopt(socketDescriptor!, SOL_SOCKET, SO_ERROR, &result, &resultLength) < 0 {
							
							throw Error(code: Socket.SOCKET_ERR_GETSOCKOPT_FAILED, reason: self.lastError())
						}
						
						// Check the result of the socket connect...
						if result == 0 {
							
							// Success, we're connected, clear status and break out of the loop...
							status = 0
							break
						}
					
					} else {
						
						throw Error(code: Socket.SOCKET_ERR_CONNECT_TIMEOUT, reason: self.lastError())
					}
				}
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

			self.close(withSSLCleanup: false)
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

		#if !os(Linux)
			// Set the new socket to ignore SIGPIPE to avoid dying on interrupted connections...
			// Note: Linux does not support the SO_NOSIGPIPE option. Instead, we use the
			// MSG_NOSIGNAL flags passed to send.  See the write() functions below.
			var on: Int32 = 1
			if setsockopt(self.socketfd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
				throw Error(code: Socket.SOCKET_ERR_SETSOCKOPT_FAILED, reason: self.lastError())
			}
		#endif

		try self.signature = Signature(
			protocolFamily: Int32(info!.pointee.ai_family),
			socketType: info!.pointee.ai_socktype,
			proto: info!.pointee.ai_protocol,
			address: address,
			hostname: host,
			port: port)
		
		// Check to see if the socket is supposed to be blocking or non-blocking and adjust the new socket...
		if self.isBlocking && timeout > 0 {
			
			// Socket supposed to be blocking but we've changed it to non-blocking because
			//	a timeout was requested...  Got to change it back before proceeding...
			let flags = fcntl(socketDescriptor!, F_GETFL)
			if flags < 0 {
				
				throw Error(code: Socket.SOCKET_ERR_GET_FCNTL_FAILED, reason: self.lastError())
			}
			
			let result = fcntl(self.socketfd, F_SETFL, flags & ~O_NONBLOCK)
			if result < 0 {
				
				throw Error(code: Socket.SOCKET_ERR_SET_FCNTL_FAILED, reason: self.lastError())
			}
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
		let (addrPtr, addrLen) = try signature.unixAddress()
		defer {
			addrPtr.deallocate(capacity: addrLen)
		}

		let rc = addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
			
			(p: UnsafeMutablePointer<sockaddr>) -> Int32 in

			#if os(Linux)
				return Glibc.connect(self.socketfd, p, socklen_t(addrLen))
			#else
				return Darwin.connect(self.socketfd, p, socklen_t(addrLen))
			#endif
		}
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

		// Make sure we've got a valid socket...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {

			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}

		// Ensure we've got a proper address...
		//	Handle the Unix style socket first...
		if let path = signature.path {

			try self.connect(to: path)
			return
		}

		if signature.hostname == nil || signature.port == Socket.SOCKET_INVALID_PORT {

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
		let rc = signature.address!.withSockAddrPointer { sockaddr, length -> Int32 in
			#if os(Linux)
				return Glibc.connect(self.socketfd, sockaddr, length)
			#else
				return Darwin.connect(self.socketfd, sockaddr, length)
			#endif
		}
		
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

	// MARK: --- TCP

	///
	/// Listen on a port, limiting the maximum number of pending connections.
	///
	/// - Parameters:
	///		- port: 				The port to listen on.
	/// 	- maxBacklogSize: 		The maximum size of the queue containing pending connections. Default is *Socket.SOCKET_DEFAULT_MAX_BACKLOG*.
	///		- allowPortReuse:		Set to `true` to allow the port to be reused. `false` otherwise. Default is `true`.
	///
	public func listen(on port: Int, maxBacklogSize: Int = Socket.SOCKET_DEFAULT_MAX_BACKLOG, allowPortReuse: Bool = true) throws {

		// Make sure we've got a valid socket...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {

			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}

		// Set a flag so that this address can be re-used immediately after the connection
		// closes.  (TCP normally imposes a delay before an address can be re-used.)
		var on: Int32 = 1
		if setsockopt(self.socketfd, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {

			throw Error(code: Socket.SOCKET_ERR_SETSOCKOPT_FAILED, reason: self.lastError())
		}

		// Allow port reuse if the caller desires...
		if allowPortReuse {
			
			// SO_REUSEPORT allows completely duplicate bindings by multiple processes if they
			// all set SO_REUSEPORT before binding the port.  This option permits multiple
			// instances of a program to each receive UDP/IP multicast or broadcast datagrams
			// destined for the bound port.
			if setsockopt(self.socketfd, SOL_SOCKET, SO_REUSEPORT, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
				
				// Setting of this option on WSL (Windows Subsytem for Linux) is not supported.  Check for
				// the appropriate errno value and if set, ignore the error...
				if errno != ENOPROTOOPT {
					throw Error(code: Socket.SOCKET_ERR_SETSOCKOPT_FAILED, reason: self.lastError())
				}
			}
		}

		// Get the signature for the socket...
		guard let sig = self.signature else {

			throw Error(code: Socket.SOCKET_ERR_INTERNAL, reason: "Socket signature not found.")
		}

        // Configure ipv6 socket so that it can share ports with ipv4 on the same port.
        if sig.protocolFamily == .inet6 && sig.proto == .tcp {
            if setsockopt(self.socketfd, Int32(IPPROTO_IPV6), IPV6_V6ONLY, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {

                throw Error(code: Socket.SOCKET_ERR_SETSOCKOPT_FAILED, reason: self.lastError())
            }
        }

		// No SSL over UDP...
		if sig.socketType != .datagram && sig.proto != .udp {

			// Tell the delegate to initialize as a server...
			do {

				try self.delegate?.initialize(asServer: true)

			} catch let error {

				guard let sslError = error as? SSLError else {

					throw error
				}

				throw Error(with: sslError)
			}
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

		var targetInfo: UnsafeMutablePointer<addrinfo>?

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
			guard let addressFromSockName = try Address(addressProvider: { (sockaddr, length) in
				if getsockname(self.socketfd, sockaddr, length) != 0 {
					throw Error(code: Socket.SOCKET_ERR_BIND_FAILED, reason: "Unable to determine listening socket address after bind.")
				}
			}) else {
				throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "Unable to determine listening socket protocol family.")
			}
			address = addressFromSockName
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

		// Update our hostname and port...
		if let (hostname, port) = Socket.hostnameAndPort(from: address) {
			self.signature?.hostname = hostname
			self.signature?.port = Int32(port)
		}

		self.signature?.isBound = true
		self.signature?.address = address

		// We don't actually listen for connections with a UDP socket, so we skip the next steps...
		if sig.socketType == .datagram && sig.proto == .udp {
			return
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

	// MARK: --- UNIX

	///
	/// Listen on a path, limiting the maximum number of pending connections.
	///
	/// - Parameters:
	///		- path: 				The path to listen on.
	/// 	- maxBacklogSize: 		The maximum size of the queue containing pending connections. Default is *Socket.SOCKET_DEFAULT_MAX_BACKLOG*.
	///
	public func listen(on path: String, maxBacklogSize: Int = Socket.SOCKET_DEFAULT_MAX_BACKLOG) throws {

		// Make sure we've got a valid socket...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {

			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}

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
		// Now, do the connection using the supplied address from the signature...
		let (addrPtr, addrLen) = try signature.unixAddress()
		defer {
			addrPtr.deallocate(capacity: addrLen)
		}

		let rc = addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
			
			(p: UnsafeMutablePointer<sockaddr>) -> Int32 in

			#if os(Linux)
				return Glibc.bind(self.socketfd, p, socklen_t(addrLen))
			#else
				return Darwin.bind(self.socketfd, p, socklen_t(addrLen))
			#endif
		}

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
		self.signature?.isBound = true
		self.signature?.isSecure = false
		self.signature?.address = signature.address
	}

	// MARK: --- UDP

	///
	/// Listen for a message on a UDP socket.
	///
	/// - Parameters:
	///		- buffer: 			The buffer to return the data in.
	/// 	- bufSize: 			The size of the buffer.
	///		- port:				Port to listen on.
	/// 	- maxBacklogSize: 	The maximum size of the queue containing pending connections. Default is *Socket.SOCKET_DEFAULT_MAX_BACKLOG*.
	///
	///	- Returns:				Tuple containing the number of bytes read and the `Address` of the client who sent the data.
	///
	public func listen(forMessage buffer: UnsafeMutablePointer<CChar>, bufSize: Int, on port: Int, maxBacklogSize: Int = Socket.SOCKET_DEFAULT_MAX_BACKLOG) throws -> (bytesRead: Int, address: Address?) {

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
			sig.socketType == .datagram else {

				throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "This is not a UDP socket.")
		}

		// Set up the socket for listening for a message unless we're already set up...
		if !sig.isBound {
			try self.listen(on: port, maxBacklogSize: maxBacklogSize)
		}

		// If we're not bound, something went wrong...
		guard self.signature?.isBound == true else {

			throw Error(code: Socket.SOCKET_ERR_LISTEN_FAILED, reason: "")
		}

		self.isListening = true

		return try self.readDatagram(into: buffer, bufSize: bufSize)
	}

	///
	/// Listen for a message on a UDP socket.
	///
	/// - Parameters:
	///		- data:				Data buffer to receive the data read.
	///		- port:				Port to listen on.
	/// 	- maxBacklogSize: 	The maximum size of the queue containing pending connections. Default is *Socket.SOCKET_DEFAULT_MAX_BACKLOG*.
	///
	///	- Returns:				Tuple containing the number of bytes read and the `Address` of the client who sent the data.
	///
	public func listen(forMessage data: NSMutableData, on port: Int, maxBacklogSize: Int = Socket.SOCKET_DEFAULT_MAX_BACKLOG) throws -> (bytesRead: Int, address: Address?) {

		// The socket must've been created...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {

			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}

		// The socket must've been created for UDP...
		guard let sig = self.signature,
			sig.socketType == .datagram && sig.proto == .udp else {

				throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "This is not a UDP socket.")
		}

		// Set up the socket for listening for a message unless we're already set up...
		if !sig.isBound {
			try self.listen(on: port, maxBacklogSize: maxBacklogSize)
		}

		// If we're not bound, something went wrong...
		guard self.signature?.isBound == true else {

			throw Error(code: Socket.SOCKET_ERR_LISTEN_FAILED, reason: "")
		}

		self.isListening = true

		return try self.readDatagram(into: data)
	}

	///
	/// Listen for a message on a UDP socket.
	///
	/// - Parameters:
	///		- data:				Data buffer to receive the data read.
	///		- port:				Port to listen on.
	/// 	- maxBacklogSize: 	The maximum size of the queue containing pending connections. Default is *Socket.SOCKET_DEFAULT_MAX_BACKLOG*.
	///
	///	- Returns:				Tuple containing the number of bytes read and the `Address` of the client who sent the data.
	///
	public func listen(forMessage data: inout Data, on port: Int, maxBacklogSize: Int = Socket.SOCKET_DEFAULT_MAX_BACKLOG) throws -> (bytesRead: Int, address: Address?) {

		// The socket must've been created...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {

			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}

		// The socket must've been created for UDP...
		guard let sig = self.signature,
			sig.socketType == .datagram else {

				throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "This is not a UDP socket.")
		}

		// Set up the socket for listening for a message unless we're already set up...
		if !sig.isBound {
			try self.listen(on: port, maxBacklogSize: maxBacklogSize)
		}

		// If we're not bound, something went wrong...
		guard self.signature?.isBound == true else {

			throw Error(code: Socket.SOCKET_ERR_LISTEN_FAILED, reason: "")
		}

		self.isListening = true

		return try self.readDatagram(into: &data)
	}

	// MARK: -- Read

	// MARK: --- TCP/UNIX

	///
	/// Read data from the socket.
	///
	/// - Parameters:
	///		- buffer: The buffer to return the data in.
	/// 	- bufSize: The size of the buffer.
	///		- truncate: Whether the data should be truncated if there is more available data than could fit in `buffer`.
	///			**Note:** If called with `truncate = true` unretrieved data will be returned on next `read` call.
	///
	/// - Throws: `Socket.SOCKET_ERR_RECV_BUFFER_TOO_SMALL` if the buffer provided is too small and `truncate = false`.
	///		Call again with proper buffer size (see `Error.bufferSizeNeeded`) or
	///		use `readData(data: NSMutableData)`.
	///
	/// - Returns: The number of bytes returned in the buffer.
	///
	public func read(into buffer: UnsafeMutablePointer<CChar>, bufSize: Int, truncate: Bool = false) throws -> Int {

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

				if truncate {

					memcpy(buffer, self.readStorage.bytes, bufSize)

					#if os(Linux)
						// Workaround for apparent bug in NSMutableData
						self.readStorage = NSMutableData(bytes: self.readStorage.bytes.advanced(by: bufSize), length:self.readStorage.length - bufSize)
					#else
						self.readStorage.replaceBytes(in: NSRange(location:0, length:bufSize), withBytes: nil, length: 0)
					#endif
					return bufSize

				} else {

					throw Error(bufferSize: self.readStorage.length)
				}
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

				// It isn't should we just use the available space?
				if truncate {

					// Yep, copy what storage we can and remove the bytes from the internal buffer.
					memcpy(buffer, self.readStorage.bytes, bufSize)

					#if os(Linux)
						// Workaround for apparent bug in NSMutableData
						self.readStorage = NSMutableData(bytes: self.readStorage.bytes.advanced(by: bufSize), length:self.readStorage.length - bufSize)
					#else
						self.readStorage.replaceBytes(in: NSRange(location:0, length:bufSize), withBytes: nil, length: 0)
					#endif

					return bufSize

				} else {

					// Nope, throw an exception telling the caller how big the buffer must be...
					throw Error(bufferSize: self.readStorage.length)
				}
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

	// MARK: --- UDP

	///
	/// Read data from a UDP socket.
	///
	/// - Parameters:
	///		- buffer: 	The buffer to return the data in.
	/// 	- bufSize: 	The size of the buffer.
	///		- address: 	Address to write data to.
	///
	/// - Returns: Tuple with the number of bytes returned in the buffer and the address they were received from.
	///
	public func readDatagram(into buffer: UnsafeMutablePointer<CChar>, bufSize: Int) throws -> (bytesRead: Int, address: Address?) {

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
			sig.socketType == .datagram else {

				throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "This is not a UDP socket.")
		}

		// Read all available bytes...
		let (count, address) = try self.readDatagramIntoStorage()

		// Check for disconnect...
		if count == 0 {

			return (count, nil)
		}

		// Did we get data?
		var returnCount: Int = 0
		if self.readStorage.length > 0 {

			// Is the caller's buffer big enough?
			if bufSize < self.readStorage.length {

				// No, discard the excess data...
				self.readStorage.length = bufSize
			}

			// - We've read data, copy to the callers buffer...
			memcpy(buffer, self.readStorage.bytes, self.readStorage.length)

			returnCount = self.readStorage.length

			// - Reset the storage buffer...
			self.readStorage.length = 0
		}

		return (returnCount, address)
	}

	///
	/// Read data from a UDP socket.
	///
	/// - Parameters:
	///		- data: 	The buffer to return the data in.
	///		- address: 	Address to write data to.
	///
	/// - Returns: Tuple with the number of bytes returned in the buffer and the address they were received from.
	///
	public func readDatagram(into data: NSMutableData) throws -> (bytesRead: Int, address: Address?) {

		// The socket must've been created...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {

			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}

		// The socket must've been created for UDP...
		guard let sig = self.signature,
			sig.socketType == .datagram else {

			throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "This is not a UDP socket.")
		}

		// Read all available bytes...
		let (count, address) = try self.readDatagramIntoStorage()

		// Did we get data?
		var returnCount: Int = 0
		if count > 0 {

			data.append(self.readStorage.bytes, length: self.readStorage.length)

			returnCount = self.readStorage.length

			// - Reset the storage buffer...
			self.readStorage.length = 0
		}

		return (returnCount, address)
	}

	///
	/// Read data from a UDP socket.
	///
	/// - Parameters:
	///		- data: 	The buffer to return the data in.
	///		- address: 	Address to write data to.
	///
	/// - Returns: Tuple with the number of bytes returned in the buffer and the address they were received from.
	///
	public func readDatagram(into data: inout Data) throws -> (bytesRead: Int, address: Address?) {

		// The socket must've been created...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {

			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}

		// The socket must've been created for UDP...
		guard let sig = self.signature,
			sig.socketType == .datagram else {

				throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "This is not a UDP socket.")
		}

		// Read all available bytes...
		let (count, address) = try self.readDatagramIntoStorage()

		// Did we get data?
		var returnCount: Int = 0
		if count > 0 {

			// - Yes, move to caller's buffer...
			data.append(self.readStorage.bytes.assumingMemoryBound(to: UInt8.self), count: self.readStorage.length)

			returnCount = self.readStorage.length

			// - Reset the storage buffer...
			self.readStorage.length = 0
		}

		return (returnCount, address)
	}

	// MARK: -- Write

	// MARK: --- TCP/UNIX

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
			// Ignore SIGPIPE to avoid process termination if the reader has closed the connection.
			// On Linux, we set the MSG_NOSIGNAL send flag. On OSX, we set SO_NOSIGPIPE during init().
			sendFlags = Int32(MSG_NOSIGNAL)
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

	// MARK: --- UDP

	///
	/// Write data to a UDP socket.
	///
	/// - Parameters:
	///		- buffer: 	The buffer containing the data to write.
	/// 	- bufSize: 	The size of the buffer.
	///		- address: 	Address to write data to.
	///
	/// - Returns: Integer representing the number of bytes written.
	///
	@discardableResult public func write(from buffer: UnsafeRawPointer, bufSize: Int, to address: Address) throws -> Int {

		// If the remote connection has closed, disallow the operation...
		if self.remoteConnectionClosed {
			return 0
		}

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
			sig.socketType == .datagram else {

			throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "This is not a UDP socket.")
		}

		return try address.withSockAddrPointer { addressPointer, addressLength -> Int in
			var sent = 0
			var sendFlags: Int32 = 0
			#if os(Linux)
				// Ignore SIGPIPE to avoid process termination if the reader has closed the connection.
				// On Linux, we set the MSG_NOSIGNAL send flag. On OSX, we set SO_NOSIGPIPE during init().
				sendFlags = Int32(MSG_NOSIGNAL)
			#endif
			
			while sent < bufSize {
				
				var s = 0
				#if os(Linux)
					s = Glibc.sendto(self.socketfd, buffer.advanced(by: sent), Int(bufSize - sent), sendFlags, addressPointer, addressLength)
				#else
					s = Darwin.sendto(self.socketfd, buffer.advanced(by: sent), Int(bufSize - sent), sendFlags, addressPointer, addressLength)
				#endif
				
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
	}

	///
	/// Write data to a UDP socket.
	///
	/// - Parameters:
	///		- data: 	The NSData object containing the data to write.
	///		- address: 	Address to write data to.
	///
	/// - Returns: Integer representing the number of bytes written.
	///
	@discardableResult public func write(from data: NSData, to address: Address) throws -> Int {

		// Send the bytes...
		return try write(from: data.bytes.assumingMemoryBound(to: UInt8.self), bufSize: data.length)
	}

	///
	/// Write data to a UDP socket.
	///
	/// - Parameters:
	///		- data: 	The Data object containing the data to write.
	///		- address: 	Address to write data to.
	///
	/// - Returns: Integer representing the number of bytes written.
	///
	@discardableResult public func write(from data: Data, to address: Address) throws -> Int {

		// Send the bytes...
		return try data.withUnsafeBytes() { [unowned self] (buffer: UnsafePointer<UInt8>) throws -> Int in

			return try self.write(from: buffer, bufSize: data.count, to: address)
		}
	}

	///
	/// Write a string to the UDP socket.
	///
	/// - Parameters:
 	///		- string: 	The string to write.
	///		- address: 	Address to write data to.
	///
	/// - Returns: Integer representing the number of bytes written.
	///
	@discardableResult public func write(from string: String, to address: Address) throws -> Int {

		return try string.utf8CString.withUnsafeBufferPointer() {

			// The count returned by nullTerminatedUTF8 includes the null terminator...
			return try self.write(from: $0.baseAddress!, bufSize: $0.count-1, to: address)
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
			count = select(self.socketfd + Int32(1), &readfds, &writefds, nil, nil)

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
			count = select(self.socketfd + Int32(1), &readfds, &writefds, nil, &timer)
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

	///
	/// Set read timeout.
	///
	/// - Parameters:
	///		- timeout:		Timeout (in msec) before returning.  A timeout value of 0 will return immediately.
	///
	public func setReadTimeout(value: UInt = 0) throws {

		// Default timeout of zero (i.e. don't wait)...
		var timer = timeval()

		// But honor callers desires...
		if value > 0 {

			// First get seconds...
			let secs = Int(Double(value / 1000))
			timer.tv_sec = secs

			// Now get the leftover millisecs...
			let msecs = Int32(Double(value % 1000))

			// Note: timeval expects microseconds, convert now...
			let uSecs = msecs * 1000

			// Now the leftover microseconds...
			#if os(Linux)
				timer.tv_usec = Int(uSecs)
			#else
				timer.tv_usec = Int32(uSecs)
			#endif
		}

		let result = setsockopt(self.socketfd, SOL_SOCKET, SO_RCVTIMEO, &timer, socklen_t(MemoryLayout<timeval>.stride))

		if result < 0 {

			throw Error(code: Socket.SOCKET_ERR_SET_RECV_TIMEOUT_FAILED, reason: self.lastError())
		}
	}

	///
	/// Set write timeout.
	///
	/// - Parameters:
	///		- timeout:		Timeout (in msec) before returning.  A timeout value of 0 will return immediately.
	///
	public func setWriteTimeout(value: UInt = 0) throws {

		// Default timeout of zero (i.e. don't wait)...
		var timer = timeval()

		// But honor callers desires...
		if value > 0 {

			// First get seconds...
			let secs = Int(Double(value / 1000))
			timer.tv_sec = secs

			// Now get the leftover millisecs...
			let msecs = Int32(Double(value % 1000))

			// Note: timeval expects microseconds, convert now...
			let uSecs = msecs * 1000

			// Now the leftover microseconds...
			#if os(Linux)
				timer.tv_usec = Int(uSecs)
			#else
				timer.tv_usec = Int32(uSecs)
			#endif
		}

		let result = setsockopt(self.socketfd, SOL_SOCKET, SO_SNDTIMEO, &timer, socklen_t(MemoryLayout<timeval>.stride))

		if result < 0 {

			throw Error(code: Socket.SOCKET_ERR_SET_WRITE_TIMEOUT_FAILED, reason: self.lastError())
		}
	}
	
	///
	/// Enable/disable broadcast on a UDP socket.
	///
	/// - Parameters:
	///		- enable:		`true` to enable broadcast, `false` otherwise.
	///
	public func udpBroadcast(enable: Bool) throws {
		
		// The socket must've been created and valid...
		if self.socketfd == Socket.SOCKET_INVALID_DESCRIPTOR {
			
			throw Error(code: Socket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		// The socket must've been created for UDP...
		guard let sig = self.signature,
			sig.socketType == .datagram else {
				
				throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "This is not a UDP socket.")
		}
		
		// Turn on or off UDP broadcasting...
		var on: Int32 = enable ? 1 : 0
		if setsockopt(self.socketfd, SOL_SOCKET, SO_BROADCAST, &on, socklen_t(MemoryLayout<Int32>.size)) < 0 {
			throw Error(code: Socket.SOCKET_ERR_SETSOCKOPT_FAILED, reason: self.lastError())
		}
	}

	// MARK: Private Functions

	///
	/// Closes the current socket.
	///
	///	- Parameters:
	///		- withSSLCleanup:	True to deinitialize the SSLService if present.
	///
	private func close(withSSLCleanup: Bool) {

		if self.socketfd != Socket.SOCKET_INVALID_DESCRIPTOR {

			// If we have a delegate, tell it to cleanup too...
			if withSSLCleanup {
				self.delegate?.deinitialize()
			}

			// Note: if the socket is listening, we need to shut it down prior to closing
			//		or the socket will be left hanging until it times out.
			#if os(Linux)
				if self.isListening {
					_ = Glibc.shutdown(self.socketfd, Int32(SHUT_RDWR))
					self.isListening = false
				}
				self.isConnected = false
				_ = Glibc.close(self.socketfd)
			#else
				if self.isListening {
					_ = Darwin.shutdown(self.socketfd, Int32(SHUT_RDWR))
					self.isListening = false
				}
				self.isConnected = false
				_ = Darwin.close(self.socketfd)
			#endif

			self.socketfd = Socket.SOCKET_INVALID_DESCRIPTOR
		}

		if let _ = self.signature {
			self.signature!.hostname = Socket.NO_HOSTNAME
			self.signature!.port = Socket.SOCKET_INVALID_PORT

			// If we've got a path to a UNIX socket and we're listening...
			//		Delete the file represented by the path as this listener
			//		is no longer available.
			if self.signature!.path != nil && self.isListening {
				#if os(Linux)
					_ = Glibc.unlink(self.signature!.path!)
				#else
					_ = Darwin.unlink(self.signature!.path!)
				#endif
			}
			self.signature!.path = nil
			self.signature!.isSecure = false
		}
	}

	///
	/// Private function that reads all available data on an open socket into storage.
	///
	/// - Returns: number of bytes read.
	///
	private func readDataIntoStorage() throws -> Int {

		// Clear the buffer...
		self.readBuffer.initialize(to: 0x0)

		var recvFlags: Int32 = 0
		if self.readStorage.length > 0 {
			recvFlags |= Int32(MSG_DONTWAIT)
		}

		// Read all the available data...
		var count: Int = 0
		repeat {

			if self.delegate == nil {

				#if os(Linux)
					count = Glibc.recv(self.socketfd, self.readBuffer, self.readBufferSize, recvFlags)
				#else
					count = Darwin.recv(self.socketfd, self.readBuffer, self.readBufferSize, recvFlags)
				#endif

			} else {

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

			}
			// Check for error...
			if count < 0 {

				switch errno {

				// - Could be an error, but if errno is EAGAIN or EWOULDBLOCK (if a non-blocking socket),
				//	it means there was NO data to read...
				case EAGAIN:
					fallthrough
				case EWOULDBLOCK:
					return self.readStorage.length

				case ECONNRESET:
					// - Handle a connection reset by peer (ECONNRESET) and throw a different exception...
					throw Error(code: Socket.SOCKET_ERR_CONNECTION_RESET, reason: self.lastError())

				default:
					// - Something went wrong...
					throw Error(code: Socket.SOCKET_ERR_RECV_FAILED, reason: self.lastError())
				}

			}

			if count == 0 {

				self.remoteConnectionClosed = true
				return 0
			}

			// Save the data in the buffer...
			self.readStorage.append(self.readBuffer, length: count)

			// Didn't fill the buffer so we've got everything available...
			if count < self.readBufferSize {

				break
			}

		} while count > 0

		return self.readStorage.length
	}

	///
	/// Private function that reads all available data on an open socket into storage.
	///
	/// - Returns: number of bytes read.
	///
	private func readDatagramIntoStorage() throws -> (bytesRead: Int, fromAddress: Address?) {

		// Clear the buffer...
		self.readBuffer.initialize(to: 0x0)
		var recvFlags: Int32 = 0
		if self.readStorage.length > 0 {
			recvFlags |= Int32(MSG_DONTWAIT)
		}
		
		do {
			guard let address = try Address(addressProvider: { (addresssPointer, addressLengthPointer) in
				
				// Read all the available data...
				#if os(Linux)
					let count = Glibc.recvfrom(self.socketfd, self.readBuffer, self.readBufferSize, recvFlags, addresssPointer, addressLengthPointer)
				#else
					let count = Darwin.recvfrom(self.socketfd, self.readBuffer, self.readBufferSize, recvFlags, addresssPointer, addressLengthPointer)
				#endif
				
				// Check for error...
				if count < 0 {
					
					// - Could be an error, but if errno is EAGAIN or EWOULDBLOCK (if a non-blocking socket),
					//		it means there was NO data to read...
					if errno == EAGAIN || errno == EWOULDBLOCK {

						throw OperationInterrupted.readDatagram(length: self.readStorage.length)
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
					throw OperationInterrupted.readDatagram(length: 0)
				}
				
				// Save the data in the buffer...
				self.readStorage.append(self.readBuffer, length: count)
			}) else {
				
				throw Error(code: Socket.SOCKET_ERR_WRONG_PROTOCOL, reason: "Unable to determine receiving socket protocol family.")
			}
			
			return (self.readStorage.length, address)
			
		} catch OperationInterrupted.readDatagram(let length) {
			
			return (length, nil)
		}
	}

	///
	/// Private function to wait for this instance to be either readable or writable.
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
	/// Private function to return the last error based on the value of errno.
	///
	/// - Returns: String containing relevant text about the error.
	///
	private func lastError() -> String {

		return String(validatingUTF8: strerror(errno)) ?? "Error: \(errno)"
	}

}
