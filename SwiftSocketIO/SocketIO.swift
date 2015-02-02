//
//  SocketIO.swift
//  SwiftSocketIO
//
//  Created by Adam Rothman on 12/23/14.
//
//

import Foundation

import Alamofire


public class SocketIO: TransportDelegate {

  public struct Options {
//    var path: String = "/socket.io/"
    var reconnection: Bool = false
    var reconnectionAttempts: Int = 0
    var reconnectionDelay: Double = 1.0
    var reconnectionDelayMax: Double = 5.0
    var reconnectionJitter: Double = 0.5
    var timeout: Double = 20.0
    var autoConnect: Bool = false
  }

  public typealias EventHandler = ([AnyObject]?) -> Void

  let httpURL: NSURL
  let wsURL: NSURL

  let opts: Options

  let pingDispatchSource: dispatch_source_t
  let timeoutDispatchSource: dispatch_source_t

  var transport: Transport!

  var pingInterval: Double!
  var pingTimeout: Double!

  var handlers: [String: EventHandler] = [:]

  // Convenience property - attempt to get the handler for the 'connect' event
  var connectHandler: EventHandler? {
    get { return handlers["connect"] }
  }

  // Convenience property - attempt to get the handler for the 'disconnect' event
  var disconnectHandler: EventHandler? {
    get { return handlers["disconnect"] }
  }

  // MARK: - Public interface

