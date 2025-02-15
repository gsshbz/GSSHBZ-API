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
        let user: User.Account.Detail
        let returned: Bool
        let armoryItems: [ArmoryItem]
        let createdAt: Date?
        let updatedAt: Date?
        let deletedAt: Date?
        
        struct ArmoryItem: Codable {
            let armoryItem: Armory.Item.Detail
            let quantity: Int
        }
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
        let returned: Bool
        
        struct ArmoryItem: Codable {
            let armoryItemId: UUID
            let quantity: Int
        }
    }
    
    struct Patch: Codable {
        let items: [ArmoryItem]?
        let returned: Bool?
        
        struct ArmoryItem: Codable {
            let armoryItemId: UUID
            let quantity: Int
        }
    }
}
