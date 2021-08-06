//
//  File.swift
//  
//
//  Created by Samuel Donovan on 7/25/21.
//

import Foundation
import NIO

extension Channel {
    var id: ObjectIdentifier {ObjectIdentifier(self)}
}
