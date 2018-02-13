![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![iOS](https://img.shields.io/badge/os-iOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
![Apache 2](https://img.shields.io/badge/license-Apache2-blue.svg?style=flat)
![](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)
![](https://img.shields.io/badge/Swift-4.0-orange.svg?style=flat)
[![Build Status - Master](https://travis-ci.org/IBM-Swift/BlueSocket.svg?branch=master)](https://travis-ci.org/IBM-Swift/BlueSocket)

# BlueSocket

## Overview
Socket framework for Swift using the Swift Package Manager. Works on iOS, macOS, and Linux.

## Contents

* Socket: Generic low level socket framework. Pure Swift.

## Prerequisites

### Swift

* Swift Open Source `swift-3.0.1-RELEASE` toolchain (**Minimum REQUIRED for latest release**)
* Swift Open Source `swift-4.0.0-RELEASE` toolchain (**Recommended**)
* Swift toolchain included in *Xcode Version 9.0 (9A325) or higher*.

### macOS

* macOS 10.11.6 (*El Capitan*) or higher
* Xcode Version 8.3.2 (8E2002) or higher using one of the above toolchains (*Recommended*)
* Xcode Version 9.0  (9A325) or higher using the included toolchain.

### iOS

* iOS 10.0 or higher
* Xcode Version 8.3.2 (8E2002) or higher using one of the above toolchains (*Recommended*)
* Xcode Version 9.0  (9A325) or higher using the included toolchain.

### Linux

* Ubuntu 16.04 (or 16.10 but only tested on 16.04)
* One of the Swift Open Source toolchain listed above

### Other Platforms

* **BlueSocket** is **NOT** supported on *watchOS* since POSIX/BSD/Darwin sockets are not supported on the actual device although they are supported in the simulator.
* **BlueSocket** should work on *tvOS* but has **NOT** been tested.

### Add-ins

* [BlueSSLService](https://github.com/IBM-Swift/BlueSSLService.git) can be used to add **SSL/TLS** support.

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

### Including in your project

#### Swift Package Manager

To include BlueSocket into a Swift Package Manager package, add it to the `dependencies` attribute defined in your `Package.swift` file. You can select the version using the `majorVersion` and `minor` parameters. For example:
```
	dependencies: [
		.Package(url: "https://github.com/IBM-Swift/BlueSocket.git", majorVersion: <majorVersion>, minor: <minor>)
	]
```

#### Carthage
To include BlueSocket in a project using Carthage, add a line to your `Cartfile` with the GitHub organization and project names and version. For example:
```
	github "IBM-Swift/BlueSocket" ~> <majorVersion>.<minor>
```

#### CocoaPods
To include BlueSocket in a project using CocoaPods, you just add `BlueSocket` to your `Podfile`, for example:
```
    platform :ios, '10.0'

    target 'MyApp' do
        use_frameworks!
        pod 'BlueSocket'
    end
```

### Before starting

The first thing you need to do is import the Socket framework.  This is done by the following:
```
import Socket
```

### Family, Type and Protocol Support

**BlueSocket** supports the following families, types and protocols:
- *Families:*
	- IPV4: `Socket.ProtocolFamily.inet`
	- IPV6: `Socket.ProtocolFamily.inet6`
	- UNIX: `Socket.ProtocolFamily.unix`
- *Types:*
	- Stream: `Socket.SocketType.stream`
	- Datagram: `Socket.SocketType.datagram`
- *Protocols:*
	- TCP: `Socket.SocketProtocol.tcp`
	- UDP: `Socket.SocketProtocol.udp`
	- UNIX: `Socket.SocketProtocol.unix`

### Creating a socket.

**BlueSocket** provides four different factory methods that are used to create an instance.  These are:
- `create()` - This creates a fully configured default socket. A default socket is created with `family: .inet`, `type: .stream`, and `proto: .tcp`.
- `create(family family: ProtocolFamily, type: SocketType, proto: SocketProtocol)` - This API allows you to create a configured `Socket` instance customized for your needs.  You can customize the protocol family, socket type and socket protocol.
- `create(connectedUsing signature: Signature)` - This API will allow you create a `Socket` instance and have it attempt to connect to a server based on the information you pass in the `Socket.Signature`.
- `create(fromNativeHandle nativeHandle: Int32, address: Address?)` - This API lets you wrap a native file descriptor describing an existing socket in a new instance of `Socket`.

#### Setting the read buffer size.

**BlueSocket** allows you to set the size of the read buffer that it will use. Then, depending on the needs of the application, you can change it to a higher or lower value. The default is set to `Socket.SOCKET_DEFAULT_READ_BUFFER_SIZE` which has a value of `4096`. The minimum read buffer size is `Socket.SOCKET_MINIMUM_READ_BUFFER_SIZE` which is set to `1024`. Below illustrates how to change the read buffer size (exception handling omitted for brevity):
```
let mySocket = try Socket.create()
mySocket.readBufferSize = 32768
```
The example above sets the default read buffer size to *32768*.  This setting should be done *prior* to using the `Socket` instance for the first time.

### Closing a socket.

To close the socket of an open instance, the following function is provided:
- `close()` - This function will perform the necessary tasks in order to cleanly close an open socket.

### Listen on a socket (TCP/UNIX).

To use **BlueSocket** to listen for an connection on a socket the following API is provided:
- `listen(on port: Int, maxBacklogSize: Int = Socket.SOCKET_DEFAULT_MAX_BACKLOG, allowPortReuse: Bool = true)`
The first parameter `port`, is the port to be used to listen on. The second parameter, `maxBacklogSize` allows you to set the size of the queue holding pending connections. The function will determine the appropriate socket configuration based on the `port` specified.  For convenience on macOS, the constant `Socket.SOCKET_MAX_DARWIN_BACKLOG` can be set to use the maximum allowed backlog size.  The default value for all platforms is `Socket.SOCKET_DEFAULT_MAX_BACKLOG`, currently set to *50*. For server use, it may be necessary to increase this value.  To allow the reuse of the listening port, set `allowPortReuse` to `true`.  If set to `false`, a error will occur if you attempt to listen on a port already in use.  The `DEFAULT` behavior is to `allow` port reuse.
- `listen(on path: String, maxBacklogSize: Int = Socket.SOCKET_DEFAULT_MAX_BACKLOG)`
This API can only be used with the `.unix` protocol family. The first parameter `path`, is the path to be used to listen on. The second parameter, `maxBacklogSize` allows you to set the size of the queue holding pending connections. The function will determine the appropriate socket configuration based on the `port` specified.  For convenience on macOS, the constant `Socket.SOCKET_MAX_DARWIN_BACKLOG` can be set to use the maximum allowed backlog size.  The default value for all platforms is `Socket.SOCKET_DEFAULT_MAX_BACKLOG`, currently set to *50*. For server use, it may be necessary to increase this value.

#### Example:

The following example creates a default `Socket` instance and then *immediately* starts listening on port `1337`.  *Note: Exception handling omitted for brevity, see the complete example below for an example of exception handling.*
```swift
var socket = try Socket.create()
try socket.listen(on: 1337)
```

### Accepting a connection from a listening socket (TCP/UNIX).

When a listening socket detects an incoming connection request, control is returned to your program.  You can then either accept the connection or continue listening or both if your application is multi-threaded. **BlueSocket** supports two distinct ways of accepting an incoming connection. They are:
- `acceptClientConnection(invokeDelegate: Bool = true)` - This function accepts the connection and returns a *new* `Socket` instance based on the newly connected socket. The instance that was listening in unaffected.  If `invokeDelegate` is `false` and the `Socket` has an `SSLService` delegate attached, you **MUST** call the `invokeDelegateOnAccept` method using the `Socket` instance that is returned by this function.
- `invokeDelegateOnAccept(for newSocket: Socket)` - If the `Socket` instance has a `SSLService` delegate, this will invoke the delegates accept function to perform SSL negotiation.  It should be called with the `Socket` instance returned by `acceptClientConnection`.  This function will throw an exception if called with the wrong `Socket` instance, called multiple times, or if the `Socket` instance does **NOT** have a `SSLService` delegate.
- `acceptConnection()` - This function accepts the incoming connection, *replacing and closing* the existing listening socket. The properties that were formerly associated with the listening socket are replaced by the properties that are relevant to the newly connected socket.

### Connecting a socket to a server (TCP/UNIX).

In addition to the `create(connectedUsing:)` factory method described above, **BlueSocket** supports three additional instance functions for connecting a `Socket` instance to a server. They are:
- `connect(to host: String, port: Int32, timeout: UInt = 0)` - This API allows you to connect to a server based on the `hostname` and `port` you provide. Note: an `exception` will be thrown by this function if the value of `port` is not in the range `1-65535`.  Optionally, you can set `timeout` to the number of milliseconds to wait for the connect. Note: If the socket is in blocking mode it will be changed to non-blocking mode *temporarily* if a `timeout` greater than zero (0) is provided. The returned socket will be *set back to its original setting (blocking or non-blocking)*.  If the socket is set to *non-blocking* and **no timeout value is provided**, an exception will be thrown.  Alternatively, you can set the socket to *non-blocking* after successfully connecting.
- `connect(to path: String)` - This API can only be used with the `.unix` protocol family. It allows you to connect to a server based on the `path` you provide.
- `connect(using signature: Signature)` - This API allows you specify the connection information by providing a `Socket.Signature` instance containing the information.  Refer to `Socket.Signature` in *Socket.swift* for more information.

### Reading data from a socket (TCP/UNIX).

**BlueSocket** supports four different ways to read data from a socket. These are (in recommended use order):
- `read(into data: inout Data)` - This function reads all the data available on a socket and returns it in the `Data` object that was passed.
- `read(into data: NSMutableData)` - This function reads all the data available on a socket and returns it in the `NSMutableData` object that was passed.
- `readString()` - This function reads all the data available on a socket and returns it as an `String`. A `nil` is returned if no data is available for reading.
- `read(into buffer: UnsafeMutablePointer<CChar>, bufSize: Int, truncate: Bool = false)` - This function allows you to read data into a buffer of a specified size by providing an *unsafe* pointer to that buffer and an integer the denotes the size of that buffer.  This API (in addition to other types of exceptions) will throw a `Socket.SOCKET_ERR_RECV_BUFFER_TOO_SMALL` if the buffer provided is too small, unless `truncate = true` in which case the socket will act as if only `bufSize` bytes were read (unretrieved bytes will be returned in the next call). If `truncate = false`, you will need to call again with proper buffer size (see `Error.bufferSizeNeeded`in *Socket.swift* for more information).
- **Note:** All of the read APIs above except `readString()` can return zero (0). This can indicate that the remote connection was closed or it could indicate that the socket would block (assuming you've turned off blocking).  To differentiate between the two, the property `remoteConnectionClosed` can be checked. If `true`, the socket remote partner has closed the connection and this `Socket` instance should be closed.

### Writing data to a Socket (TCP/UNIX).

In addition to reading from a socket, **BlueSocket** also supplies four methods for writing data to a socket. These are (in recommended use order):
- `write(from data: Data)` - This function writes the data contained within the `Data` object to the socket.
- `write(from data: NSData)` - This function writes the data contained within the `NSData` object to the socket.
- `write(from string: String)` - This function writes the data contained in the `String` provided to the socket.
- `write(from buffer: UnsafeRawPointer, bufSize: Int)` - This function writes the data contained within the buffer of the specified size by providing an *unsafe* pointer to that buffer and an integer that denotes the size of that buffer.

### Listening for a datagram message (UDP).

**BlueSocket** supports three different ways to listen for incoming datagrams. These are (in recommended use order):
- `listen(forMessage data: inout Data, on port: Int, maxBacklogSize: Int = Socket.SOCKET_DEFAULT_MAX_BACKLOG)` - This function listens for an incoming datagram, reads it and returns it in the passed `Data` object.  It returns a tuple containing the number of bytes read and the `Address` of where the data originated.
- `listen(forMessage data: NSMutableData, on port: Int, maxBacklogSize: Int = Socket.SOCKET_DEFAULT_MAX_BACKLOG)` - This function listens for an incoming datagram, reads it and returns it in the passed `NSMutableData` object.  It returns a tuple containing the number of bytes read and the `Address` of where the data originated.
- `listen(forMessage buffer: UnsafeMutablePointer<CChar>, bufSize: Int, on port: Int, maxBacklogSize: Int = Socket.SOCKET_DEFAULT_MAX_BACKLOG)` - This function listens for an incoming datagram, reads it and returns it in the passed `Data` object.  It returns a tuple containing the number of bytes read and the `Address` of where the data originated.
- **Note 1:** These functions will determine the appropriate socket configuration based on the `port` specified. Setting the value of `port` to zero (0) will cause the function to determine a suitable free port.
- **Note 2:** The parameter, `maxBacklogSize` allows you to set the size of the queue holding pending connections. The function will determine the appropriate socket configuration based on the `port` specified.  For convenience on macOS, the constant `Socket.SOCKET_MAX_DARWIN_BACKLOG` can be set to use the maximum allowed backlog size.  The default value for all platforms is `Socket.SOCKET_DEFAULT_MAX_BACKLOG`, currently set to *50*. For server use, it may be necessary to increase this value.

### Reading a datagram (UDP).

**BlueSocket** supports three different ways to read incoming datagrams. These are (in recommended use order):
- `readDatagram(into data: inout Data)` - This function reads an incoming datagram and returns it in the passed `Data` object.  It returns a tuple containing the number of bytes read and the `Address` of where the data originated.
- `readDatagram(into data: NSMutableData)` - This function reads an incoming datagram and returns it in the passed `NSMutableData` object.  It returns a tuple containing the number of bytes read and the `Address` of where the data originated.
- `readDatagram(into buffer: UnsafeMutablePointer<CChar>, bufSize: Int)` - This function reads an incoming datagram and returns it in the passed `Data` object.  It returns a tuple containing the number of bytes read and the `Address` of where the data originated. If the amount of data read is more than `bufSize` only `bufSize` will be returned.  The remainder of the data read will be discarded.

### Writing a datagram (UDP).

**BlueSocket** also supplies four methods for writing datagrams to a socket. These are (in recommended use order):
- `write(from data: Data, to address: Address)` - This function writes the datagram contained within the `Data` object to the socket.
- `write(from data: NSData, to address: Address)` - This function writes the datagram contained within the `NSData` object to the socket.
- `write(from string: String, to address: Address)` - This function writes the datagram contained in the `String` provided to the socket.
- `write(from buffer: UnsafeRawPointer, bufSize: Int, to address: Address)` - This function writes the data contained within the buffer of the specified size by providing an *unsafe* pointer to that buffer and an integer that denotes the size of that buffer.
- **Note:** In all four of the APIs above, the `address` parameter represents the address for the destination you are sending the datagram to.

### IMPORTANT NOTE about NSData and NSMutableData

The read and write APIs above that use either `NSData` or `NSMutableData` will *probably* be **deprecated** in the not so distant future.

### Miscellaneous Utility Functions

- `hostnameAndPort(from address: Address)` - This *class function* provides a means to extract the hostname and port from a given `Socket.Address`. On successful completion, a tuple containing the `hostname` and `port` are returned.
- `checkStatus(for sockets: [Socket])` - This *class function* allows you to check status of an array of `Socket` instances. Upon completion, a tuple containing two `Socket` arrays is returned. The first array contains the `Socket` instances are that have data available to be read and the second array contains `Socket` instances that can be written to. This API does *not* block. It will check the status of each `Socket` instance and then return the results.
- `wait(for sockets: [Socket], timeout: UInt, waitForever: Bool = false)` - This *class function* allows for monitoring an array of `Socket` instances, waiting for either a timeout to occur or data to be readable at one of the monitored `Socket` instances. If a timeout of zero (0) is specified, this API will check each socket and return immediately. Otherwise, it will wait until either the timeout expires or data is readable from one or more of the monitored `Socket` instances. If a timeout occurs, this API will return `nil`.  If data is available on one or more of the monitored `Socket` instances, those instances will be returned in an array. If the `waitForever` flag is set to true, the function will wait indefinitely for data to become available *regardless of the timeout value specified*.
- `createAddress(host: String, port: Int32)` - This *class* function allows for the creation of `Address` enum given a `host` and `port`. On success, this function returns an `Address` or `nil` if the `host` specified doesn't exist.
- `isReadableOrWritable(waitForever: Bool = false, timeout: UInt = 0)` - This *instance function* allows to determine whether a `Socket` instance is readable and/or writable.  A tuple is returned containing two `Bool` values.  The first, if true, indicates the `Socket` instance has data to read, the second, if true, indicates that the `Socket` instance can be written to. `waitForever` if true, causes this routine to wait until the `Socket` is either readable or writable or an error occurs.  If false, the `timeout` parameter specifies how long to wait.  If a value of zero `(0)` is specified for the timeout value, this function will check the *current* status and *immediately* return. This function returns a tuple containing two booleans, the first `readable` and the second, `writable`.  They are set to true if the `Socket` is either readable or writable repsectively.  If neither is set to true, a timeout has occurred. **Note:** If you're attempting to write to a newly connected *Socket*, you should ensure that it's *writable* before attempting the operation.
- `setBlocking(shouldBlock: Bool)` - This *instance function* allows you control whether or not this `Socket` instance should be placed in blocking mode or not. **Note:** All `Socket` instances are, by *default*, created in *blocking mode*.
- `setReadTimeout(value: UInt = 0)` - This *instance function* allows you to set a timeout for read operations. `value` is a `UInt` the specifies the time for the read operation to wait before returning.  In the event of a timeout, the read operation will return `0` bytes read and `errno` will be set to `EAGAIN`.
- `setWriteTimeout(value: UInt = 0)` - This *instance function* allows you to set a timeout for write operations. `value` is a `UInt` the specifies the time for the write operation to wait before returning.  In the event of a timeout, the write operation will return `0` bytes written and `errno` will be set to `EAGAIN` for *TCP* and *UNIX* sockets, for *UDP*, the write operation will *succeed* regardless of the timeout value.
- `udpBroadcast(enable: Bool)` - This *instance function* is used to enable broadcast mode on a UDP socket.  Pass `true` to enable broadcast, `false` to disable.  This function will throw an exception if the `Socket` instance is not a UDP socket.

### Complete Example

The following example shows how to create a relatively simple multi-threaded echo server using the new `GCD based` **Dispatch** API. What follows is code for a simple echo server that once running, can be accessed via `telnet ::1 1337`.
```swift

import Foundation
import Socket
import Dispatch

class EchoServer {

    static let quitCommand: String = "QUIT"
    static let shutdownCommand: String = "SHUTDOWN"
    static let bufferSize = 4096

    let port: Int
    var listenSocket: Socket? = nil
    var continueRunning = true
    var connectedSockets = [Int32: Socket]()
    let socketLockQueue = DispatchQueue(label: "com.ibm.serverSwift.socketLockQueue")

    init(port: Int) {
        self.port = port
    }

    deinit {
        // Close all open sockets...
        for socket in connectedSockets.values {
            socket.close()
        }
        self.listenSocket?.close()
    }

    func run() {

        let queue = DispatchQueue.global(qos: .userInteractive)

        queue.async { [unowned self] in

            do {
                // Create an IPV6 socket...
                try self.listenSocket = Socket.create(family: .inet6)

                guard let socket = self.listenSocket else {

                    print("Unable to unwrap socket...")
                    return
                }

                try socket.listen(on: self.port)

                print("Listening on port: \(socket.listeningPort)")

                repeat {
                    let newSocket = try socket.acceptClientConnection()

                    print("Accepted connection from: \(newSocket.remoteHostname) on port \(newSocket.remotePort)")
                    print("Socket Signature: \(newSocket.signature?.description)")

                    self.addNewConnection(socket: newSocket)

                } while self.continueRunning

            }
            catch let error {
                guard let socketError = error as? Socket.Error else {
                    print("Unexpected error...")
                    return
                }

                if self.continueRunning {

                    print("Error reported:\n \(socketError.description)")

                }
            }
        }
        dispatchMain()
    }

    func addNewConnection(socket: Socket) {

        // Add the new socket to the list of connected sockets...
        socketLockQueue.sync { [unowned self, socket] in
            self.connectedSockets[socket.socketfd] = socket
        }

        // Get the global concurrent queue...
        let queue = DispatchQueue.global(qos: .default)

        // Create the run loop work item and dispatch to the default priority global queue...
        queue.async { [unowned self, socket] in

            var shouldKeepRunning = true

            var readData = Data(capacity: EchoServer.bufferSize)

            do {
                // Write the welcome string...
                try socket.write(from: "Hello, type 'QUIT' to end session\nor 'SHUTDOWN' to stop server.\n")

                repeat {
                    let bytesRead = try socket.read(into: &readData)

                    if bytesRead > 0 {
                        guard let response = String(data: readData, encoding: .utf8) else {

                            print("Error decoding response...")
                            readData.count = 0
                            break
                        }
                        if response.hasPrefix(EchoServer.shutdownCommand) {

                            print("Shutdown requested by connection at \(socket.remoteHostname):\(socket.remotePort)")

                            // Shut things down...
                            self.shutdownServer()

                            return
                        }
                        print("Server received from connection at \(socket.remoteHostname):\(socket.remotePort): \(response) ")
                        let reply = "Server response: \n\(response)\n"
                        try socket.write(from: reply)

                        if (response.uppercased().hasPrefix(EchoServer.quitCommand) || response.uppercased().hasPrefix(EchoServer.shutdownCommand)) &&
                            (!response.hasPrefix(EchoServer.quitCommand) && !response.hasPrefix(EchoServer.shutdownCommand)) {

                            try socket.write(from: "If you want to QUIT or SHUTDOWN, please type the name in all caps. 😃\n")
                        }

                        if response.hasPrefix(EchoServer.quitCommand) || response.hasSuffix(EchoServer.quitCommand) {

                            shouldKeepRunning = false
                        }
                    }

                    if bytesRead == 0 {

                        shouldKeepRunning = false
                        break
                    }

                    readData.count = 0

                } while shouldKeepRunning

                print("Socket: \(socket.remoteHostname):\(socket.remotePort) closed...")
                socket.close()

                self.socketLockQueue.sync { [unowned self, socket] in
                    self.connectedSockets[socket.socketfd] = nil
                }

            }
            catch let error {
                guard let socketError = error as? Socket.Error else {
                    print("Unexpected error by connection at \(socket.remoteHostname):\(socket.remotePort)...")
                    return
                }
                if self.continueRunning {
                    print("Error reported by connection at \(socket.remoteHostname):\(socket.remotePort):\n \(socketError.description)")
                }
            }
        }
    }

    func shutdownServer() {
        print("\nShutdown in progress...")
        continueRunning = false

        // Close all open sockets...
        for socket in connectedSockets.values {
            socket.close()
        }

        listenSocket?.close()

        DispatchQueue.main.sync {
            exit(0)
        }
    }
}

let port = 1337
let server = EchoServer(port: port)
print("Swift Echo Server Sample")
print("Connect with a command line window by entering 'telnet ::1 \(port)'")

server.run()
```
This server can be built by specifying the following `Package.swift` file using Swift 4.
```swift
import PackageDescription

let package = Package(
    name: "EchoServer",
	dependencies: [
		.package(url: "https://github.com/IBM-Swift/BlueSocket.git", .upToNextMinor(from: "0.12.76")),
		],
	exclude: ["EchoServer.xcodeproj"]
)
```
Or if you are still using Swift 3, by specifying the following `Package.swift` file.
```swift
import PackageDescription

let package = Package(
	name: "EchoServer",
	dependencies: [
	.Package(url: "https://github.com/IBM-Swift/BlueSocket.git", majorVersion: 0, minor: 12),
	],
	exclude: ["EchoServer.xcodeproj"]
)
```

The following command sequence will build and run the echo server on Linux.  If running on macOS or with any toolchain **NEWER** than the 8/18 toolchain, you can omit the `-Xcc -fblocks` switch as it's no longer needed.
```
$ swift build -Xcc -fblocks
$ .build/debug/EchoServer
Swift Echo Server Sample
Connect with a command line window by entering 'telnet ::1 1337'
Listening on port: 1337
```
