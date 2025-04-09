//
//  UserRegistrationTokenModel.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 11.03.2025..
//

import Vapor
import Fluent

final class UserRegistrationTokenModel: DatabaseModelInterface, Codable {
    typealias Module = UserModule
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: FieldKeys.v1.token)
    var code: String
    
    @Field(key: FieldKeys.v1.isUsed)
    var isUsed: Bool
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create)
    var createdAt: Date?
    
    @Field(key: FieldKeys.v1.expiresAt)
    var expiresAt: Date
    
    init() {}
    
    init(id: UUID? = nil, code: String, expiresAt: Date = Date().addingTimeInterval(Constants.REFRESH_TOKEN_LIFETIME)) {
        self.id = id
        self.code = code
        self.isUsed = false
        self.expiresAt = expiresAt
    }
}

extension UserRegistrationTokenModel {
    struct FieldKeys {
        struct v1 {
            static var id: FieldKey { "id" }
            static var token: FieldKey { "token" }
            static var isUsed: FieldKey { "is_used" }
            static var createdAt: FieldKey { "created_at" }
            static var expiresAt: FieldKey { "expires_at" }
        }
    }
}
