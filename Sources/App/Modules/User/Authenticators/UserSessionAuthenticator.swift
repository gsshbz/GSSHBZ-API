//
//  UserSessionAuthenticator.swift
//  
//
//  Created by Mico Miloloza on 01.07.2023..
//

import Vapor
import Fluent


struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = AuthenticatedUser
    
    func authenticate(sessionID: UUID, for request: Request) async throws {
        guard let user = try await UserAccountModel
            .find(sessionID, on: request.db)
        else {
            return
        }
        
        try request.auth.login(AuthenticatedUser(id: user.requireID(), username: user.username))
    }
}
