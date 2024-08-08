//
//  ApiModelInterface.swift
//
//
//  Created by Mico Miloloza on 28.12.2023..
//

import Vapor


public protocol ApiModelInterface {
    associatedtype Module: ApiModuleInterface
    
    static var pathKey: String { get }
    static var pathIdKey: String { get }
}

public extension ApiModelInterface {
    static var pathKey: String {
        String(describing: self).lowercased() + "s"
    }
    
    static var pathIdKey: String {
        String(describing: self).lowercased() + "Id"
    }
    
    static var pathIdComponent: PathComponent {
        .init(stringLiteral: ":" + pathIdKey)
    }
}
