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
        let imageKey: String?
        var armoryItems: [Armory.Item.List]? = nil
    }
    
    struct Detail: Codable {
        let id: UUID
        let name: String
        let imageKey: String?
    }
    
    struct Create: Codable {
        let name: String
        let imageKey: String?
    }
    
    struct Update: Codable {
        let name: String
        let imageKey: String?
    }
    
    struct Patch: Codable {
        let name: String?
        let imageKey: String?
    }
}
