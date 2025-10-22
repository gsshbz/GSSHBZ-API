//
//  ArmoryTripHistory.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 30.09.2025..
//

import Vapor


public extension Armory.TripHistory {
    struct List: Codable {
        let id: UUID
        let distance: Double
        let odometer: Double
        let destination: String
        let createdAt: Date?
        
    }
    
    struct Detail: Codable {
        let id: UUID
        let vehicle: Armory.Vehicle.List
        let distance: Double
        let odometer: Double
        let destination: String
        let createdAt: Date?
    }
    
    struct Create: Codable {
        let vehicleId: UUID
        let odometer: Double
        let destination: String
    }
    
    struct Update: Codable {
        let vehicleId: UUID
        let odometer: Double
        let destination: String
    }
    
    struct Patch: Codable {
        let vehicleId: UUID?
        let odometer: Double?
        let destination: String?
    }
}
