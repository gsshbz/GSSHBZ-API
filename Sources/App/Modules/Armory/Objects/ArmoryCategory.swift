//
//  ArmoryCategory.swift
//  
//
//  Created by Mico Miloloza on 12.11.2023..
//

import Foundation


public extension Armory.Category {
    struct List: Codable {
        let id: UUID
        let name: String
        let imageKey: Int?
        var armoryItems: [Armory.Item.List]? = nil
    }
    
    struct Detail: Codable {
        let id: UUID
        let name: String
        let imageKey: Int?
    }
    
    struct Create: Codable {
        let name: String
        let imageKey: Int?
    }
    
    struct Update: Codable {
        let name: String
        let imageKey: Int?
    }
    
    struct Patch: Codable {
        let name: String?
        let imageKey: Int?
    }
}
