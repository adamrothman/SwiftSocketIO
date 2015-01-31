//
//  Parser.swift
//  SwiftSocketIO
//
//  Created by Adam Rothman on 1/26/15.
//
//

import Foundation


class Parser: NSObject {

  private class func decodePacket(string: String) -> (Int, String)? {
    let typeIndex = string.startIndex
    if let type = "\(string[typeIndex])".toInt() {
      let payload = string.substringFromIndex(typeIndex.successor())
      return (type, payload)
    }
    return nil
  }

  class func decodeEngineIOPacket(string: String) -> EngineIOPacket? {
    if let (rawType, payload) = decodePacket(string) {
      if let type = EngineIOPacket.TypeCode(rawValue: rawType) {
        return EngineIOPacket(type: type, payload: payload)
      }
    }
    return nil
  }

  class func decodeSocketIOPacket(string: String) -> SocketIOPacket? {
    if let (rawType, payload) = decodePacket(string) {
      if let type = SocketIOPacket.TypeCode(rawValue: rawType) {
        return SocketIOPacket(type: type, payload: payload)
      }
    }
    return nil
  }

  class func encodePacket(packet: Packet) -> String {
    return "\(packet.rawType)\(packet.payload != nil ? packet.payload! : String())"
  }

}