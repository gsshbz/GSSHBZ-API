//
//  File.swift
//  
//
//  Created by Mico Miloloza on 11.04.2024..
//

import Foundation


public extension Armory.Lease {
    struct List: Codable {
        let leases: [Detail]
        let metadata: Metadata?
        
        struct Metadata: Codable {
            let page: Int
            let per: Int
            let total: Int
        }
    }
    
    struct Detail: Codable {
        let id: UUID
        let user: User.Account.List
        let armoryItems: [Armory.Item.List]
    }
    
    struct Create: Codable {
        let items: [ArmoryItem]
        
        struct ArmoryItem: Codable {
            let armoryItemId: UUID
            let quantity: Int
        }
    }
    
    struct Update: Codable {
        let items: [ArmoryItem]
        
        struct ArmoryItem: Codable {
            let armoryItemId: UUID
            let quantity: Int
        }
    }
    
    struct Patch: Codable {
        let items: [ArmoryItem]?
        
        struct ArmoryItem: Codable {
            let armoryItemId: UUID
            let quantity: Int
        }
    }
}
