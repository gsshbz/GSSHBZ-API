//
//  VehicleMigrations.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 03.02.2025..
//

import Fluent
import Vapor


enum VehicleMigrations {
    struct v1: AsyncMigration {
        func prepare(on database: Database) async throws {
            // MARK: - LeaseModel
            try await database.schema(VehicleModel.schema)
                .id()
                .field(VehicleModel.FieldKeys.v1.maker, .string, .required)
                .field(VehicleModel.FieldKeys.v1.model, .string, .required)
                .field(VehicleModel.FieldKeys.v1.year, .int)
                .field(VehicleModel.FieldKeys.v1.odometer, .double)
                .field(VehicleModel.FieldKeys.v1.imageKey, .string)
                .field(VehicleModel.FieldKeys.v1.createdAt, .datetime)
                .field(VehicleModel.FieldKeys.v1.updatedAt, .datetime)
                .field(VehicleModel.FieldKeys.v1.deletedAt, .datetime)
                .create()
            
            try await database.schema(VehiclesTripHistoryModel.schema)
                .id()
                .field(VehiclesTripHistoryModel.FieldKeys.v1.vehicleId, .uuid, .required)
                .foreignKey(VehiclesTripHistoryModel.FieldKeys.v1.vehicleId, references: VehicleModel.schema, VehicleModel.FieldKeys.v1.id, onDelete: .cascade)
                .field(VehiclesTripHistoryModel.FieldKeys.v1.odometer, .double, .required)
                .field(VehiclesTripHistoryModel.FieldKeys.v1.distance, .double, .required)
                .field(VehiclesTripHistoryModel.FieldKeys.v1.destination, .string)
                .field(VehiclesTripHistoryModel.FieldKeys.v1.createdAt, .datetime)
                .field(VehiclesTripHistoryModel.FieldKeys.v1.updatedAt, .datetime)
                .field(VehiclesTripHistoryModel.FieldKeys.v1.deletedAt, .datetime)
                .create()
        }
        
        
        
        func revert(on database: Database) async throws {
            try await database.schema(VehicleModel.schema).delete()
            try await database.schema(VehiclesTripHistoryModel.schema).delete()
        }
    }
    
    struct seed: AsyncMigration {
        func prepare(on database: any Database) async throws {

            let vehicle1 = try VehicleModel(maker: "Nissan", model: "Patrol", year: 2001, odometer: 247000.0, imageKey: "0")
            let vehicle2 = try VehicleModel(maker: "Volkswagen", model: "T6", year: 2016, odometer: 279000.0, imageKey: "1")
            
            try await vehicle1.create(on: database)
            try await vehicle2.create(on: database)
        }
        
        func revert(on database: any Database) async throws {
            try await VehiclesTripHistoryModel.query(on: database).delete()
            try await VehicleModel.query(on: database).delete()
        }
    }
}
