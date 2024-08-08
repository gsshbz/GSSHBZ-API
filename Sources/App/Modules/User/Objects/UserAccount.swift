//
//  UserAccount.swift
//
//
//  Created by Mico Miloloza on 09.02.2024..
//

import Foundation


extension User.Account {
    struct List: Codable {
        let id: UUID
        let username: String
    }
    
    struct Detail: Codable {
        let id: UUID
        let username: String
    }
    
    struct Create: Codable {
        let firstName: String
        let lastName: String
        let username: String
        let email: String
        let password: String
        let confirmPassword: String
        let phoneNumber: String?
        let address: String?
        let profileImageUrlString: String?
    }
    
    struct Update: Codable {
        let username: String
        let email: String
        let password: String?
    }
    
    struct Patch: Codable {
        let username: String?
        let email: String?
        let password: String?
    }
    
    struct LoginRequest: Codable {
        let email: String
        let password: String
    }
}
