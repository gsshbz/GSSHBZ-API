//
//  File.swift
//  
//
//  Created by Mico Miloloza on 11.04.2024..
//

import Foundation


public extension Armory.Lease {
    struct List: Codable {
        let id: UUID
        let user: User.Account.List
        let armoryItems: [Armory.Item.List]
    }
    
    struct Detail: Codable {
        let id: UUID
        let user: User.Account.List
        let armoryItems: [Armory.Item.List]
    }
    
    struct Create: Codable {
        let armoryItemsIds: [UUID]
    }
    
    struct Update: Codable {
        let armoryItemsIds: [UUID]
    }
    
    struct Patch: Codable {
        let armoryItemsIds: [UUID]?
    }
}
