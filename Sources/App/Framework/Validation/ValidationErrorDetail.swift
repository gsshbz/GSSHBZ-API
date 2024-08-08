//
//  ValidationErrorDetail.swift
//  
//
//  Created by Mico Miloloza on 10.07.2023..
//

import Vapor


public struct ValidationErrorDetail: Codable {
    var key: String
    var message: String
    
    public init(key: String, message: String) {
        self.key = key
        self.message = message
    }
}

extension ValidationErrorDetail: Content {
    
}
