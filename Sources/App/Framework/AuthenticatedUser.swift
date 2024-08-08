//
//  AuthenticatedUser.swift
//  
//
//  Created by Mico Miloloza on 29.06.2023..
//

import Vapor


public struct AuthenticatedUser {
    public let id: UUID
    public let username: String
    
    public init(id: UUID, username: String) {
        self.id = id
        self.username = username
    }
}


extension AuthenticatedUser: SessionAuthenticatable {
    public var sessionID: UUID { id }
}
