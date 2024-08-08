//
//  OptionContext.swift
//  
//
//  Created by Mico Miloloza on 30.07.2023..
//

import Foundation


public struct OptionContext {
    let key: String
    let label: String
    
    public init(key: String, label: String) {
        self.key = key
        self.label = label
    }
}


public extension OptionContext {
    static func yesNo() -> [OptionContext] {
        ["yes", "no"].map { .init(key: $0, label: $0.capitalized) }
    }
    
    static func trueFalse() -> [OptionContext] {
        [true, false].map { .init(key: String($0), label: String($0).capitalized) }
    }
    
    static func numbers(_ numbers: [Int]) -> [OptionContext] {
        numbers.map { .init(key: String($0), label: String($0)) }
    }
}
