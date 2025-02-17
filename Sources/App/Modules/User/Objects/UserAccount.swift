//
//  UserAccount.swift
//
//
//  Created by Mico Miloloza on 09.02.2024..
//

import Foundation
import Vapor


extension User.Account {
    struct List: Codable {
        let users: [Public]
        let metadata: Metadata?
        
        struct Metadata: Codable {
            let page: Int
            let per: Int
            let total: Int
        }
    }
//    struct List: Codable {
//        let id: UUID
//        let firstName: String
//        let lastName: String
//        let email: String
//        let isAdmin: Bool
//        let imageKey: Int?
//    }
    
    struct Detail: Codable {
        let id: UUID
        let firstName: String
        let lastName: String
        let imageKey: Int?
        let email: String
        let isAdmin: Bool
    }
    
    struct Public: Codable {
        let id: UUID
        let firstName: String
        let lastName: String
        let imageKey: Int?
    }
    
    struct Create: Codable {
        let firstName: String
        let lastName: String
        let email: String
        let password: String
        let confirmPassword: String
        let phoneNumber: String?
        let address: String?
        let imageKey: Int?
    }
    
    struct Update: Codable {
        let firstName: String
        let lastName: String
        let email: String
        let password: String
        let phoneNumber: String
        let address: String
        let isAdmin: Bool
        let imageKey: Int?
    }
    
    struct Patch: Codable {
        let firstName: String?
        let lastName: String?
        let email: String?
        let phoneNumber: String?
        let address: String?
        let isAdmin: Bool?
        let imageKey: Int?
        
    }
    
    struct LoginRequest: Codable {
        let email: String
        let password: String
    }
}
