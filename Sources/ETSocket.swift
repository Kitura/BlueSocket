//
//  ETSocket.swift
//  ETSocket
//
//  Created by Bill Abt on 11/9/15.
//  Copyright © 2015 IBM. All rights reserved.
//
//

#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
	import Darwin
	import Foundation
#elseif os(Linux)
	import Foundation
	import Glibc
#endif

// MARK: ETSocketError

public class ETSocketError: ErrorType, CustomStringConvertible {
	
	///
	/// The error code: **see ETSocket for possible errors**
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
		
		if let reason = self.errorReason {
			return "Error code: \(self.errorCode), Reason: \(reason)"
		}
		return "Error code: \(self.errorCode), Reason: Unavailable"
	}
	
	///
	/// The buffer size needed to complete the read.
	///
	public var bufferSizeNeeded: Int32
	
	///
	/// Initializes an ETSocketError Instance
	///
	/// - Parameter code:	Error code
	/// - Parameter reason:	Optional Error Reason
	///
	/// - Returns: ETSocketError instance
	///
	init(code: Int, reason: String?) {
		
		self.errorCode = Int32(code)
		self.errorReason = reason
		self.bufferSizeNeeded = 0
	}

	///
	/// Initializes an ETSocketError Instance for a too small receive buffer error.
	///
	///	- Parameter bufferSize:	Required buffer size
	///
	///	- Returns: ETSocketError Instance
	///
	convenience init(bufferSize: Int) {
		
		self.init(code: ETSocket.SOCKET_ERR_RECV_BUFFER_TOO_SMALL, reason: nil)
		self.bufferSizeNeeded = Int32(bufferSize)
	}
}

public class ETSocket: ETReader, ETWriter {
	
	// MARK: Constants
	
	public static let ETSOCKET_DOMAIN						= "ETSocket.ErrorDomain"
	
	public static let SOCKET_MINIMUM_READ_BUFFER_SIZE		= 1024
	public static let SOCKET_DEFAULT_READ_BUFFER_SIZE		= 4096
	public static let SOCKET_DEFAULT_MAX_CONNECTIONS		= 5

	public static let SOCKET_INVALID_PORT					= 0
	public static let SOCKET_INVALID_DESCRIPTOR 			= -1
	
	public static let INADDR_ANY							= in_addr_t(0)
	
	public static let NO_HOSTNAME							= "No hostname"
	
	// MARK: - Error Codes
	
	public static let SOCKET_ERR_UNABLE_TO_CREATE_SOCKET    = -9999
	public static let SOCKET_ERR_BAD_DESCRIPTOR				= -9998
	public static let SOCKET_ERR_ALREADY_CONNECTED			= -9997
	public static let SOCKET_ERR_NOT_CONNECTED				= -9996
	public static let SOCKET_ERR_NOT_LISTENING				= -9995
	public static let SOCKET_ERR_ACCEPT_FAILED				= -9994
	public static let SOCKET_ERR_SETSOCKOPT_FAILED			= -9993
	public static let SOCKET_ERR_BIND_FAILED				= -9992
	public static let SOCKET_ERR_INVALID_HOSTNAME			= -9991
	public static let SOCKET_ERR_GETHOSTBYNAME_FAILED		= -9990
	public static let SOCKET_ERR_CONNECT_FAILED				= -9989
	public static let SOCKET_ERR_SELECT_FAILED				= -9988
	public static let SOCKET_ERR_LISTEN_FAILED				= -9987
	public static let SOCKET_ERR_INVALID_BUFFER				= -9986
	public static let SOCKET_ERR_INVALID_BUFFER_SIZE		= -9985
	public static let SOCKET_ERR_RECV_FAILED				= -9984
	public static let SOCKET_ERR_RECV_BUFFER_TOO_SMALL		= -9983
	public static let SOCKET_ERR_WRITE_FAILED				= -9982
	public static let SOCKET_ERR_GET_FCNTL_FAILED			= -9981
	public static let SOCKET_ERR_SET_FCNTL_FAILED			= -9980
	public static let SOCKET_ERR_NOT_IMPLEMENTED			= -9979
	
	// MARK: Enums
	
	///
	/// Socket Protocol Family Values
	///
	public enum SocketProtocolFamily {
		
