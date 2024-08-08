//
//  RefreshTokenModel.swift
//  
//
//  Created by Mico Miloloza on 09.02.2024..
//

import Vapor
import Fluent


final class RefreshTokenModel: DatabaseModelInterface {
    typealias Module = UserModule
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: FieldKeys.v1.token)
    var token: String
    
    @Parent(key: FieldKeys.v1.userId)
    var user: UserAccountModel
    
    @Field(key: FieldKeys.v1.expiresAt)
    var expiresAt: Date
    
    @Field(key: FieldKeys.v1.issuedAt)
    var issuedAt: Date
    
    init() {}
    
    init(id: UUID? = nil, token: String, userId: UUID, expiresAt: Date = Date().addingTimeInterval(Constants.REFRESH_TOKEN_LIFETIME), issuedAt: Date = Date()) {
        self.id = id
        self.token = token
        self.$user.id = userId
        self.expiresAt = expiresAt
        self.issuedAt = issuedAt
    }
}


extension RefreshTokenModel {
    struct FieldKeys {
        struct v1 {
            static var id: FieldKey { "id" }
            static var token: FieldKey { "token" }
            static var userId: FieldKey { "user_id" }
            static var expiresAt: FieldKey { "expires_at" }
            static var issuedAt: FieldKey { "issued_at" }
        }
    }
}

