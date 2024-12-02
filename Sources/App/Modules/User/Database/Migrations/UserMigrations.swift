//
//  UserMigrations.swift
//  
//
//  Created by Mico Miloloza on 28.06.2023..
//

import Vapor
import Fluent


enum UserMigrations {
    struct v1: AsyncMigration {
        func prepare(on database: Database) async throws {
            // MARK: - UserAccountModel
            try await database.schema(UserAccountModel.schema)
                .id()
                .field(UserAccountModel.FieldKeys.v1.firstName, .string, .required)
                .field(UserAccountModel.FieldKeys.v1.lastName, .string, .required)
                .field(UserAccountModel.FieldKeys.v1.email, .string, .required)
                .field(UserAccountModel.FieldKeys.v1.password, .string, .required)
                .field(UserAccountModel.FieldKeys.v1.phoneNumber, .string)
                .field(UserAccountModel.FieldKeys.v1.address, .string)
                .field(UserAccountModel.FieldKeys.v1.profileImageUrlString, .string)
                .field(UserAccountModel.FieldKeys.v1.isAdmin, .bool, .required, .sql(.default(false)))
                .field(UserAccountModel.FieldKeys.v1.createdAt, .datetime)
                .field(UserAccountModel.FieldKeys.v1.updatedAt, .datetime)
                .field(UserAccountModel.FieldKeys.v1.deletedAt, .datetime)
                .unique(on: UserAccountModel.FieldKeys.v1.email)
                .create()
            
            // MARK: - RefreshTokenModel
            try await database.schema(RefreshTokenModel.schema)
                .id()
                .field(RefreshTokenModel.FieldKeys.v1.token, .string)
                .field(RefreshTokenModel.FieldKeys.v1.userId, .uuid, .references(UserAccountModel.schema, UserAccountModel.FieldKeys.v1.id, onDelete: .cascade))
                .field(RefreshTokenModel.FieldKeys.v1.expiresAt, .datetime)
                .field(RefreshTokenModel.FieldKeys.v1.issuedAt, .datetime)
                .foreignKey(RefreshTokenModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id)
                .unique(on: RefreshTokenModel.FieldKeys.v1.token)
                .unique(on: RefreshTokenModel.FieldKeys.v1.userId)
                .create()
            
            //MARK: - OAuthToken
            try await database.schema(OAuthToken.schema)
                .id()
                .field(OAuthToken.FieldKeys.v1.value, .string, .required)
                .field(OAuthToken.FieldKeys.v1.userId, .uuid, .required, .references(UserAccountModel.schema, UserAccountModel.FieldKeys.v1.id, onDelete: .cascade))
                .field(OAuthToken.FieldKeys.v1.source, .int, .required)
                .field(OAuthToken.FieldKeys.v1.createdAt, .datetime, .required)
                .field(OAuthToken.FieldKeys.v1.expiresAt, .datetime)
                .unique(on: OAuthToken.FieldKeys.v1.value)
                .create()
            
            try await database.schema(EmailTokenModel.schema)
                .id()
                .field(EmailTokenModel.FieldKeys.v1.userId, .uuid, .required, .references(UserAccountModel.schema, UserAccountModel.FieldKeys.v1.id, onDelete: .cascade))
                .field(EmailTokenModel.FieldKeys.v1.token, .string, .required)
                .field(EmailTokenModel.FieldKeys.v1.expiresAt, .datetime, .required)
                .unique(on: EmailTokenModel.FieldKeys.v1.userId)
                .unique(on: EmailTokenModel.FieldKeys.v1.token)
                .create()
            
            try await database.schema(PasswordTokenModel.schema)
                .id()
                .field(PasswordTokenModel.FieldKeys.v1.userId, .uuid, .required, .references(UserAccountModel.schema, UserAccountModel.FieldKeys.v1.id, onDelete: .cascade))
                .field(PasswordTokenModel.FieldKeys.v1.token, .string, .required)
                .field(PasswordTokenModel.FieldKeys.v1.expiresAt, .datetime, .required)
                .create()
            
            try await database.schema(ResetPasswordTokenModel.schema)
                .id()
                .field(ResetPasswordTokenModel.FieldKeys.v1.token, .string, .required)
                .field(ResetPasswordTokenModel.FieldKeys.v1.userId, .uuid, .required, .references(UserAccountModel.schema, UserAccountModel.FieldKeys.v1.id))
                .field(ResetPasswordTokenModel.FieldKeys.v1.createdAt, .datetime)
                .unique(on: ResetPasswordTokenModel.FieldKeys.v1.token)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(UserAccountModel.schema).delete()
            try await database.schema(RefreshTokenModel.schema).delete()
            try await database.schema(OAuthToken.schema).delete()
            try await database.schema(EmailTokenModel.schema).delete()
            try await database.schema(PasswordTokenModel.schema).delete()
            try await database.schema(ResetPasswordTokenModel.schema).delete()
        }
    }
    
    struct seed: AsyncMigration {
        func prepare(on database: Database) async throws {
            let password = "admin"
            let userAccountModel = UserAccountModel(firstName: "Admin",
                                                    lastName: "Admin",
                                                    email: "root@localhost.localhost",
                                                    password: try Bcrypt.hash(password),
                                                    phoneNumber: "00387445394857",
                                                    address: "Ulica 1",
                                                    profileImageUrlString: "\(AppConfig.environment.frontendUrl)/img/default-avatar.jpg")
            
            try await userAccountModel.create(on: database)
        }
        
        func revert(on database: Database) async throws {
            
        }
    }
}
