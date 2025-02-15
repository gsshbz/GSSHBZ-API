//
//  UserRepository.swift
//  
//
//  Created by Mico Miloloza on 12.07.2022..
//

import Vapor
import Fluent


protocol UserRepository: Repository {
    func create(_ user: UserAccountModel) async throws
    func delete(id: UUID) async throws
    func all() async throws -> [User.Account.Detail]
    func find(id: UUID?) async throws -> UserAccountModel?
    func find(email: String) async throws -> UserAccountModel?
    func set<Field>(_ field: KeyPath<UserAccountModel, Field>, to value: Field.Value, for userId: UUID) async throws where Field: QueryableProperty, Field.Model == UserAccountModel
    func count() async throws -> Int
}

struct DatabaseUserRepository: UserRepository, DatabaseRepository {
    let database: Database
    
    func create(_ user: UserAccountModel) async throws {
        return try await user.create(on: database)
    }
    
    func delete(id: UUID) async throws {
        return try await UserAccountModel.query(on: database)
            .filter(\.$id == id)
            .delete()
    }
    
    func all() async throws -> [User.Account.Detail] {
        try await UserAccountModel.query(on: database).all().map { user in
                .init(id: try user.requireID(), firstName: user.firstName, lastName: user.lastName, imageKey: user.imageKey, email: user.email, isAdmin: user.isAdmin)
        }
    }
    
    func find(id: UUID?) async throws -> UserAccountModel? {
        try await UserAccountModel.find(id, on: database)
    }
    
    func find(email: String) async throws -> UserAccountModel? {
        try await UserAccountModel.query(on: database)
            .filter(\.$email == email)
            .first()
    }
    
    func set<Field>(_ field: KeyPath<UserAccountModel, Field>, to value: Field.Value, for userId: UUID) async throws where Field: QueryableProperty, Field.Model == UserAccountModel
    {
        try await UserAccountModel.query(on: database)
            .filter(\.$id == userId)
            .set(field, to: value)
            .update()
    }
    
    func count() async throws -> Int {
        try await UserAccountModel.query(on: database).count()
    }
}

extension Application.Repositories {
    var users: UserRepository {
        guard let storage = storage.makeUserRepository else {
            fatalError("UserRepository not configured, use: app.userRepository.use()")
        }
        
        return storage(app)
    }
    
    func use(_ make: @escaping (Application) -> (UserRepository)) {
        storage.makeUserRepository = make
    }
}




