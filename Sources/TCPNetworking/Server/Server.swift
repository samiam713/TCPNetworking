//
//  File.swift
//  
//
//  Created by Samuel Donovan on 7/25/21.
//

import Foundation
import NIO

class Server {
    let host: String
    let port: Int
    
    var channel: Channel? = nil
    
    let serverHandler: ServerHandler
    
    init(host: String, port: Int, delegate: ServerDelegate) {
        self.host = host
        self.port = port
        
        self.serverHandler = ServerHandler(delegate: delegate)
    }
    
    func setupAndListenForever() {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let bootstrap = ServerBootstrap(group: group)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

            // Set the handlers that are appled to the accepted Channels
            .childChannelInitializer { channel in
                // Ensure we don't read faster than we can write by adding the BackPressureHandler into the pipeline.
                channel.pipeline.addHandler(BackPressureHandler()).flatMap { v in
                    channel.pipeline.addHandler(self.serverHandler)
                }
            }

            // Enable SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        
        defer {
            try? group.syncShutdownGracefully()
        }

        guard let channel = try? bootstrap.bind(host: host, port: port).wait() else {
            print("Couldn't Bind to Channel")
            return
        }
        self.channel = channel

        if let localAddress = channel.localAddress {
            print("Server started and listening on \(localAddress)")
        } else {
            print("Logic Error in Server.swift: Couldn't find localAddress")
        }
        
        guard let _ = try? channel.closeFuture.wait() else {
            print("Server Crashed")
            return
        }
        print("Server closed")
    }
}