		case INET, INET6
		
		func valueOf() -> Int32 {
			switch(self) {
			case .INET:
				return Int32(AF_INET)
				
			case .INET6:
				return Int32(AF_INET6)
			}
		}
	}
	
	///
	/// Socket Type Values
	///
	/// **Note:** Only `STREAM`, i.e. `SOCK_STREAM`, supported at this time.
	///
	public enum SocketType {
		
		case STREAM
		
		func valueOf() -> Int32 {
			switch(self) {
			case .STREAM:
				#if os(Linux)
					return Int32(SOCK_STREAM.rawValue)
				#else
					return SOCK_STREAM
				#endif
			}
		}
	}
	
	///
	/// Socket Protocol Values
	///
	/// **Note:** Only `TCP`, i.e. `IPROTO_TCP`, supported at this time.
	///
	public enum SocketProtocol {
		case TCP
		
		func valueOf() -> Int32 {
			switch(self) {
			case .TCP:
				return Int32(IPPROTO_TCP)
			}
		}
	}
	
	// MARK: Properties
	
	// MARK: -- Private
	
	///
	/// Internal read buffer.
	/// 	**Note:** The readBuffer is actually allocating unmanaged memory that'll
	///			be deallocated when we're done with it.
	///
	var readBuffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.alloc(ETSocket.SOCKET_DEFAULT_READ_BUFFER_SIZE)
	
	///
	/// Internal Storage Buffer iniitially created with `ETSocket.SOCKET_DEFAULT_READ_BUFFER_SIZE`.
	///
	var readStorage: NSMutableData = NSMutableData(capacity: ETSocket.SOCKET_DEFAULT_READ_BUFFER_SIZE)!
	
	// MARK: -- Public
	
	///
	/// Internal Read buffer size for all open sockets.
	///		**Note:** Changing this value will cause the internal read buffer to
	///			be discarded and reallocated with the new size. The value must be
	///			set to at least `ETSocket.SOCKET_MINIMUM_READ_BUFFER_SIZE`. If set
	///			to something smaller, it will be automatically set to the minimum
	///			size as defined by `ETSocket.SOCKET_MINIMUM_READ_BUFFER_SIZE`.
	///
	public var readBufferSize: Int = ETSocket.SOCKET_DEFAULT_READ_BUFFER_SIZE {
		
		// If the buffer size changes we need to reallocate the buffer...
		didSet {
		
			// Ensure minimum buffer size...
			if readBufferSize < ETSocket.SOCKET_MINIMUM_READ_BUFFER_SIZE {
			
				readBufferSize = ETSocket.SOCKET_MINIMUM_READ_BUFFER_SIZE
			}
		
			print("Creating read buffer of size: \(readBufferSize)")
			if readBufferSize != oldValue {
			
				if readBuffer != nil {
					readBuffer.destroy()
					readBuffer.dealloc(oldValue)
				}
				readBuffer = UnsafeMutablePointer<CChar>.alloc(readBufferSize)
				readBuffer.initialize(0)
			}
		}
	}
	
	///
	/// Maximum number of pending connections per listening socket.
	///		**Note:** Default value is `ETSocket.SOCKET_DEFAULT_MAX_CONNECTIONS`
	///
	public var maxPendingConnections: Int = ETSocket.SOCKET_DEFAULT_MAX_CONNECTIONS
	
	///
	/// True if this socket is connected.
	///
	public private(set) var connected: Bool = false
	
	///
	/// True if this socket is blocking.
	///
	public private(set) var isBlocking: Bool = true
	
	///
	/// True if this socket is listening.
	///
	public private(set) var listening: Bool = false
	
	///
	/// The remote host name this socket is connected to. (Readonly)
	///
	public private(set) var remoteHostName: String = ETSocket.NO_HOSTNAME
	
	///
	/// The remote port this socket is connected to. (Readonly)
	///
	public private(set) var	remotePort: Int = SOCKET_INVALID_PORT
	
	///
	/// The file descriptor representing this socket. (Readonly)
	///
	public private(set) var socketfd: Int32 = Int32(SOCKET_INVALID_DESCRIPTOR)
	
	
	// MARK: Class Methods
	
