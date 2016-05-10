# BlueSocket

## Overview
Socket framework for Swift using the Swift Package Manager. Works on OS X and Linux.

## Contents

* Socket: Generic low level socket framework. Pure Swift. 

## Prerequisites

### Swift
* Swift Open Source `swift-DEVELOPMENT-SNAPSHOT-2016-04-25-a` toolchain (**Minimum REQUIRED for latest release**)
* Swift Open Source `swift-DEVELOPMENT-SNAPSHOT-2016-05-03-a` toolchain (**Recommended**)

### OS X

* OS X 10.11.0 (*El Capitan*) or higher
* Xcode Version 7.3.1 (7D1012) or higher using the one of the above toolchains (*Recommended*)

### Linux

* Ubuntu 15.10 (or 14.04 but only tested on 15.10)
* One of the Swift Open Source toolchains listed above

## Build

To build Socket from the command line:

```
% cd <path-to-clone>
% swift build
```
## Using BlueSocket

### Before starting

The first you need to do is import the Socket framework.  This is done by the following:
```
import Socket
```

### Creating a socket.

BlueSocket provides four different factory methods that are used to create an instance.  These are:
- `create()` - This creates a fully configured default socket. A Default socket created with `family: .inet`, `type: .stream`, and `proto: .tcp`.
- `create(family family: ProtocolFamily, type: SocketType, proto: SocketProtocol)` - This API allows you to create a configured socket customized for your needs.  You can customize the protocol family, socket type and socket protocol.
- `create(connectedUsing signature: Signature)` - This API will allow you create a socket and have it attempt to connect to a server based on the information you pass in the `Socket.Signature`.
- `create(fromNativeHandle nativeHandle: Int32, address: Address?)` - This API lets you wrap a native file descriptor in a new instance of Socket.

### Closing a socket.

To close the socket of an open instance, the following function is provided:
- `close()` - This function will perform the necessary tasks in order to cleanly close an open socket.

### Listen on a socket.

BlueSocket supports two ways to listen for an connection on a socket. These are:
- `listen(on port: Int)`
- `listen(on port: Int, maxPendingConnections: Int)`
The second way allow you to limit the maximum number of incoming connection. In both cases, the function will determine the appropriate socket configuration based on the `port` specified.

#### Example:

The following example creates a default socket and then starts listening on port `1337`.  *Note: Exception handling omitted for brevity, see the complete example below for an example of exception handling.*
```swift
var socket = try Socket.create()
guard let socket = socket else {
  fatalError("Could not create socket.")
}
try socket.listen(on: 1337)
```

### Accepting a connection from a listening socket.

When a listening socket detects an incoming connection request, control is returned to your program.  You can then either accept the connection or continue listening or both if your application is multi-threaded. BlueSocket supports two distinct ways of accepting an incoming connection. They are:
- `acceptClientConnection()` - This function accepts the connection and returns a *new* Socket instance based on the newly connected socket. The instance that was listening in unaffected.
- `acceptConnection()` - This function accepts the incoming connection, *replacing and closing* the existing listening socket. The properties that were formerly associated with the listening socket are replaced by the properties that are relevant to the newly connected socket.

### Connecting a socket to a server.

In addition to the `create(connectedUsing:)` factory method described above, BlueSocket supports two additional functions for connecting a Socket instance to a server. They are:
- `connect(to host: String, port: Int32)` - This API allows you to connect to a server based on the `hostname` and `port` you provide.
- `connect(using signature: Signature)` - This API allows you specify the connection information by providing a `Socket.Signature` instance containing the information.  Refer to `Socket.Signature` in *Socket.swift* for more information.

### Reading data from a Socket.

BlueSocket supports three different ways to read data from a socket. These are:
- `read(into data: NSMutableData)` - This function reads all the data available on a socket and returns it in the `NSMutableData` object that was passed.
- `readString()` - This function reads all the data available on a socket and returns it as an `String?`.
- `read(into buffer: UnsafeMutablePointer<CChar>, bufSize: Int)` - This function allows you to read data into a buffer of a specified size by providing an *unsafe* pointer to that buffer and an integer the denotes the size of that buffer.  This API (in addition to other types of exceptions) will throw a `Socket.SOCKET_ERR_RECV_BUFFER_TOO_SMALL` if the buffer provided is too small. You will need to call again with proper buffer size (see `Error.bufferSizeNeeded`).

### Writing data to a Socket.

In addition to reading from a socket, BlueSocket also supplies three methods for writing data to a socket. These are:
- `write(from data: NSData)` - This function writes the data contained within the `NSData` object to the socket.
- `write(from string: String)` - This function writes the data contained in the `String` provided to the socket.
- `write(from buffer: UnsafePointer<Void>, bufSize: Int)` - This function writes the data contained within the buffer of the specified size by providing an *unsafe* pointer to that buffer and an integer the denotes the size of that buffer.

### Miscellaneous Utility Functions

- `hostnameAndPort(from address: Address)` - This class function provides a means to extract the hostname and port from a given `Socket.Address`. On successful completion, a tuple containing the hostname and port are returned.
- `checkStatus(for sockets: [Socket])` - This class function allows you check status of an array of Socket instances. Upon completion, a tuple containing two Socket arrays is returned. The first array contains the Socket instances are that have data available to be read and the second array contains Socket instances that can be written to.
- `isReadableOrWritable()` - This instance function allows to determine whether a Socket instance is readable and/or writable.  A tuple is returned containing two `Bool` values.  The first, if true, indicates the Socket instance has data to read, the second, if true, indicates that the Socket instance can be written to.
- `setBlocking(shouldBlock: Bool)` - This instance function allows you control whether or not this Socket instance should be in blocking mode or not.

### Complete Example

The following example shows how to create a simple echo server.
```swift
#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
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
			
			try socket.listen(on: self.port, maxPendingConnections: 10)
			
			print("Listening on port: \(self.port)")
			
			try socket.acceptConnection()
			
			print("Accepted connection from: \(socket.remoteHostname) on port \(socket.remotePort)")
			
			try self.listenSocket?.write(from: "Hello, type 'QUIT' to end session\n")
			
			var bytesRead = 0
			repeat {
				
				let readData = NSMutableData()
				bytesRead = try socket.read(into: readData)
				
				if bytesRead > 0 {
					
					guard let response = NSString(data: readData, encoding: NSUTF8StringEncoding) else {
						
						print("Error decoding response...")
						readData.length = 0
						break
					}
					
					if response.hasPrefix(EchoServer.QUIT) {
						
						self.keepRunning = false
					}
					
					print("Server received from connection at \(socket.remoteHostname):\(socket.remotePort): \(response) ")
					let reply = "Server response: \n\(response)\n"
					try socket.write(from: reply)
					
				}
				
				if bytesRead == 0 {
					
					break
				}
				
			} while self.keepRunning
			
			socket.close()
		
		} catch let error as Socket.Error {
			
			print("Error reported:\n \(error.description)")
		
		} catch {
			
			print("Unexpected error...")
		}
	}
}

let port = 1337
let server = EchoServer(port:port)
print("Connect using Terminal via 'telnet 127.0.0.1 \(port)'")
server.run()
```
