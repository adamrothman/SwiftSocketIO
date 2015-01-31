# SwiftSocketIO

SwiftSocketIO is a [Socket.IO](http://socket.io/) (1.x) client written in Swift.

## Features

At present, SwiftSocketIO only implements the websocket transport. The initial connection occurs over HTTP(S) but the connection is upgraded immediately upon successful handshake. If your server doesn't support the websocket transport, you can't use SwiftSocketIO at this time.

The following features are not implemented by SwiftSocketIO but will be included in future releases.

- [ ] XHR polling transport
- [ ] Namespaces
- [ ] Binary events
- [ ] Test coverage

## Requirements

- iOS 8.1+ / Mac OS X 10.10+
- Xcode 6.1

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

pod 'SwiftSocketIO', '~> 0.1.0'
```

Then, run the following command at the root of your project:

```bash
$ pod install
```

### Carthage

Carthage is a decentralized dependency manager that automates the process of adding frameworks to your Cocoa application.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate Alamofire into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "adamrothman/SwiftSocketIO" >= 0.1.0
```

---

## API

### Classes and Types

#### class SocketIO

#### typealias EventHandler = ([AnyObject]?) -> Void

### SocketIO Instance Methods

#### init(host: String, secure: Bool)

Designated initializer. Returns a `SocketIO` instance configured to connect to `host`. If `secure` is `true`, connection will use the `https` and `wss` protocols.

#### connect()

Opens the socket connection. Must be called before you can send or receive any data on the socket.

#### emit(event: String, data: AnyObject? = nil)

Emits an event with name `event` and optionally, payload `data`. If not `nil`, `data` must be an object that is JSON serializable.

#### on(event: String, handler: EventHandler)

Registers `handler` for `event`. If the event is sent with additional data, `handler` will be called with an `Array` containing these items.

Calling this method multiple times will overwrite previously registered handlers.

#### clearHandlers()

Removes all previously registered event handlers.

#### disconnect()

Closes the socket connection. If you have registered a handler for the `"disconnect"` event, it will be called before the connection is closed.

---

## Usage Examples

### Initializing and Opening a Socket

```swift
import SwiftSocketIO

let socket = SwiftSocketIO.SocketIO(host: "mysocketserver.com", secure: true)
socket.connect()
```

### Emitting Events

```swift
socket.emit("begin session")
socket.emit("new user", data: "adam")
socket.emit("device os", data: ["iOS", 8.1])
socket.emit("message", data: ["user": "adam", "content": "hello world"])
```

### Registering Handlers

```swift
socket.on("connect") { (_) in
    println("socket connected")
}

socket.on("new user") { (args) in
    if let newUser: String = args?.first as? String {
        println("new user: \(newUser)")
    }
}

socket.on("device os") { (args) in
    if let osInfo: [String] = args as? Array {
        println("device OS: \(osInfo[0]), version: \(osInfo[1])")
    }
}

socket.on("message") { (args) in
    if let message: [String: String] = args?.first as? Dictionary {
        println("message from \(message["user"]!): \(message["content"]!)")
    }
}
```

---

## License

SwiftSocketIO is released under the MIT license. See LICENSE for details.
