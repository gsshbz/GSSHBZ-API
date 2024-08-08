//
//  ApiUserAuthenticator.swift
//
//
//  Created by Mico Miloloza on 12.06.2024..
//

import Vapor
import JWT

/// This authenticator is used for API Authentication with JWT
struct ApiUserAuthenticator: JWTAuthenticator {
    typealias Payload = JWTUser
    
/// Function: authenticate
/// 
/// - Parameters:
///   - jwt: Payload
///   - for request: Request
/// - Returns: EventLoopFuture<Void>
    func authenticate(jwt: Payload, for request: Request) -> EventLoopFuture<Void> {
        request.auth.login(jwt)
        return request.eventLoop.makeSucceededFuture(())
    }
}