	///
	/// Creates a default pre-configured ETSocket instance.
	///
	/// - Returns: New ETSocket instance
	///
	public class func defaultConfigured() throws ->ETSocket {
		
		return try ETSocket(family: .INET, type: .STREAM, proto: .TCP)
	}
	
	///
	/// Create a configured ETSocket instance.
	///
	/// - Parameter family:	The family of the socket to create.
	///	- Parameter	type:	The type of socket to create.
	///	- Parameter proto:	The protocool to use for the socket.
	///
	/// - Returns: New ETSocket instance
	///
	public class func customConfigured(family: SocketProtocolFamily, type: SocketType, proto: SocketProtocol) throws ->ETSocket {
		
		return try ETSocket(family: family, type: type, proto: proto)
	}
	
	///
	/// Extract the dotted IP address from an in_addr struct.
	///
	/// - Parameter fromAddress: The in_addr struct.
	///
	/// - Returns: Optional String containing the dotted IP address or nil if not available.
	///
	public class func dottedIP(fromAddress: in_addr) ->String? {
		
		let cString = inet_ntoa(fromAddress)
		return String.fromCString(cString)
	}
	
	// MARK: Lifecycle Methods

	// MARK: -- Public
	
	///
	/// Internal initializer to create a configured ETSocket instance.
	///
	/// - Parameter family:	The family of the socket to create.
	///	- Parameter	type:	The type of socket to create.
	///	- Parameter proto:	The protocool to use for the socket.
	///
	/// - Returns: New ETSocket instance
	///
	private init(family: SocketProtocolFamily, type: SocketType, proto: SocketProtocol) throws {

		// Initialize the read buffer...
		self.readBuffer.initialize(0)
		
		// Create the socket...
		self.socketfd = socket(family.valueOf(), type.valueOf(), proto.valueOf())
		
		// If error, return error...
		if self.socketfd < 0 {
			
			self.socketfd = Int32(ETSocket.SOCKET_INVALID_DESCRIPTOR)
			throw ETSocketError(code: ETSocket.SOCKET_ERR_UNABLE_TO_CREATE_SOCKET, reason: self.lastError())
		}
	}
	
	// MARK: -- Private
	
	///
	/// Private constructor to create an instance for existing open socket fd.
	///
	/// - Parameter fd: Open file descriptor.
	///	- Parameter remoteAddress: The sockaddr_in associated with the open fd.
	///
	/// - Returns: New ETSocket instance
	///
	private init(fd: Int32, remoteAddress: sockaddr_in) throws {
		
		self.connected = true
		self.listening = false
		self.readBuffer.initialize(0)
		if let hostname = ETSocket.dottedIP(remoteAddress.sin_addr) {
			self.remoteHostName = hostname
		}
		self.remotePort = Int(remoteAddress.sin_port)
		self.socketfd = fd
	}
	
	deinit {
		
		if self.socketfd > 0 {
			
			self.close()
		}
		
		// Destroy and free the readBuffer...
		self.readBuffer.destroy(0)
		self.readBuffer.dealloc(self.readBufferSize)
	}
	
	// MARK: Public Methods
	
	///
	/// Accepts an incoming connection request on the current instance, leaving the current instance still listening.
	///
	/// - returns: New ETSocket instance representing the newly accepted socket.
	///
	public func acceptConnectionAndKeepListening() throws ->ETSocket {
		
		// The socket must've been created, not connected and listening...
		if self.socketfd == Int32(ETSocket.SOCKET_INVALID_DESCRIPTOR) {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		if self.connected {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_ALREADY_CONNECTED, reason: nil)
		}
		
		if !self.listening {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_NOT_LISTENING, reason: nil)
		}
		
