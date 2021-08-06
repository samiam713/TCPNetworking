//
//  File.swift
//  
//
//  Created by Samuel Donovan on 8/3/21.
//

import Foundation

enum DataStoreClientToServer {
    class SetRequest: ClientToServer, Trigger {
        static var messageType: UInt8 = 0
        
        let id: UUID
        let path: String
        let data: Data?
        
        init(path: String, data: Data?) {
            self.id = UUID()
            
            self.path = path
            self.data = data
        }
    }
    
    class GetRequest: ClientToServer, Trigger {
        static var messageType: UInt8 = 1
        
        let id: UUID
        let path: String
        
        init(path: String) {
            self.id = UUID()
            
            self.path = path
        }
    }
}

enum DataStoreServerToClient {
    class SetResponse: ServerToClient, Response {
        static var messageType: UInt8 = 0
        
        var id: UUID
        let success: Bool
        
        init(id: UUID, success: Bool) {
            self.id = id
            self.success = success
        }
    }
    
    class GetResponse: ServerToClient, Response {
        static var messageType: UInt8 = 1
        
        var id: UUID
        let data: Data?
        
        init(id: UUID, data: Data?) {
            self.id = id
            self.data = data
        }
        
    }
}
