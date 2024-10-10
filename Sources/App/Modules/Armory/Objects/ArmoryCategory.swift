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
        var armoryItems: [Armory.Item.List]? = nil
    }
    
    // This model is used to determine if we need to return armory items in request response
    struct GetList: Codable {
        let items: Bool
        
        // Custom initializer to provide a default value
        init(items: Bool = false) {
            self.items = items
        }
    }
    
    struct Detail: Codable {
        let id: UUID
        let name: String
    }
    
    struct Create: Codable {
        let name: String
    }
    
    struct Update: Codable {
        let name: String
    }
    
    struct Patch: Codable {
        let name: String?
    }
}
