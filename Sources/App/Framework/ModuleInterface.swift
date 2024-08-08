//
//  ModuleInterface.swift
//  
//
//  Created by Mico Miloloza on 25.06.2023..
//

import Vapor


public protocol ModuleInterface {
    static var identifier: String { get }
    
    func boot(_ app: Application) throws
}


public extension ModuleInterface {
    func boot(_ app: Application) throws { }
    
    static var identifier: String {
        return String(describing: self).dropLast(6).lowercased()
    }
}