		// Accept the remote connection...
		var acceptAddr = sockaddr_in()
		var addrSize: socklen_t = socklen_t(sizeof(sockaddr_in))
		let socketfd2 = withUnsafeMutablePointer(&acceptAddr) {
			accept(self.socketfd, UnsafeMutablePointer($0), &addrSize)
		}
		if socketfd2 < 0 {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_ACCEPT_FAILED, reason: self.lastError())
		}
		
		// Create and return the new socket...
		//	Note: The current socket continues to listen.
		return try ETSocket(fd: socketfd2, remoteAddress: acceptAddr)
	}
	
	///
	/// Accepts an incoming connection request replacing the existing socket with the newly accepted one.
	///
	public func acceptConnection() throws {
		
		// The socket must've been created, not connected and listening...
		if self.socketfd == Int32(ETSocket.SOCKET_INVALID_DESCRIPTOR) {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		if self.connected {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_ALREADY_CONNECTED, reason: nil)
		}

		if !self.listening {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_NOT_LISTENING, reason: nil)
		}
		
		// Accept the remote connection...
		var acceptAddr = sockaddr_in()
		var addrSize: socklen_t = socklen_t(sizeof(sockaddr_in))
		let socketfd2 = withUnsafeMutablePointer(&acceptAddr) {
			accept(self.socketfd, UnsafeMutablePointer($0), &addrSize)
		}
		
		if socketfd2 < 0 {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_ACCEPT_FAILED, reason: self.lastError())
		}
		
		// Close the old socket...
		self.close()
		
		// Replace the existing socketfd with the new one...
		self.socketfd = socketfd2
		self.remotePort = Int(acceptAddr.sin_port)
		if let hostname = ETSocket.dottedIP(acceptAddr.sin_addr) {
			self.remoteHostName = hostname
		}
		
		// We're connected...
		self.connected = true
		self.listening = false
	}
	
	///
	/// Closes the current socket.
	///
	public func close() {
		
		if self.socketfd != Int32(ETSocket.SOCKET_INVALID_DESCRIPTOR) {
			#if os(Linux)
				Glibc.close(self.socketfd)
			#else
				Darwin.close(self.socketfd)
			#endif
			self.socketfd = Int32(ETSocket.SOCKET_INVALID_DESCRIPTOR)
		}
		
		self.remoteHostName = ETSocket.NO_HOSTNAME
		self.connected = false
		self.listening = false
	}
	
	///
	/// Connects to the named host on the specified port.
	///
	/// - Parameter host:	The host name to connect to.
	///	- Parameter port:	The port to be used.
	///
	public func connectTo(host: String, port: Int32) throws {
		
		// The socket must've been created and must not be connected...
		if self.socketfd == Int32(ETSocket.SOCKET_INVALID_DESCRIPTOR) {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		if self.connected {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_ALREADY_CONNECTED, reason: nil)
		}
		
		if host.utf8.count == 0 {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_INVALID_HOSTNAME, reason: nil)
		}
		
		// Look up the host...
		self.remoteHostName = host
		let remoteHost: UnsafeMutablePointer<hostent> = gethostbyname(self.remoteHostName)
		if remoteHost == nil {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_GETHOSTBYNAME_FAILED, reason: self.lastError())
		}
		
		// Copy the info into the socket address structure...
		var remoteAddr = sockaddr_in()
		remoteAddr.sin_family = sa_family_t(AF_INET)
		bcopy(remoteHost.memory.h_addr_list[0], &remoteAddr.sin_addr.s_addr, Int(remoteHost.memory.h_length))
		remoteAddr.sin_port = UInt16(port).bigEndian
		
		// Now, do the connection...
		let rc = withUnsafeMutablePointer(&remoteAddr) {
			connect(self.socketfd, UnsafeMutablePointer($0), socklen_t(sizeof(sockaddr_in)))
		}
		if rc < 0 {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_CONNECT_FAILED, reason: self.lastError())
		}
		
		self.remoteHostName = host
		self.remotePort = Int(port)
		self.connected = true
	}
	
	///
	/// Determines if this socket can be read from or written to.
	///
	/// - Returns: Tuple containing two boolean values, one for readable and one for writable.
	///
	public func isReadableOrWritable() throws ->(readable: Bool, writable: Bool) {
		
		// The socket must've been created and must be connected...
		if self.socketfd == Int32(ETSocket.SOCKET_INVALID_DESCRIPTOR) {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		if !self.connected {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_NOT_CONNECTED, reason: nil)
		}
		
		// Create a read and write file descriptor set for this socket...
		var readfds = fd_set()
		fdZero(&readfds)
		fdSet(self.socketfd, set: &readfds)
		
		var writefds = fd_set()
		fdZero(&writefds)
		fdSet(self.socketfd, set: &writefds)
		
		// Create a timeout of zero (i.e. don't wait)...
		var timeout = timeval()
		
		// See if there's data on the socket...
		let count = select(self.socketfd + 1, &readfds, &writefds, nil, &timeout)
		
		// A count of less than zero indicates select failed...
		if count < 0 {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_SELECT_FAILED, reason: self.lastError())
		}
		
		// Return a tuple containing whether or not this socket is readable and/or writable...
		return (fdIsSet(self.socketfd, set: &readfds), fdIsSet(self.socketfd, set: &writefds))
	}
	
	///
	/// Listen on a port using the default for max pending connections.
	///
	/// - Parameter port: The port to listen on.
	///
	public func listenOn(port: Int) throws {
		
		return try self.listenOn(port, maxPendingConnections: self.maxPendingConnections)
	}
	
	///
	/// Listen on a port, limiting the maximum number of pending connections.
	///
	/// - Parameter port: The port to listen on.
	/// - Parameter maxPendingConnections: The maximum number of pending connections to allow.
	///
	public func listenOn(port: Int, maxPendingConnections: Int) throws {
		
		// Set a flag so that this address can be re-used immediately after the connection
		// closes.  (TCP normally imposes a delay before an address can be re-used.)
		var on: Int32 = 1
		if setsockopt(self.socketfd, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(sizeof(Int32))) < 0 {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_SETSOCKOPT_FAILED, reason: self.lastError())
		}
		
		// Bind the address to the socket....
		var localAddr = sockaddr_in()
		localAddr.sin_family = sa_family_t(AF_INET)
		localAddr.sin_addr.s_addr = ETSocket.INADDR_ANY
		localAddr.sin_port = in_port_t(UInt16(bigEndian: UInt16(port)))
		
		var bindAddr = sockaddr()
		memcpy(&bindAddr, &localAddr, Int(sizeof(sockaddr_in)))
		
		let addrSize: socklen_t = socklen_t(sizeof(sockaddr_in))
		
		if bind(self.socketfd, &bindAddr, addrSize) < 0 {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_BIND_FAILED, reason: self.lastError())
		}

		// Now listen for connections...
		if listen(self.socketfd, Int32(maxPendingConnections)) < 0 {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_LISTEN_FAILED, reason: self.lastError())
		}
		
		self.listening = true
	}
	
	///
	/// Read data from the socket.
	///
	/// - Parameter buffer: The buffer to return the data in.
	/// - Parameter bufSize: The size of the buffer.
	///
	/// - Throws: `ETSocket.SOCKET_ERR_RECV_BUFFER_TOO_SMALL` if the buffer provided is too small.
	///		Call again with proper buffer size (see `ETSocketError.bufferSizeNeeded`) or
	///		use `readData(data: NSMutableData)`.
	///
	/// - Returns: The number of bytes returned in the buffer.
	///
	public func readData(buffer: UnsafeMutablePointer<CChar>, bufSize: Int) throws ->Int {
		
		if buffer == nil || bufSize == 0 {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_INVALID_BUFFER, reason: nil)
		}

		// The socket must've been created and must be connected...
		if self.socketfd == Int32(ETSocket.SOCKET_INVALID_DESCRIPTOR) {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		if !self.connected {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_NOT_CONNECTED, reason: nil)
		}
		
		// See if we have cached data to send back...
		if self.readStorage.length > 0 {
			
			if bufSize < self.readStorage.length {
				
				throw ETSocketError(bufferSize: self.readStorage.length)
			}
			
			let returnCount = self.readStorage.length
			
			// - We've got data we've already read, copy to the callers buffer...
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
				
				throw ETSocketError(bufferSize: self.readStorage.length)
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
	/// Read data from the socket.
	///
	/// - Parameter data: The buffer to return the data in.
	///
	/// - Returns: The number of bytes returned in the buffer.
	///
	public func readData(data: NSMutableData) throws ->Int {
		
		// The socket must've been created and must be connected...
		if self.socketfd == Int32(ETSocket.SOCKET_INVALID_DESCRIPTOR) {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		if !self.connected {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_NOT_CONNECTED, reason: nil)
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
			data.appendData(self.readStorage)
			
			returnCount = self.readStorage.length

			// - Reset the storage buffer...
			self.readStorage.length = 0
		}
		
		return returnCount
	}
	
	///
	/// Write data to the socket.
	///
	/// - Parameter buffer: The buffer containing the data to write.
	/// - Parameter bufSize: The size of the buffer.
	///
	public func writeData(buffer: UnsafePointer<Void>, bufSize: Int) throws {
		
		if buffer == nil || bufSize == 0 {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_INVALID_BUFFER, reason: nil)
		}
		
		// The socket must've been created and must be connected...
		if self.socketfd == Int32(ETSocket.SOCKET_INVALID_DESCRIPTOR) {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		if !self.connected {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_NOT_CONNECTED, reason: nil)
		}

		var sent = 0
		while sent < bufSize {
			
			let s = write(self.socketfd, buffer + sent, Int(bufSize - sent))
			if s <= 0 {
				
				throw ETSocketError(code: ETSocket.SOCKET_ERR_WRITE_FAILED, reason: self.lastError())
			}
			sent += s
		}
	}
	
	///
	/// Write data to the socket.
	///
	/// - Parameter data: The NSData object containing the data to write.
	///
	public func writeData(data: NSData) throws {
		
		// The socket must've been created and must be connected...
		if self.socketfd == Int32(ETSocket.SOCKET_INVALID_DESCRIPTOR) {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_BAD_DESCRIPTOR, reason: nil)
		}
		
		if !self.connected {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_NOT_CONNECTED, reason: nil)
		}
		
		var sent = 0
		let buffer = data.bytes
		while sent < data.length {
			
			let s = write(self.socketfd, buffer + sent, Int(data.length - sent))
			if s <= 0 {
				
				throw ETSocketError(code: ETSocket.SOCKET_ERR_WRITE_FAILED, reason: self.lastError())
			}
			sent += s
		}
	}
	
	///
	/// Write a string to the socket.
	///
	/// - Parameter string: The string to write.
	///
	public func writeString(string: String) throws {
		
		try string.nulTerminatedUTF8.withUnsafeBufferPointer() {
			try self.writeData($0.baseAddress, bufSize: $0.count)
		}
	}
	
	///
	/// Set blocking mode for socket.
	///
	/// **WARNING: This function currently not implemented. Will throw an exception.**
	///
	/// - Parameter shouldBlock: True to block, false to not.
	///
	public func setBlocking(shouldBlock: Bool) throws {
		
		let flags = fcntl(self.socketfd, F_GETFL)
		if flags < 0 {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_GET_FCNTL_FAILED, reason: self.lastError())
		}
		
		var result: Int32 = 0
		if shouldBlock {
			
			result = fcntl(self.socketfd, F_SETFL, flags & ~O_NONBLOCK)
		
		} else {
			
			result = fcntl(self.socketfd, F_SETFL, flags | O_NONBLOCK)
		}
		
		if result < 0 {
			
			throw ETSocketError(code: ETSocket.SOCKET_ERR_SET_FCNTL_FAILED, reason: self.lastError())
		}
		
		self.isBlocking = shouldBlock
	}
	
	// MARK: Private Methods
	
	///
	/// Private method that reads all available data on an open socket into storage.
	///
	/// - Returns: number of bytes read.
	///
	private func readDataIntoStorage() throws ->Int {
	
		// Clear the buffer...
		if self.readBuffer != nil {
			
			self.readBuffer.destroy()
			self.readBuffer.initialize(0x0)
			memset(self.readBuffer, 0x0, self.readBufferSize)
		}
		
		var count: Int = 0
		repeat {
			
			count = recv(self.socketfd, self.readBuffer, self.readBufferSize, 0)
			
			// Check for error...
			if count < 0 {
				
				// - Could be an error, but if errno is EAGAIN or EWOULDBLOCK, it means there was NO data to read...
				if errno == EAGAIN {
					
					return 0
				}
				
				// - Something went wrong...
				throw ETSocketError(code: ETSocket.SOCKET_ERR_RECV_FAILED, reason: self.lastError())
			}
			
			if count > 0 {
				
				self.readStorage.appendBytes(self.readBuffer, length: count)
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
	private func lastError() ->String {
		
		return String.fromCString(strerror(errno)) ?? "Error: \(errno)"
	}

}

