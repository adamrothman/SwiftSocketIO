//
//  Packet.swift
//  SwiftSocketIO
//
//  Created by Adam Rothman on 1/25/15.
//
//

import Foundation


protocol Packet: class {
  var rawType: Int { get }
  var payload: String? { get set }
}


class EngineIOPacket: Packet {

  enum TypeCode: Int {
    case Open     = 0 // non-ws
    case Close    = 1 // non-ws
    case Ping     = 2
    case Pong     = 3
    case Message  = 4
    case Upgrade  = 5
    case NoOp     = 6
  }
  
  var type: TypeCode

  var rawType: Int {
    get { return type.rawValue }
  }

  var payload: String?

  // Convenience property - attempt to construct a SocketIOPacket from the payload
  var socketIOPacket: SocketIOPacket? {
    get { return payload != nil ? Parser.decodeSocketIOPacket(payload!) : nil }
  }
  
  init(type: TypeCode, payload: String? = nil) {
    self.type = type
    self.payload = payload
  }

}


class SocketIOPacket: Packet {

  enum TypeCode: Int {
    case Connect = 0
    case Disconnect
    case Event
    case Ack
    case Error
    case BinaryEvent
    case BinaryAck
  }

  var type: TypeCode

  var rawType: Int {
    get { return type.rawValue }
  }

  var payload: String?

  // Convenience property
  var payloadObject: AnyObject? {
    // If payload string is JSON, decode it to native object
    get {
      if let payloadData = payload?.dataUsingEncoding(NSUTF8StringEncoding) {
        var error: NSError?
        return NSJSONSerialization.JSONObjectWithData(payloadData, options: NSJSONReadingOptions(0), error: &error)
      } else {
        return nil
      }
    }

    // Encode native object as JSON, store it in payload
    set {
      if newValue != nil {
        var error: NSError?
        if let payloadData = NSJSONSerialization.dataWithJSONObject(newValue!, options: NSJSONWritingOptions(0), error: &error) {
          payload = NSString(data: payloadData, encoding: NSUTF8StringEncoding)
        }
      }
    }
  }

  init(type: TypeCode, payload: String? = nil) {
    self.type = type
    self.payload = payload
  }

}
