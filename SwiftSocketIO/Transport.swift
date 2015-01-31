//
//  Transport.swift
//  SwiftSocketIO
//
//  Created by Adam Rothman on 1/26/15.
//
//

import Foundation

import Alamofire
import SocketRocket


protocol Transport: class, NSObjectProtocol {
  weak var delegate: TransportDelegate? { get set }

  var isReady: Bool { get }

  init(URL: NSURL, sid: String)

  func open()
  func send(packet: Packet)
  func close()
}


protocol TransportDelegate: class, NSObjectProtocol {
  func transportDidOpen(transport: Transport)
  func transport(transport: Transport, didReceiveMessage message: String)
  func transport(transport: Transport, didCloseWithCode code: Int, reason: String!, wasClean: Bool)
  func transport(transport: Transport, didFailWithError error: NSError!)
}


class WebsocketTransport: NSObject, Transport, SRWebSocketDelegate {

  var URL: NSURL!
  var sid: String!

  var socket: SRWebSocket!

  var packetQueue: [Packet] = []

  weak var delegate: TransportDelegate?

  var isReady: Bool {
    get { return socket.readyState.value == 1 }
  }


  required init(URL: NSURL, sid: String) {
    self.URL = URL
    self.sid = sid
  }

  func open() {
    let parameters: [String: AnyObject] = [
      "EIO": 3,
      "sid": sid,
      "transport": "websocket"
    ]
    var request: NSURLRequest
    (request, _) = Alamofire.ParameterEncoding.URL.encode(
      NSURLRequest(URL: URL!),
      parameters: parameters
    )

    socket = SRWebSocket(URLRequest: request)
    socket.delegate = self
    socket.open()
  }

  func send(packet: Packet) {
    if isReady {
      if let engineIOPacket = packet as? EngineIOPacket {
        let packetString = Parser.encodePacket(engineIOPacket)
        NSLog("[WebsocketTransport]\tsending:\t\(packetString)")
        socket.send(packetString)
      } else if let socketIOPacket = packet as? SocketIOPacket {
        send(EngineIOPacket(type: .Message, payload: Parser.encodePacket(socketIOPacket)))
      }
    } else {
      NSLog("[WebsocketTransport]\tsocket not ready; queueing packet")
      packetQueue.append(packet)
      return
    }
  }

  func close() {
    socket.close()
  }

  // MARK: - SRWebSocketDelegate

  func webSocketDidOpen(webSocket: SRWebSocket!) {
    NSLog("[WebsocketTransport]\tsocket opened")
    for packet in packetQueue {
      send(packet)
    }
    packetQueue.removeAll(keepCapacity: false)
    delegate?.transportDidOpen(self)
  }

  func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
    var messageString = message as String
    NSLog("[WebsocketTransport]\treceived:\t\(messageString)")
    delegate?.transport(self, didReceiveMessage: messageString)
  }

  func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
    delegate?.transport(self, didCloseWithCode: code, reason: reason, wasClean: wasClean)
  }

  func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
    delegate?.transport(self, didFailWithError: error)
  }
  
}