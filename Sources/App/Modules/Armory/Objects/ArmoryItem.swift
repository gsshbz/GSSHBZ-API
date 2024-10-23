//
//  ArmoryItem.swift
//
//
//  Created by Mico Miloloza on 12.11.2023..
//

import Foundation


public extension Armory.Item {
    struct List: Codable {
        let id: UUID
        let name: String
        let imageKey: String
        let aboutInfo: String
        let inStock: Int
        let category: Armory.Category.List
        let categoryId: UUID
    }
    
    struct Detail: Codable {
        let id: UUID
        let name: String
        let imageKey: String
        let aboutInfo: String
        let inStock: Int
        let category: Armory.Category.List
        let categoryId: UUID
    }
    
    struct Create: Codable {
        let name: String
        let imageKey: String
        let aboutInfo: String
        let inStock: Int
        let categoryId: UUID?
    }
    
    struct Update: Codable {
        let name: String
        let imageKey: String
        let aboutInfo: String
        let inStock: Int
        let categoryId: UUID?
    }
    
    struct Patch: Codable {
        let name: String?
        let imageKey: String?
        let aboutInfo: String?
        let inStock: Int?
        let categoryId: UUID?
    }
}
