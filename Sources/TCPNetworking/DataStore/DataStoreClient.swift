//
//  File.swift
//  
//
//  Created by Samuel Donovan on 7/30/21.
//

import Foundation
import NIO

public class DataStoreClient: ClientDelegate {
    public var clientHandler: ClientHandler?
    
    var client: Client! = nil
    
    public init?(host: String, port: Int) {
        self.client = Client(host: host, port: port, delegate: self)
        let setup = self.client.setup()
        guard setup == .success else {return nil}
        
        guard let clientHandler = self.clientHandler else {return nil}
        clientHandler.register(type: DataStoreServerToClient.SetResponse.self)
        clientHandler.register(type: DataStoreServerToClient.GetResponse.self)
    }
    
    public func connectionEnded() {
        print("Logic Error in DataStoreClient.swift: Got kicked but shouldn't have")
    }
    
    public func messageReceived(message: ServerToClient, from: Channel) {
        
    }
    
    public func triggerReceived(response: ServerToClient & Trigger, from: Channel) {
        
    }
    
    public func set(path: String, data: Data?, completion: @escaping (Bool) -> ()) {
        let trigger = DataStoreClientToServer.SetRequest(path: path, data: data)
        
        sendTrigger(trigger: trigger) {(response: Response & ServerToClient) in
            guard let response = response as? DataStoreServerToClient.SetResponse else {
                print("Logic Error in DataStoreClient.swift: Didn't get a SetResponse object")
                return
            }
            completion(response.success)
        }
    }
    
    public func get(path: String, completion: @escaping (Data?) -> ()) {
        let trigger = DataStoreClientToServer.GetRequest(path: path)
        
        sendTrigger(trigger: trigger) {(response: Response & ServerToClient) in
            guard let response = response as? DataStoreServerToClient.GetResponse else {
                print("Logic Error in DataStoreClient.swift: Didn't get a SetResponse object")
                return
            }
            
            completion(response.data)
        }
    }
}

