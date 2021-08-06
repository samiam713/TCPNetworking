//
//  File.swift
//  
//
//  Created by Samuel Donovan on 7/25/21.
//

import Foundation
import NIO

class ServerData {
    var messageFragment = MessageFragment()
    var pendingResponses = [UUID:(ServerToClient & Response) -> ()]()
}

public final class ClientHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer
    
    let delegate: ClientDelegate
    unowned let client: Client
    
    var serverData = ServerData()
    
    var decoders: [UInt8:(Data)->ServerToClient?] = [:]

    
    init(delegate: ClientDelegate, client: Client) {
        self.delegate = delegate
        self.client = client
        
        delegate.clientHandler = self
        
    }
    
    public func channelActive(context: ChannelHandlerContext) {
        // removed this method because this should be called immediately after the client is setup
        // delegate.connectionStarted()
    }
    
    public func channelInactive(context: ChannelHandlerContext) {
        shutdown(context: context)
    }
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {

        let bytesView = unwrapInboundIn(data).readableBytesView
        
        for byte in bytesView {
            let receiveResult = serverData.messageFragment.receive(byte: byte)
            
            if receiveResult {
                let fragment = serverData.messageFragment
                if let decoder = decoders[fragment.messageType], let message = decoder(fragment.jsonData) {
                    if let response = message as? ServerToClient & Response {
                        if let handler = serverData.pendingResponses[response.id] {
                            handler(response)
                            serverData.pendingResponses[response.id] = nil
                        }
                    } else if let trigger = message as? ServerToClient & Trigger {
                        delegate.triggerReceived(response: trigger, from: context.channel)
                    } else {
                        delegate.messageReceived(message: message, from: context.channel)
                    }
                } else {
                    print("Received bad JSON Data or Invalid message type from channel...shutting down")
                    self.shutdown(context: context)
                }
            }
        }
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        shutdown(context: context)
    }
    
    func shutdown(context: ChannelHandlerContext) {
        context.close(promise: nil)
        client.shutdown()
        delegate.connectionEnded()
    }
    
    func register<T: ServerToClient>(type: T.Type) {
        let handler: (Data)->ServerToClient? = {return try? MessageNamespace.decoder.decode(T.self, from: $0)}
        decoders[type.messageType] = handler
    }
}

public protocol ClientDelegate: AnyObject {
    
    
    /// must be unowned
    var clientHandler: ClientHandler? {get set}
    
    // func connectionStarted()
    
    func connectionEnded()
    
    func messageReceived(message: ServerToClient, from: Channel)
    
    func triggerReceived(response: ServerToClient & Trigger, from: Channel)
}

extension ClientDelegate {
    
    func sendTrigger(trigger: ClientToServer & Trigger, responseHandler: @escaping (ServerToClient & Response) -> ()) {
        clientHandler?.serverData.pendingResponses[trigger.id] = responseHandler
         sendMessage(message: trigger)
    }
    
    func sendMessage(message: ClientToServer) {
        let serializedMessage = message.serialized()
        let buffer = ByteBuffer(bytes: serializedMessage)
        // wrapOutboundOut(buffer)
        clientHandler?.client.channel?.writeAndFlush(buffer, promise: nil)
    }
}
