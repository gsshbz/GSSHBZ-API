//
//  DetailContext.swift
//
//
//  Created by Mico Miloloza on 16.10.2023..
//

import Foundation


public struct DetailContext {
    public enum `Type`: String {
        case text
        case image
    }
    
    public let key: String
    public let label: String
    public let value: String
    public let type: `Type`
    
    public init(_ key: String, _ value: String, label: String? = nil, type: `Type` = .text) {
        self.key = key
        self.value = value
        self.label = label ?? key.capitalized
        self.type = type
    }
}
