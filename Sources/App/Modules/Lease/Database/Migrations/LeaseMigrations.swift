//
//  File.swift
//  
//
//  Created by Mico Miloloza on 13.06.2024..
//

import Fluent
import Vapor


enum LeaseMigrations {
    struct v1: AsyncMigration {
        func prepare(on database: Database) async throws {
            // MARK: - LeaseModel
            try await database.schema(LeaseModel.schema)
                .id()
                .field(LeaseModel.FieldKeys.v1.userId, .uuid, .required)
                .foreignKey(LeaseModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id)
                .field(LeaseModel.FieldKeys.v1.createdAt, .datetime)
                .field(LeaseModel.FieldKeys.v1.updatedAt, .datetime)
                .field(LeaseModel.FieldKeys.v1.deletedAt, .datetime)
                .create()
            
            try await database.schema(LeaseItemModel.schema)
                .id()
                .field(LeaseItemModel.FieldKeys.v1.leaseId, .uuid, .required)
                .field(LeaseItemModel.FieldKeys.v1.armoryItemId, .uuid, .required)
                .field(LeaseItemModel.FieldKeys.v1.quantity, .int, .required, .sql(.default(1)))
                .foreignKey(LeaseItemModel.FieldKeys.v1.leaseId, references: LeaseModel.schema, LeaseModel.FieldKeys.v1.id, onDelete: .cascade)
                .foreignKey(LeaseItemModel.FieldKeys.v1.armoryItemId, references: ArmoryItemModel.schema, ArmoryItemModel.FieldKeys.v1.id, onDelete: .cascade)
                .unique(on: LeaseItemModel.FieldKeys.v1.leaseId, LeaseItemModel.FieldKeys.v1.armoryItemId)
                .create()
        }
        
        
        
        func revert(on database: Database) async throws {
            try await database.schema(LeaseModel.schema).delete()
            try await database.schema(LeaseItemModel.schema).delete()
        }
    }
    
    struct seed: AsyncMigration {
        func prepare(on database: any Database) async throws {
            let user = try await UserAccountModel.query(on: database)
                .filter(\.$email == "root@localhost.localhost")
                .first() // Fetch an existing user
            
            guard let user = user else {
                throw Abort(.internalServerError, reason: "No user found for seeding leases.")
            }

            let lease1 = try LeaseModel(userId: try user.requireID())
            let lease2 = try LeaseModel(userId: try user.requireID())
            let lease3 = try LeaseModel(userId: try user.requireID())
            
            try await lease1.create(on: database)
            try await lease2.create(on: database)
            try await lease3.create(on: database)
            
            let armoryItem1 = try await ArmoryItemModel.query(on: database).all().first!
            let armoryItem2 = try await ArmoryItemModel.query(on: database).all().last!
            
            // Create LeaseItemModel to link leases with armory items
            let leaseItem1 = LeaseItemModel(leaseId: try lease1.requireID(), armoryItemId: try armoryItem1.requireID(), quantity: 1)
            let leaseItem2 = LeaseItemModel(leaseId: try lease2.requireID(), armoryItemId: try armoryItem2.requireID(), quantity: 2)
            let leaseItem3 = LeaseItemModel(leaseId: try lease3.requireID(), armoryItemId: try armoryItem1.requireID(), quantity: 3)
            
            try await leaseItem1.create(on: database)
            try await leaseItem2.create(on: database)
            try await leaseItem3.create(on: database)
        }
        
        func revert(on database: any Database) async throws {
            try await LeaseItemModel.query(on: database).delete()
            try await LeaseModel.query(on: database).delete()
        }
    }
}
