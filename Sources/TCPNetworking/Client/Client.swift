//
//  File.swift
//  
//
//  Created by Samuel Donovan on 7/25/21.
//

import Foundation
import NIO

/// The logical way to represent a client
class Client {
    
    let host: String
    let port: Int
    
    var channel: Channel?
    
    var active = false
    
    let delegate: ClientDelegate
    var clientHandler: ClientHandler! = nil
    
    var group: MultiThreadedEventLoopGroup? = nil

    
    init(host: String, port: Int, delegate: ClientDelegate) {
        self.host = host
        self.port = port
        
        self.delegate = delegate
    }
    
    func setup() {
        self.clientHandler = ClientHandler(delegate: delegate, client: self)
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: min(System.coreCount,2))
        self.group = group
        let bootstrap = ClientBootstrap(group: group)
            // Enable SO_REUSEADDR.
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelInitializer { channel in
                channel.pipeline.addHandler(self.clientHandler)
            }
        
        self.channel = try? bootstrap.connect(host: host, port: port).wait()
        
        active = true
    }
    
    /// check if delegate methods still get called when this is called
    func shutdown() {
        try? channel?.close().wait()
        try? group?.syncShutdownGracefully()
        channel = nil
        clientHandler = nil
        
        
        active = false
    }
}

