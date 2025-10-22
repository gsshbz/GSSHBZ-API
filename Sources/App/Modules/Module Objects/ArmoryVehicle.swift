//
//  ArmoryVehicle.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 24.09.2025..
//

import Foundation
import Vapor


public extension Armory.Vehicle {
    struct List: Codable {
        let id: UUID
        let maker: String
        let model: String
        let year: Int
        let odometer: Double
        let imageKey: String
    }
    
    struct Detail: Codable {
        let id: UUID
        let maker: String
        let model: String
        let year: Int
        let odometer: Double
        let imageKey: String
        let tripHistory: [Armory.TripHistory.List]
        let createdAt: Date?
        let updatedAt: Date?
        let deletedAt: Date?
    }
    
    struct Create: Codable {
        let maker: String
        let model: String
        let year: Int
        let odometer: Double
        let imageKey: String
    }
    
    struct Update: Codable {
        let maker: String
        let model: String
        let year: Int
        let odometer: Double
        let imageKey: String
    }
    
    struct Patch: Codable {
        let maker: String?
        let model: String?
        let year: Int?
        let odometer: Double?
        let imageKey: String?
    }
}
