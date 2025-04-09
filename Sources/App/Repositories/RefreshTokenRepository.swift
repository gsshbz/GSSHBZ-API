//
//  File.swift
//  
//
//  Created by Mico Miloloza on 12.07.2022..
//

import Vapor
import Fluent


protocol RefreshTokenRepository: Repository {
    func create(_ token: UserRefreshTokenModel) async throws
    func find(id: UUID?) async throws -> UserRefreshTokenModel?
    func find(token: String) async throws -> UserRefreshTokenModel?
    func delete(_ token: UserRefreshTokenModel) async throws
    func count() async throws -> Int
    func delete(for userId: UUID) async throws
}

struct DatabaseRefreshTokenRepository: RefreshTokenRepository, DatabaseRepository {
    let database: Database
    
    func create(_ token: UserRefreshTokenModel) async throws {
        try await token.create(on: database)
    }
    
    func find(id: UUID?) async throws -> UserRefreshTokenModel? {
         try await UserRefreshTokenModel.find(id, on: database)
    }
    
    func find(token: String) async throws -> UserRefreshTokenModel? {
        try await UserRefreshTokenModel.query(on: database)
            .filter(\.$token == token)
            .first()
    }
    
    func delete(_ token: UserRefreshTokenModel) async throws {
        try await token.delete(on: database)
    }
    
    func count() async throws -> Int {
        try await UserRefreshTokenModel.query(on: database)
            .count()
    }
    
    func delete(for userId: UUID) async throws {
        try await UserRefreshTokenModel.query(on: database)
            .filter(\.$user.$id == userId)
            .delete()
    }
}

extension Application.Repositories {
    var refreshTokens: RefreshTokenRepository {
        guard let factory = storage.makeRefreshTokenRepository else {
            fatalError("RefreshToken repository not configured, use: app.repositories.use")
        }
        return factory(app)
    }
    
    func use(_ make: @escaping (Application) -> (RefreshTokenRepository)) {
        storage.makeRefreshTokenRepository = make
    }
}

