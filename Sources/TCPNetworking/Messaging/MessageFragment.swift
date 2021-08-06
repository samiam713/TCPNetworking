//
//  File.swift
//  
//
//  Created by Samuel Donovan on 7/25/21.
//

import Foundation

public struct MessageFragment {
    var messageType = UInt8.max
    var jsonData = Data()
    
    public init(messageType: UInt8 = UInt8.max, jsonData: Data = Data()) {
        self.messageType = messageType
        self.jsonData = jsonData
    }
    
    public mutating func reset() {
        messageType = UInt8.max
        jsonData.removeAll(keepingCapacity: true)
    }
    
    /// - Returns: true iff we're done
    public mutating func receive(byte: UInt8) -> Bool {
        
        if byte == MessageNamespace.terminatorByte {return true}
        
        if messageType == UInt8.max {
            messageType = byte
        } else {
            jsonData.append(byte)
        }
        return false
    }
}
