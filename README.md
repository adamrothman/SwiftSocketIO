# SwiftSocketIO

SwiftSocketIO is a [Socket.IO](http://socket.io/) (1.x) client written in Swift.

## Features

At present, SwiftSocketIO only implements the websocket transport. The initial connection occurs over HTTP(S) but the connection is upgraded immediately upon successful handshake. If your server doesn't support the websocket transport, you can't use SwiftSocketIO at this time.

The following features are not implemented by SwiftSocketIO but will be included in future releases.

- [ ] XHR polling transport
- [ ] Namespaces
- [ ] Binary events
- [ ] Reconnection attempts
- [ ] Test coverage

## Requirements

- iOS 8.1+ / Mac OS X 10.10+
- Xcode 6.1

### Dependencies

- [Alamofire](https://github.com/Alamofire/Alamofire)
- [SocketRocket](https://github.com/square/SocketRocket)

## Communication

- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. This is the recommended way to add SwiftsocketIO to your project.

CocoaPods 0.36 beta adds supports for Swift and embedded frameworks. You can install it with the following command:

```bash
$ gem install cocoapods --pre
```

To integrate SwiftSocketIO into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
platform :ios, '8.1'

pod 'SwiftSocketIO', :git => 'https://github.com/adamrothman/SwiftSocketIO.git'
```

SwiftSocketIO is not yet available from the CocoaPods trunk. For now, you must specify it as a `git` dependency, rather than by version.

Then, run the following command at the root of your project:

```bash
$ pod install
```

This will integrate SwiftSocketIO and its dependencies into your project.

To develop SwiftSocketIO, clone the repository and run `pod install` at the root to install the dependencies.

## API

### Classes and Types

#### class SocketIO

#### typealias EventHandler = ([AnyObject]?) -> Void

### SocketIO Instance Methods

#### required init(host: NSURL)

Designated initializer. Returns a `SocketIO` instance configured to connect to the URL specified by `host`. `host` should be a fully qualified URL, including the protocol (`http` or `https`). If `https` is used, the secure `wss` protocol will be used for the websocket connection.

#### convenience init?(host: String)

Convenience intializer. Attempts to create an `NSURL` instance from `host`. This is initializer is failable, meaning that it returns an optional value. If successful, delegates to the designated initializer above. If not, returns `nil`.

#### connect()

Opens the socket connection. Must be called before you can send or receive any data on the socket.

#### emit(event: String, data: AnyObject...)

Emits an event with name `event` and optionally, the objects passed as `data`. You can 0 or more objects as `data`, but they must all be JSON serializable. This is not currently enforced by the compiler; passing a non-serializable object will cause a crash.

#### on(event: String, handler: EventHandler)

Registers `handler` for `event`. If the event is sent with additional data, `handler` will be called with an `Array` containing these items.

Calling this method multiple times will overwrite previously registered handlers.

#### clearHandlers()

Removes all previously registered event handlers.

#### disconnect()

Closes the socket connection. If you have registered a handler for the `"disconnect"` event, it will be called before the connection is closed.

## Usage Examples

### Initializing and Opening a Socket

```swift
import SwiftSocketIO

let socket: SwiftSocketIO.SocketIO = SwiftSocketIO.SocketIO(host: NSURL(scheme: "https", host: "mysocketserver.com", path: "/")!)
socket.connect()

// or

let socket: SwiftSocketIO.SocketIO? = SwiftSocketIO.SocketIO(host: "https://mysocketserver.com")
socket?.connect()
```

### Emitting Events

```swift
socket.emit("no data")
socket.emit("a string", data: "hi there")
socket.emit("an array", data: ["iOS", 8.1])
socket.emit("a dictionary", data: ["user": "adam", "message": "hello world"])
socket.emit("different objects", data: "adam", [1, 2], ["hello": "world"])
```

### Registering Handlers

```swift
socket.on("connect") { (_) in
    println("socket connected")
}

socket.on("no data") { (_) in
    println("no data... so sad")
}

socket.on("a string") { (args) in
    if let s: String = args?.first as? String {
        println("received a string: \(s)")
    }
}

socket.on("an array") { (args) in
    if let a: [AnyObject] = args?.first as? Array {
        println("got an array: \(a)")
    }
}

socket.on("a dictionary") { (args) in
    if let d: [String: String] = args?.first as? Dictionary {
        println("got a dictionary: \(d)")
    }
}

socket.on("different objects") { (args) in
    for o in args {
        println("got object: \(o)")
    }
}

socket.on("disconnect") { (_) in
    println("socket disconnected")
}
```

## License

SwiftSocketIO is released under the MIT license. See LICENSE for details.
