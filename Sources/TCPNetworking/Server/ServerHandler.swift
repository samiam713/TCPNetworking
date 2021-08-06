//
//  File.swift
//  
//
//  Created by Samuel Donovan on 7/25/21.
//

import Foundation
import NIO

class ChannelData {
    var messageFragment = MessageFragment()
    var pendingResponses = [UUID:(ClientToServer & Response) -> ()]()
}

final class ServerHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer
    
    var channelToData: [ObjectIdentifier:ChannelData] = [:]
    var delegate: ServerDelegate
    
    var decoders: [UInt8:(Data)->ClientToServer?] = [:]
    
    init(delegate: ServerDelegate) {
        self.delegate = delegate
        self.delegate.serverHandler = self
    }
    
    func channelActive(context: ChannelHandlerContext) {
        print("Channel Active Fired")
        channelToData[context.channel.id] = ChannelData()
        delegate.connectionStarted(channel: context.channel)
    }
    
    func channelInactive(context: ChannelHandlerContext) {
        print("Channel Inactive Fired")
        remove(context: context)
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        guard let channelData = channelToData[context.channel.id] else {
            context.close(promise: nil)
            return
        }
        
        let bytesView = unwrapInboundIn(data).readableBytesView
        
        for byte in bytesView {
            let receiveResult = channelData.messageFragment.receive(byte: byte)
            
            if receiveResult {
                let fragment = channelData.messageFragment
                if let decoder = decoders[fragment.messageType], let message = decoder(fragment.jsonData) {
                    if let response = message as? ClientToServer & Response {
                        if let handler = channelToData[context.channel.id]?.pendingResponses[response.id] {
                            handler(response)
                            channelToData[context.channel.id]?.pendingResponses[response.id] = nil
                        }
                    } else if let trigger = message as? ClientToServer & Trigger {
                        delegate.triggerReceived(trigger: trigger, from: context.channel)
                    } else {
                        delegate.messageReceived(message: message, from: context.channel)
                    }
                } else {
                    print("Received bad JSON Data or Invalid message type from channel...removing it")
                    remove(context: context)
                }
            }
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        remove(context: context)
    }
    
    func remove(context: ChannelHandlerContext) {
        channelToData[context.channel.id] = nil
        context.close(promise: nil)
        delegate.connectionEnded(channel: context.channel)
    }
    
    
    func register<T: ClientToServer>(type: T.Type) {
        let handler: (Data)->ClientToServer? = {return try? MessageNamespace.decoder.decode(T.self, from: $0)}
        decoders[type.messageType] = handler
    }
}

protocol ServerDelegate: AnyObject {
    
    var serverHandler: ServerHandler? {get set}
    
    func connectionStarted(channel: Channel)
    
    func connectionEnded(channel: Channel)
    
    func messageReceived(message: ClientToServer, from: Channel)
    
    func triggerReceived(trigger: ClientToServer & Trigger, from: Channel)
}

extension ServerDelegate {
    
    func sendTrigger(trigger: ServerToClient & Trigger, to: Channel, responseHandler: @escaping (ClientToServer & Response) -> ()) {
        guard let channelData = serverHandler?.channelToData[to.id] else {
            print("Logic Error in ServerHandler.swift: Couldn't find channel's data (it was probably deleted)")
            return
        }
        channelData.pendingResponses[trigger.id] = responseHandler
        sendMessage(message: trigger, to: to)
    }
    
    func sendMessage(message: ServerToClient, to: Channel) {
        let serializedMessage = message.serialized()
        let buffer = ByteBuffer(bytes: serializedMessage)
        // wrapOutboundOut(buffer)
        to.writeAndFlush(buffer, promise: nil)
    }
}
