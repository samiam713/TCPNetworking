//
//  File.swift
//  
//
//  Created by Samuel Donovan on 7/30/21.
//

import Foundation
import NIO

public class DataStoreClient: ClientDelegate {
    var clientHandler: ClientHandler?
    
    var client: Client! = nil
    
    public init(host: String, port: Int) {
        self.client = Client(host: host, port: port, delegate: self)
        
        self.client.clientHandler.register(type: DataStoreServerToClient.SetResponse.self)
        self.client.clientHandler.register(type: DataStoreServerToClient.GetResponse)
    }
    
    func connectionEnded() {
        print("Error...we got kicked but shouldn't have")
    }
    
    func messageReceived(message: ServerToClient, from: Channel) {
        
    }
    
    func triggerReceived(response: ServerToClient & Trigger, from: Channel) {
        
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

