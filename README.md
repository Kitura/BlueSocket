![](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)
![](https://img.shields.io/badge/Snapshot-8/4-blue.svg?style=flat)

# BlueSocket

## Overview
Socket framework for Swift using the Swift Package Manager. Works on macOS and Linux.

## Contents

* Socket: Generic low level socket framework. Pure Swift. 

## Prerequisites

### Swift
* Swift Open Source `swift-DEVELOPMENT-SNAPSHOT-2016-08-04-a` toolchain (**Minimum REQUIRED for latest release**)

### macOS

* macOS 10.11.6 (*El Capitan*) or higher
* Xcode Version 8.0 beta 3 (8S174q) or higher using the above toolchain (*Recommended*)

### Linux

* Ubuntu 15.10 (or 14.04 but only tested on 15.10)
* The Swift Open Source toolchain listed above

### Add-ons

* [BlueSSLService](https://github.com/IBM-Swift/BlueSSLService.git) can be used to add **SSL** support.

## Build

To build Socket from the command line:

```
% cd <path-to-clone>
% swift build
```

## Testing

To run the supplied unit tests for **Socket** from the command line:

```
% cd <path-to-clone>
% swift build
% swift test
```

## Using BlueSocket

### Before starting

The first you need to do is import the Socket framework.  This is done by the following:
```
import Socket
```

### Creating a socket.

**BlueSocket** provides four different factory methods that are used to create an instance.  These are:
- `create()` - This creates a fully configured default socket. A default socket is created with `family: .inet`, `type: .stream`, and `proto: .tcp`.
- `create(family family: ProtocolFamily, type: SocketType, proto: SocketProtocol)` - This API allows you to create a configured `Socket` instance customized for your needs.  You can customize the protocol family, socket type and socket protocol.
- `create(connectedUsing signature: Signature)` - This API will allow you create a `Socket` instance and have it attempt to connect to a server based on the information you pass in the `Socket.Signature`.
- `create(fromNativeHandle nativeHandle: Int32, address: Address?)` - This API lets you wrap a native file descriptor describing an existing socket in a new instance of `Socket`.

### Closing a socket.

To close the socket of an open instance, the following function is provided:
- `close()` - This function will perform the necessary tasks in order to cleanly close an open socket.

### Listen on a socket.

To use **BlueSocket** to listen for an connection on a socket the following API is provided:
- `listen(on port: Int, maxBacklogSize: Int = Socket.SOCKET_DEFAULT_MAX_BACKLOG)`
The first parameter `port`, is the port to be used to listen on. The second parameter, `maxBacklogSize` allows you to set the size of the queue holding pending connections. The function will determine the appropriate socket configuration based on the `port` specified.  For convenience on macOS, the constant `Socket.SOCKET_MAX_DARWIN_BACKLOG` can be set to use the maximum allowed backlog size.  The default value for all platforms is `Socket.SOCKET_DEFAULT_MAX_BACKLOG`, currently set to *50*. For server use, it may be necessary to increase this value.

#### Example:

The following example creates a default `Socket` instance and then *immediately* starts listening on port `1337`.  *Note: Exception handling omitted for brevity, see the complete example below for an example of exception handling.*
```swift
var socket = try Socket.create()
guard let socket = socket else {
  fatalError("Could not create socket.")
}
try socket.listen(on: 1337)
```

### Accepting a connection from a listening socket.

When a listening socket detects an incoming connection request, control is returned to your program.  You can then either accept the connection or continue listening or both if your application is multi-threaded. **BlueSocket** supports two distinct ways of accepting an incoming connection. They are:
- `acceptClientConnection()` - This function accepts the connection and returns a *new* `Socket` instance based on the newly connected socket. The instance that was listening in unaffected.
- `acceptConnection()` - This function accepts the incoming connection, *replacing and closing* the existing listening socket. The properties that were formerly associated with the listening socket are replaced by the properties that are relevant to the newly connected socket.

### Connecting a socket to a server.

In addition to the `create(connectedUsing:)` factory method described above, **BlueSocket** supports two additional functions for connecting a `Socket` instance to a server. They are:
- `connect(to host: String, port: Int32)` - This API allows you to connect to a server based on the `hostname` and `port` you provide.
- `connect(using signature: Signature)` - This API allows you specify the connection information by providing a `Socket.Signature` instance containing the information.  Refer to `Socket.Signature` in *Socket.swift* for more information.

### Reading data from a socket.

**BlueSocket** supports four different ways to read data from a socket. These are (in recommended use order):
- `read(into data: inout Data)` - This function reads all the data available on a socket and returns it in the `Data` object that was passed.
- `read(into data: NSMutableData)` - This function reads all the data available on a socket and returns it in the `NSMutableData` object that was passed.
- `readString()` - This function reads all the data available on a socket and returns it as an `String`. A `nil` is returned if no data is available for reading.
- `read(into buffer: UnsafeMutablePointer<CChar>, bufSize: Int)` - This function allows you to read data into a buffer of a specified size by providing an *unsafe* pointer to that buffer and an integer the denotes the size of that buffer.  This API (in addition to other types of exceptions) will throw a `Socket.SOCKET_ERR_RECV_BUFFER_TOO_SMALL` if the buffer provided is too small. You will need to call again with proper buffer size (see `Error.bufferSizeNeeded`in *Socket.swift* for more information).

### Writing data to a Socket.

In addition to reading from a socket, **BlueSocket** also supplies four methods for writing data to a socket. These are (in recommended use order):
- `write(from data: Data)` - This function writes the data contained within the `Data` object to the socket.
- `write(from data: NSData)` - This function writes the data contained within the `NSData` object to the socket.
- `write(from string: String)` - This function writes the data contained in the `String` provided to the socket.
- `write(from buffer: UnsafePointer<Void>, bufSize: Int)` - This function writes the data contained within the buffer of the specified size by providing an *unsafe* pointer to that buffer and an integer the denotes the size of that buffer.

### Miscellaneous Utility Functions

- `hostnameAndPort(from address: Address)` - This *class function* provides a means to extract the hostname and port from a given `Socket.Address`. On successful completion, a tuple containing the `hostname` and `port` are returned.
- `checkStatus(for sockets: [Socket])` - This *class function* allows you to check status of an array of `Socket` instances. Upon completion, a tuple containing two `Socket` arrays is returned. The first array contains the `Socket` instances are that have data available to be read and the second array contains `Socket` instances that can be written to. This API does *not* block. It will check the status of each `Socket` instance and then return the results.
- `wait(for sockets: [Socket], timeout: UInt, waitForever: Bool = false)` - This *class function* allows for monitoring an array of `Socket` instances, waiting for either a timeout to occur or data to be readable at one of the monitored `Socket` instances. If a timeout of zero (0) is specified, this API will check each socket and return immediately. Otherwise, it will wait until either the timeout expires or data is readable from one or more of the monitored `Socket` instances. If a timeout occurs, this API will return `nil`.  If data is available on one or more of the monitored `Socket` instances, those instances will be returned in an array. If the `waitForever` flag is set to true, the function will wait indefinitely for data to become available *regardless of the timeout value specified*.
- `isReadableOrWritable()` - This *instance function* allows to determine whether a `Socket` instance is readable and/or writable.  A tuple is returned containing two `Bool` values.  The first, if true, indicates the `Socket` instance has data to read, the second, if true, indicates that the `Socket` instance can be written to.
- `setBlocking(shouldBlock: Bool)` - This *instance function* allows you control whether or not this `Socket` instance should be placed in blocking mode or not. **Note:** All `Socket` instances are, by *default*, created in *blocking mode*.

### Complete Example

The following example shows how to create a simple echo server.
```swift
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
	import Darwin
	import Foundation
	import Socket
#elseif os(Linux)
	import Glibc
	import Foundation
	import Socket
#endif

class EchoServer {
	
	static let QUIT: String = "QUIT"
	
	let port: Int
	
	var keepRunning: Bool = true
	var listenSocket: Socket? = nil

	init(port: Int) {
		
		self.port = port
	}
	
	deinit {
		
		self.listenSocket?.close()
	}
	
	func run() {
		
		do {
			
			try self.listenSocket = Socket.create()
			
			guard let socket = self.listenSocket else {
				
				print("Unable to unwrap socket...")
				return
			}
			
			try socket.listen(on: self.port, maxBacklogSize: 10)
			
			print("Listening on port: \(self.port)")
			
			// Replace the listening socket with the newly accepted connection...
			try socket.acceptConnection()
			
			print("Accepted connection from: \(socket.remoteHostname) on port \(socket.remotePort)")
			
			try socket.write(from: "Hello, type 'QUIT' to end session\n")
			
			var bytesRead = 0
			repeat {
				
				let readData = NSMutableData()
				bytesRead = try socket.read(into: readData)
				
				if bytesRead > 0 {
					
					guard let response = String(data: readData as Data, encoding: String.Encoding.utf8) else {
						
						print("Error decoding response...")
						readData.length = 0
						break
					}
					
					// If the user typed `QUIT`, we'll shutdown the server...
					if response.hasPrefix(EchoServer.QUIT) {
						
						self.keepRunning = false
					}
					
					print("Server received from connection at \(socket.remoteHostname):\(socket.remotePort): \(response) ")
					
					// Echo back to the client what we receivied...
					let reply = "Server response: \n\(response)\n"
					try socket.write(from: reply)
					
				}
				
				// No bytes read, the other side closed the connection...
				if bytesRead == 0 {
					
					break
				}
				
			} while self.keepRunning
			
			socket.close()
		
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

let port = 1337
let server = EchoServer(port: port)
print("Connect using Terminal via 'telnet 127.0.0.1 \(port)'")
server.run()
```
