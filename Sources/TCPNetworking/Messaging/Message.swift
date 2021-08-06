import Foundation

public protocol Message: Codable {
    
    /// Must be unique to a single class.
    /// {messageType != UInt8.max}.
    static var messageType: UInt8 {get}
    
}

public enum MessageNamespace {
    public static let terminatorByte = ("\n" as Character).asciiValue!
    public static let encoder = JSONEncoder()
    public static let decoder = JSONDecoder()
}

extension Message {
    
    /// serializes this data
    public func serialized() -> Data {
        var data = Data()
        data.append(Self.messageType)
        if let message = try? MessageNamespace.encoder.encode(self) {
            data.append(message)
        }
        data.append(MessageNamespace.terminatorByte)
        return data
    }
}

public protocol ClientToServer: Message {}

public protocol ServerToClient: Message {}

public protocol Trigger: Message {
    var id: UUID {get}
}

public protocol Response: Message {
    var id: UUID {get}
}
