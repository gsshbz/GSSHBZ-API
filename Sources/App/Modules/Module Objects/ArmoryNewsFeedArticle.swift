//
//  ArmoryNewsFeedArticle.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 03.02.2025..
//

import Foundation


public extension Armory.NewsFeedArticle {
    struct List: Codable {
        let news: [Detail]
        let metadata: Metadata?
        
        struct Metadata: Codable {
            let page: Int
            let per: Int
            let total: Int
        }
    }
    
    struct Detail: Codable {
        let id: UUID
        let title: String
        let text: String
        let user: User.Account.Detail
        let createdAt: Date?
        let updatedAt: Date?
        let deletedAt: Date?
    }
    
    struct Create: Codable {
        let title: String
        let text: String
    }
    
    struct Update: Codable {
        let title: String
        let text: String
    }
    
    struct Patch: Codable {
        let title: String?
        let text: String?
    }
}

