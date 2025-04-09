//
//  UserToken.swift
//
//
//  Created by Mico Miloloza on 09.02.2024..
//

import Foundation


extension User.Token {
    struct Detail: Codable {
        let id: UUID
        let user: User.Account.Detail
        let accessToken: String
        let refreshToken: String
    }
    
    struct AccessTokenRequest: Codable {
        let refreshToken: String
    }
    
    struct AccessTokenResponse: Codable {
        let refreshToken: String
        let accessToken: String
    }
    
    struct ResetPasswordRequest: Codable {
        let email: String
        let token: String
        let newPassword: String
        let confirmPassword: String
    }
    
    struct RegistrationToken: Codable {
        let id: UUID
        let token: String
        let isUsed: Bool
        let createdAt: Date?
    }
    
    struct ResetPasswordToken: Codable {
        let id: UUID
        let token: String
        let isUsed: Bool
        let createdAt: Date?
    }
}
