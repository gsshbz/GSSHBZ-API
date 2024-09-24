//
//  EmailTokenRepository.swift
//  
//
//  Created by Mico Miloloza on 12.07.2022..
//

import Vapor
import Fluent


protocol EmailTokenRepository: Repository {
    func find(token: String) async throws -> EmailTokenModel?
    func create(_ emailToken: EmailTokenModel) async throws
    func delete(_ emailToken: EmailTokenModel) async throws
    func find(userId: UUID) async throws -> EmailTokenModel?
}

struct DatabaseEmailTokenRepository: EmailTokenRepository, DatabaseRepository {
    let database: Database
    
    func find(token: String) async throws -> EmailTokenModel? {
        return try await EmailTokenModel.query(on: database)
            .filter(\.$token == token)
            .first()
    }
    
    func create(_ emailToken: EmailTokenModel) async throws {
        return try await emailToken.create(on: database)
    }
    
    func delete(_ emailToken: EmailTokenModel) async throws {
        return try await emailToken.delete(on: database)
    }
    
    func find(userId: UUID) async throws -> EmailTokenModel? {
        try await EmailTokenModel.query(on: database)
            .filter(\.$user.$id == userId)
            .first()
    }
}

extension Application.Repositories {
    var emailTokens: EmailTokenRepository {
        guard let factory = storage.makeEmailTokenRepository else {
            fatalError("EmailToken repository not configured, use: app.repositories.use")
        }
        return factory(app)
    }
    
    func use(_ make: @escaping (Application) -> (EmailTokenRepository)) {
        storage.makeEmailTokenRepository = make
    }
}

