//
//  File.swift
//  
//
//  Created by Mico Miloloza on 13.06.2024..
//

import Fluent


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
                .foreignKey(LeaseItemModel.FieldKeys.v1.leaseId, references: LeaseModel.schema, LeaseModel.FieldKeys.v1.id, onDelete: .cascade)
                .foreignKey(LeaseItemModel.FieldKeys.v1.armoryItemId, references: ArmoryItemModel.schema, ArmoryItemModel.FieldKeys.v1.id, onDelete: .cascade)
                .create()
        }
        
        
        
        func revert(on database: Database) async throws {
            try await database.schema(LeaseModel.schema).delete()
            try await database.schema(LeaseItemModel.schema).delete()
        }
    }
}
