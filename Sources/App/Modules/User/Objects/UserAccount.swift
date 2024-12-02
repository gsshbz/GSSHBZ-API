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
        let id: UUID
        let firstName: String
        let lastName: String
        let email: String
        let isAdmin: Bool
    }
    
    struct Detail: Codable {
        let id: UUID
        let firstName: String
        let lastName: String
        let profileImageUrlString: String?
        let email: String
        let isAdmin: Bool
    }
    
    struct Create: Codable {
        let firstName: String
        let lastName: String
        let email: String
        let password: String
        let confirmPassword: String
        let phoneNumber: String?
        let address: String?
        let image: File?
    }
    
    struct Update: Codable {
        let firstName: String
        let lastName: String
        let email: String
        let password: String
        let phoneNumber: String
        let address: String
        let isAdmin: Bool
        let image: File
    }
    
    struct Patch: Codable {
        let firstName: String?
        let lastName: String?
        let email: String?
        let phoneNumber: String?
        let address: String?
        let isAdmin: Bool?
        let image: File?
        
    }
    
    struct LoginRequest: Codable {
        let email: String
        let password: String
    }
}