  required public init(host: NSURL, options: Options = Options()) {
    let httpURLComponents = NSURLComponents(URL: host, resolvingAgainstBaseURL: true)
    httpURLComponents?.path = "/socket.io/"
    httpURL = (httpURLComponents?.URL)!

    // Recycle httpURLComponents to make the ws(s):// URL
    let websocketProtocol = httpURLComponents?.scheme == "https" ? "wss" : "ws"
    httpURLComponents?.scheme = websocketProtocol
    wsURL = (httpURLComponents?.URL)!

    opts = options

    pingDispatchSource = dispatch_source_create(
      DISPATCH_SOURCE_TYPE_TIMER,
      0,
      0,
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
    )

    timeoutDispatchSource = dispatch_source_create(
      DISPATCH_SOURCE_TYPE_TIMER,
      0,
      0,
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
    )

    dispatch_source_set_event_handler(pingDispatchSource) {
      self.transport.send(EngineIOPacket(type: .Ping))
    }
    dispatch_resume(pingDispatchSource)

    dispatch_source_set_event_handler(timeoutDispatchSource) {
      dispatch_source_cancel(self.pingDispatchSource)
      dispatch_source_cancel(self.timeoutDispatchSource)
      self.disconnect()
    }
    dispatch_resume(timeoutDispatchSource)

    if opts.autoConnect {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
        self.connect()
      }
    }
  }

  convenience public init?(host: String) {
    if let url = NSURL(string: host) {
      self.init(host: url)
    } else {
      // The Swift 1.1 compiler is unable to destroy partially initialized classes in all
      // cases, so it disallows formation of a situation where it would have to. We have
      // to initialize the instance before returning nil, for now. From this post on the
      // Apple Developer Forums: https://devforums.apple.com/message/1062922#1062922
      // See the section on failable initializers in the Xcode 6.1 Release Notes here:
      // https://developer.apple.com/library/prerelease/ios/releasenotes/DeveloperTools/RN-Xcode/Chapters/xc6_release_notes.html#//apple_ref/doc/uid/TP40001051-CH4-DontLinkElementID_20
      self.init(host: NSURL(string: "")!)
      return nil
    }
  }

  public func connect() {
    let time = NSDate().timeIntervalSince1970 * 1000
    let timeString = "\(Int(time))-0"

    let manager = Alamofire.Manager(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())

    manager.request(
      .GET,
      httpURL,
      parameters: [
        "b64": true,
        "EIO": 3,
        "transport": "polling",
        "t": timeString
      ]
    ).response { (request, response, data, error) in
      if error == nil {
        if let dataString: String = NSString(data: data as NSData, encoding: NSUTF8StringEncoding) {
          NSLog("[SocketIO]\tconnect response:\n\(dataString)")
          if let separatorIndex = dataString.rangeOfString(":")?.startIndex {
            if separatorIndex < dataString.endIndex {
              if let packetLength = dataString.substringToIndex(separatorIndex).toInt() {
                let packetString = dataString.substringFromIndex(separatorIndex.successor())

                if countElements(packetString) == packetLength {
                  if let packet = Parser.decodeSocketIOPacket(packetString) {
                    if let handshakeInfo: [String: AnyObject] = packet.payloadObject as? Dictionary {
                      let upgrades: [String] = handshakeInfo["upgrades"] as Array

                      if contains(upgrades, "websocket") {
                        let sid: String = handshakeInfo["sid"] as String
                        self.pingInterval = handshakeInfo["pingInterval"] as Double / 1000
                        self.pingTimeout = handshakeInfo["pingTimeout"] as Double / 1000

                        self.transport = WebsocketTransport(URL: self.wsURL, sid: sid)
                        self.transport.delegate = self
                        self.transport.open()
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  public func emit(event: String, data: AnyObject...) {
    NSLog("[SocketIO]\temitting '\(event)' with \(data)")

    let packet = SocketIOPacket(type: .Event)

    var payloadArray: [AnyObject] = [event]
    for datum in data {
      payloadArray.append(datum)
    }
    packet.payloadObject = payloadArray

    transport.send(packet)
  }

  public func on(event: String, handler: EventHandler) {
    handlers[event] = handler
  }

  public func clearHandlers() {
    handlers.removeAll(keepCapacity: true)
  }

  public func disconnect() {
    disconnectHandler?(nil)
    transport.close()
  }

  // MARK: - Heartbeat management

  func startPingPong(delay: Double = 0) {
    let start = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))

    // We have to send a ping every `pingInterval` seconds
    let interval = UInt64(pingInterval * Double(NSEC_PER_SEC))

    // The connection will die if we don't send a ping every `pingTimeout` seconds
    // If `pingTimeout` is larger than `pingInterval`, we have some leeway here
    // If the difference is smaller than 10, we'll say it's 0 just to be safe
    let leeway = pingTimeout - pingInterval > 10 ? UInt64((pingTimeout - pingInterval - 10) * Double(NSEC_PER_SEC)) : UInt64(0)

    dispatch_source_set_timer(pingDispatchSource, start, interval, leeway)

    resetTimeout()
  }

  func resetTimeout() {
    let start = dispatch_time(DISPATCH_TIME_NOW, Int64(pingTimeout * Double(NSEC_PER_SEC)))

    dispatch_source_set_timer(timeoutDispatchSource, start, 0, 0)
  }

  // MARK: - TransportDelegate

  func transportDidOpen(transport: Transport) {
    transport.send(EngineIOPacket(type: .Ping, payload: "probe"))
  }

  func transport(transport: Transport, didReceiveMessage message: String) {
    if let packet = Parser.decodeEngineIOPacket(message) {
      switch packet.type {

      case .Pong:
        if packet.payload == "probe" {
          startPingPong(delay: pingInterval)
          transport.send(EngineIOPacket(type: .Upgrade))
        } else {
          resetTimeout()
        }

      case .Message:
        if let ioPacket = packet.socketIOPacket {
          switch ioPacket.type {

          case .Connect:
            NSLog("[SocketIO]\tconnected")
            connectHandler?(nil)

          case .Disconnect:
            NSLog("[SocketIO]\tdisconnected")
            disconnect()

          case .Event:
            NSLog("[SocketIO]\treceived event:\n\(ioPacket.payloadObject)")
            if let eventArray: [AnyObject] = ioPacket.payloadObject as? Array {
              if let eventName: String = eventArray.first as? String {
                if let handler = handlers[eventName] {
                  if eventArray.count > 1 {
                    let restOfEvent = Array(eventArray[1 ... eventArray.count - 1])
                    handler(restOfEvent)
                  } else {
                    handler(nil)
                  }
                } else {
                  NSLog("[SocketIO]\tno handler registered for \(eventName)")
                }
              }
            }

          case .Ack:
            NSLog("[SocketIO]\treceived ACK")

          case .Error:
            NSLog("[SocketIO]\treceived ERROR")

          case .BinaryEvent:
            NSLog("[SocketIO]\treceived BINARY_EVENT")

          case .BinaryAck:
            NSLog("[SocketIO]\treceived BINARY_ACK")

          }
        }

      // .Open .Close .Ping .Upgrade .NoOp
      default:
        return
      }
    }
  }

  func transport(transport: Transport, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
    NSLog("\(transport) closed with code: \(code), reason: \(reason), wasClean: \(wasClean)")
  }

  func transport(transport: Transport, didFailWithError error: NSError!) {
    NSLog("\(transport) failed with error: \(error)")
  }
}
