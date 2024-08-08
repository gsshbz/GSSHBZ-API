//
//  File.swift
//  
//
//  Created by Mico Miloloza on 14.02.2024..
//

import Vapor


extension SHA256 {
    /// Returns hex-encoded string
    static func hash(_ string: String) -> String {
        SHA256.hash(data: string.data(using: .utf8)!)
    }
    
    /// Returns a hex encoded string
    static func hash<D>(data: D) -> String where D : DataProtocol {
        SHA256.hash(data: data).hex
    }
}

