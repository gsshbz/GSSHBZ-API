//
//  DatabaseModelInterface.swift
//  
//
//  Created by Mico Miloloza on 27.06.2023..
//

import Vapor
import Fluent


public protocol DatabaseModelInterface: Fluent.Model where Self.IDValue == UUID {
    associatedtype Module: ModuleInterface
    
    static var identifier: String { get }
}


public extension DatabaseModelInterface {
    static var schema: String {
        Module.identifier + "_" + identifier
    }
    
    static var identifier: String {
        let identifierString = String(describing: self)
            .dropFirst(Module.identifier.count)
            .dropLast(5)
            .lowercased() + "s"
        
        if identifierString == "s" { return Module.identifier + "s" }
        
        return identifierString
    }
}
