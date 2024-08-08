//
//  HiddenFieldContext.swift
//  
//
//  Created by Mico Miloloza on 30.07.2023..
//


public struct HiddenFieldContext {
    var key: String
    var value: String?
    
    public init(key: String, value: String? = nil) {
        self.key = key
        self.value = value
    }
}
