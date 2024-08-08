//
//  CellContext.swift
//
//
//  Created by Mico Miloloza on 10.10.2023..
//

import Foundation


public struct CellContext {
    public enum `Type`: String {
        case text
        case image
    }
    
    public let value: String
    public let link: LinkContext?
    public let type: `Type`
    
    public init(value: String, link: LinkContext? = nil, type: `Type` = .text) {
        self.value = value
        self.link = link
        self.type = type
    }
}
