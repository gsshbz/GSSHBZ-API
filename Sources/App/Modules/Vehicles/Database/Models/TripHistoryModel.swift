//
//  TripHistoryModel.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 16.09.2025..
//

import Vapor
import Fluent


final class VehiclesTripHistoryModel: DatabaseModelInterface {
    typealias Module = VehiclesModule
    
    @ID
    var id: UUID?
    
    @Parent(key: FieldKeys.v1.vehicleId)
    var vehicle: VehicleModel
    
    @Field(key: FieldKeys.v1.odometer)
    var odometer: Double
    
    @Field(key: FieldKeys.v1.distance)
    var distance: Double
    
    @Field(key: FieldKeys.v1.destination)
    var destination: String
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create)
    var createdAt: Date?
    
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete)
    var deletedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, vehicleId: UUID, odometer: Double, distance: Double, destination: String, createdAt: Date? = nil, updatedAt: Date? = nil, deletedAt: Date? = nil) {
        self.id = id
        self.$vehicle.id = vehicleId
        self.odometer = odometer
        self.distance = distance
        self.destination = destination
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

extension VehiclesTripHistoryModel {
    struct FieldKeys {
        struct v1 {
            static var id: FieldKey { "id" }
            static var vehicleId: FieldKey { "vehicle_id" }
            static var odometer: FieldKey { "odometer" }
            static var distance: FieldKey { "distance" }
            static var destination: FieldKey { "destination" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
}
