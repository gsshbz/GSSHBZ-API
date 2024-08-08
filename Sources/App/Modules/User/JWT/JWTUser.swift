//
//  Payload.swift
//  
//
//  Created by Mico Miloloza on 12.07.2022..
//

import Vapor
import JWT

/// This JWTUser is used for API authentication with JWT
struct JWTUser: JWTPayload, Authenticatable {
    var userId: UUID
    var fullName: String
    var email: String
    var expiration: ExpirationClaim
    
    func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
    
    init(with user: UserAccountModel) throws {
        self.userId = try user.requireID()
        self.fullName = user.firstName + " " + user.lastName
        self.email = user.email
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(Constants.ACCESS_TOKEN_LIFETIME))
    }
}
                                   
                                
