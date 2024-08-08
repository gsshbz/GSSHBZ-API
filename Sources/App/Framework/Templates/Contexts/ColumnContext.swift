//
//  ColumnContext.swift
//
//
//  Created by Mico Miloloza on 11.10.2023..
//

import Foundation


public struct ColumnContext {
    public let key: String
    public let label: String
    
    public init(key: String, label: String? = nil) {
        self.key = key
        self.label = label ?? key.capitalized
    }
}
