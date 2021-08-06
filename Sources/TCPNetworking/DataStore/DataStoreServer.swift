//
//  File.swift
//  
//
//  Created by Samuel Donovan on 7/30/21.
//

import Foundation
import NIO


public class DataStoreServer: ServerDelegate {
    var serverHandler: ServerHandler? = nil
    
    var server: Server! = nil
    
    var data = [String:Data]()
    
    public init(host: String, port: Int) {
        self.server = Server(host: host, port: port, delegate: self)
        self.server.serverHandler.register(type: DataStoreClientToServer.SetRequest.self)
        self.server.serverHandler.register(type: DataStoreClientToServer.GetRequest.self)
    }
    
    public func setupAndListenForever() {
        server.setupAndListenForever()
    }
    
    func connectionStarted(channel: Channel) {print("Connection Started")}
    
    func connectionEnded(channel: Channel) {print("Connection Ended")}
    
    func messageReceived(message: ClientToServer, from: Channel) {}
    
    func triggerReceived(trigger: ClientToServer & Trigger, from: Channel) {
        if let setRequest = trigger as? DataStoreClientToServer.SetRequest {
            data[setRequest.path] = setRequest.data
            let response = DataStoreServerToClient.SetResponse(id: setRequest.id, success: true)
            sendMessage(message: response, to: from)
        } else if let getRequest = trigger as? DataStoreClientToServer.GetRequest {
            let responseData = data[getRequest.path]
            let response = DataStoreServerToClient.GetResponse(id: getRequest.id, data: responseData)
            sendMessage(message: response, to: from)
        }
    }
}
