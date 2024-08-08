//
//  UserCredentialsAuthenticator.swift
//  
//
//  Created by Mico Miloloza on 01.07.2023..
//

import Vapor
import Fluent


struct UserCredentialsAuthenticator: AsyncCredentialsAuthenticator {
    struct Credentials: Content {
        let email: String
        let password: String
    }
    
    func authenticate(credentials: Credentials, for request: Request) async throws {
        guard let user = try await UserAccountModel
            .query(on: request.db)
            .filter(\.$email == credentials.email)
            .first() else { throw Abort(.notFound) }
        
        do {
            guard try Bcrypt.verify(credentials.password, created: user.password) else { return }
            
            try request.auth.login(AuthenticatedUser(id: user.requireID(), username: user.username))
        } catch {
            // do nothing...
        }
    }
}
