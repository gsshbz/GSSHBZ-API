//
//  DatabasePasswordTokenRepository.swift
//  
//
//  Created by Mico Miloloza on 03.09.2024..
//

import Vapor
import Fluent


protocol PasswordTokenRepository: Repository {
    func find(userId: UUID) async throws -> PasswordTokenModel?
    func find(token: String) async throws  -> PasswordTokenModel?
    func count() async throws  -> Int
    func create(_ passwordToken: PasswordTokenModel) async throws
    func delete(_ passwordToken: PasswordTokenModel) async throws
    func delete(for userId: UUID) async throws
}

struct DatabasePasswordTokenRepository: PasswordTokenRepository, DatabaseRepository {
    var database: Database
    
    func find(userId: UUID) async throws -> PasswordTokenModel? {
        try await PasswordTokenModel.query(on: database)
            .filter(\.$user.$id == userId)
            .first()
     }
    
    func find(token: String) async throws -> PasswordTokenModel? {
        try await PasswordTokenModel.query(on: database)
            .filter(\.$token == token)
            .first()
    }
    
    func count() async throws -> Int {
        try await PasswordTokenModel.query(on: database).count()
    }
    
    func create(_ passwordToken: PasswordTokenModel) async throws {
        try await passwordToken.create(on: database)
    }
    
    func delete(_ passwordToken: PasswordTokenModel) async throws {
        try await passwordToken.delete(on: database)
    }
    
    func delete(for userId: UUID) async throws {
        try await PasswordTokenModel.query(on: database)
            .filter(\.$user.$id == userId)
            .delete()
    }
}

extension Application.Repositories {
    var passwordTokens: PasswordTokenRepository {
        guard let factory = storage.makePasswordTokenRepository else {
            fatalError("PasswordToken repository not configured, use: app.repositories.use")
        }
        return factory(app)
    }
    
    func use(_ make: @escaping (Application) -> (PasswordTokenRepository)) {
        storage.makePasswordTokenRepository = make
    }
}
