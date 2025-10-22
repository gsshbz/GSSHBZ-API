//
//  VehicleModel.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 16.09.2025..
//

import Vapor
import Fluent


final class VehicleModel: DatabaseModelInterface {
    typealias Module = VehiclesModule
    
    @ID
    var id: UUID?
    
    @Field(key: FieldKeys.v1.maker)
    var maker: String
    
    @Field(key: FieldKeys.v1.model)
    var model: String
    
    @Field(key: FieldKeys.v1.year)
    var year: Int
    
    @Field(key: FieldKeys.v1.odometer)
    var odometer: Double
    
    @Field(key: FieldKeys.v1.imageKey)
    var imageKey: String
    
    @Children(for: \.$vehicle)
    var tripHistory: [VehiclesTripHistoryModel]
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create)
    var createdAt: Date?
    
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete)
    var deletedAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, maker: String, model: String, year: Int, odometer: Double, imageKey: String, createdAt: Date? = nil, updatedAt: Date? = nil, deletedAt: Date? = nil) throws {
        self.id = id
        self.maker = maker
        self.model = model
        self.year = year
        self.odometer = odometer
        self.imageKey = imageKey
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}


extension VehicleModel {
    struct FieldKeys {
        struct v1 {
            static var id: FieldKey { "id" }
            static var maker: FieldKey { "maker" }
            static var model: FieldKey { "model" }
            static var year: FieldKey { "year" }
            static var odometer: FieldKey { "odometer" }
            static var tripHistory: FieldKey { "trip_history" }
            static var imageKey: FieldKey { "image_key" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
}

